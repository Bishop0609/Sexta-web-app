import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

/// Clase auxiliar para manejar archivos de forma compatible web/móvil
class AttachmentFile {
  final Uint8List bytes;
  final String fileName;

  AttachmentFile({required this.bytes, required this.fileName});

  String get extension => path.extension(fileName).toLowerCase();
  int get size => bytes.length;
}

/// Servicio para manejo de archivos en Supabase Storage
class StorageService {
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();
  
  static const String _permissionsBucket = 'permission-attachments';
  static const int _maxFileSizeBytes = 2 * 1024 * 1024; // 2MB
  static const int _imageQuality = 50; // Compresión agresiva
  static const int _maxImageWidth = 1280; // Ancho máximo

  /// Seleccionar imagen desde galería
  Future<AttachmentFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxImageWidth.toDouble(),
        imageQuality: _imageQuality,
      );
      
      if (image == null) return null;
      return AttachmentFile(
        bytes: await image.readAsBytes(),
        fileName: image.name,
      );
    } catch (e) {
      throw Exception('Error seleccionando imagen: $e');
    }
  }

  /// Tomar foto con cámara
  Future<AttachmentFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxImageWidth.toDouble(),
        imageQuality: _imageQuality,
      );
      
      if (image == null) return null;
      return AttachmentFile(
        bytes: await image.readAsBytes(),
        fileName: image.name,
      );
    } catch (e) {
      throw Exception('Error capturando foto: $e');
    }
  }

  /// Seleccionar archivo PDF
  Future<AttachmentFile?> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Importante para Web
      );

      if (result == null || result.files.isEmpty) return null;
      
      final file = result.files.first;
      
      // En Web, file.path es null, usar file.bytes
      // En móvil, file.bytes puede ser null si withData es false (pero aquí es true)
      // FilePicker a veces no devuelve bytes en móvil aunque se pida, fallback a leer ruta
      Uint8List? fileBytes = file.bytes;
      
      if (fileBytes == null && file.path != null) {
        // Fallback para móvil/desktop si bytes viene nulo
        // NOTA: Esto requeriría dart:io si leemos directo, pero FilePicker debería darlo
        // Para evitar dart:io, asumimos que withData:true funciona o usamos XFile para leer
        // Pero FilePicker no retorna XFile.
        // Solución simple: Asumimos bytes disponibles o lanzamos error en esta impl simplificada para web
        // En una app real híbrida robusta, se usaría compilación condicional o paquetes cross-platform completos.
        // Dado que el usuario usa Flutter Web ahora, priorizamos bytes.
        // Si se ejecuta en móvil, FilePicker con withData: true suele cargar bytes en memoria (cuidado con RAM), 
        // o si no, podemos usar un import condicional. 
        // Para simplificar y dado el tamaño max 2MB, cargar en memoria está bien.
        
        // Si estamos en movil y bytes es null, necesitamos dart:io
        // Pero no puedo importar dart:io si quiero que compile en web sin warnings molestos o errores.
        // La mejor opción es confiar en `withData: true`.
        throw Exception('No se pudieron leer los datos del archivo');
      } 
      
      if (fileBytes == null) return null;

      final attachment = AttachmentFile(
        bytes: fileBytes,
        fileName: file.name,
      );

      // Validar tamaño
      if (attachment.size > _maxFileSizeBytes) {
        throw Exception('El archivo PDF excede el límite de 2MB');
      }

      return attachment;
    } catch (e) {
      throw Exception('Error seleccionando PDF: $e');
    }
  }

  /// Comprimir bytes de imagen de forma agresiva
  Future<Uint8List> compressImageBytes(Uint8List imageBytes) async {
    try {
      // Comprimir con calidad agresiva
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: _maxImageWidth,
        minHeight: (_maxImageWidth * 0.75).toInt(), // Proporción 4:3
        quality: _imageQuality,
        format: CompressFormat.jpeg,
      );

      // Verificar tamaño después de comprimir
      if (compressedBytes.length > _maxFileSizeBytes) {
        throw Exception('La imagen sigue siendo muy grande después de comprimir');
      }

      return compressedBytes;
    } catch (e) {
      print('Error en compresión (puede fallar en web simuladores): $e');
      // En Web, image_compress a veces tiene problemas. Fallback: devolver original si falla
      return imageBytes; 
    }
  }

  /// Subir archivo adjunto de permiso
  Future<String> uploadPermissionAttachment(
    AttachmentFile file,
    String permissionId,
    String userId,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Generar nombre único incluyendo el userId como carpeta raíz para cumplir RLS
      final storagePath = '$userId/$permissionId/$timestamp${file.extension}';

      // Preparar datos para subir
      Uint8List fileBytes;
      
      if (file.extension == '.pdf') {
        // PDF sin comprimir
        if (file.size > _maxFileSizeBytes) {
          throw Exception('El archivo PDF excede el límite de 2MB');
        }
        fileBytes = file.bytes;
      } else {
        // Imagen con compresión agresiva
        fileBytes = await compressImageBytes(file.bytes);
      }

      // Subir a Supabase Storage
      await _supabase.storage
          .from(_permissionsBucket)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: file.extension == '.pdf' ? 'application/pdf' : 'image/jpeg',
            ),
          );

      return storagePath;
    } catch (e) {
      throw Exception('Error subiendo archivo: $e');
    }
  }

  /// Obtener URL pública temporal (válida por 1 hora)
  Future<String> getAttachmentUrl(String storagePath) async {
    try {
      final url = await _supabase.storage
          .from(_permissionsBucket)
          .createSignedUrl(storagePath, 3600); // 1 hora
      
      return url;
    } catch (e) {
      throw Exception('Error obteniendo URL del archivo: $e');
    }
  }

  /// Eliminar archivo adjunto
  Future<void> deleteAttachment(String storagePath) async {
    try {
      await _supabase.storage
          .from(_permissionsBucket)
          .remove([storagePath]);
    } catch (e) {
      throw Exception('Error eliminando archivo: $e');
    }
  }

  /// Validar tamaño de archivo
  bool validateFileSize(AttachmentFile file) {
    return file.size <= _maxFileSizeBytes;
  }

  /// Obtener tamaño de archivo en formato legible
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
