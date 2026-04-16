class ViperEmergenciaModel {
  final String id;
  final int correlativo;
  final DateTime fecha;
  final String codigoEmergencia;
  final String codigoPrincipal;
  final String? tipoEmergencia;
  final String? direccion;
  final List<String>? carros;
  final String? comuna;
  final String? attendanceEventId;
  final String estadoMatching;
  final String? notas;
  final DateTime? importedAt;
  final String? importedBy;
  final DateTime? updatedAt;

  ViperEmergenciaModel({
    required this.id,
    required this.correlativo,
    required this.fecha,
    required this.codigoEmergencia,
    required this.codigoPrincipal,
    this.tipoEmergencia,
    this.direccion,
    this.carros,
    this.comuna,
    this.attendanceEventId,
    this.estadoMatching = 'pendiente',
    this.notas,
    this.importedAt,
    this.importedBy,
    this.updatedAt,
  });

  factory ViperEmergenciaModel.fromJson(Map<String, dynamic> json) {
    return ViperEmergenciaModel(
      id: json['id'] as String,
      correlativo: json['correlativo'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      codigoEmergencia: json['codigo_emergencia'] as String,
      codigoPrincipal: json['codigo_principal'] as String,
      tipoEmergencia: json['tipo_emergencia'] as String?,
      direccion: json['direccion'] as String?,
      carros: (json['carros'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      comuna: json['comuna'] as String?,
      attendanceEventId: json['attendance_event_id'] as String?,
      estadoMatching: json['estado_matching'] as String? ?? 'pendiente',
      notas: json['notas'] as String?,
      importedAt: json['imported_at'] != null ? DateTime.parse(json['imported_at'] as String) : null,
      importedBy: json['imported_by'] as String?,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'correlativo': correlativo,
      'fecha': fecha.toIso8601String(),
      'codigo_emergencia': codigoEmergencia,
      'codigo_principal': codigoPrincipal,
      'tipo_emergencia': tipoEmergencia,
      'direccion': direccion,
      'carros': carros,
      'comuna': comuna,
      'attendance_event_id': attendanceEventId,
      'estado_matching': estadoMatching,
      'notas': notas,
      'imported_by': importedBy,
    };
  }

  static ViperEmergenciaModel fromExcelRow({
    required int correlativo,
    required String fecha,
    required String clave,
    required String calle,
    String? esquina,
    required String carro,
    String? comuna,
    required String importedByUserId,
  }) {
    // 1. Parsing Fecha ("DD-MM-YYYY HH:MM:SS" -> DateTime)
    DateTime parsedFecha = DateTime.now(); // Fallback date if parsing fails
    try {
      final parts = fecha.trim().split(' ');
      final dateParts = parts[0].split('-');
      final timeParts = parts.length > 1 ? parts[1].split(':') : [];

      if (dateParts.length >= 3) {
        final day = int.tryParse(dateParts[0]) ?? 1;
        final month = int.tryParse(dateParts[1]) ?? 1;
        final year = int.tryParse(dateParts[2]) ?? 2000;

        final hour = timeParts.isNotEmpty ? (int.tryParse(timeParts[0]) ?? 0) : 0;
        final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
        final second = timeParts.length > 2 ? (int.tryParse(timeParts[2]) ?? 0) : 0;

        parsedFecha = DateTime(year, month, day, hour, minute, second);
      }
    } catch (_) {
      // Ignore parse exception inside the excel, fallback to now
    }

    // 2. Parsing Clave
    String codigoEmergencia;
    String codigoPrincipal;
    String? tipoEmergencia;

    final claveTrim = clave.trim();
    final claveUpper = claveTrim.toUpperCase();

    if (claveUpper.contains('ALARMA')) {
      codigoEmergencia = claveTrim;
      codigoPrincipal = 'INCENDIO';
      tipoEmergencia = 'INCENDIO';
    } else if (claveTrim.contains('(')) {
      final parts = claveTrim.split('(');
      codigoEmergencia = parts[0].trim();
      tipoEmergencia = parts.length > 1 ? parts[1].replaceAll(')', '').trim() : null;

      final codeParts = codigoEmergencia.split('-');
      codigoPrincipal = codeParts.length >= 2 
          ? '${codeParts[0]}-${codeParts[1]}' 
          : codigoEmergencia;
    } else {
      codigoEmergencia = claveTrim;
      codigoPrincipal = claveTrim;
      tipoEmergencia = null;
    }

    // 3. Parsing Dirección
    String? direccionParsed;
    final calleTrim = calle.trim();
    if (esquina != null && esquina.trim().isNotEmpty) {
      direccionParsed = '$calleTrim / ${esquina.trim()}';
    } else {
      direccionParsed = calleTrim;
    }

    return ViperEmergenciaModel(
      id: '', // Supabase generará el ID (no se envía en toJson)
      correlativo: correlativo,
      fecha: parsedFecha,
      codigoEmergencia: codigoEmergencia,
      codigoPrincipal: codigoPrincipal,
      tipoEmergencia: tipoEmergencia,
      direccion: direccionParsed,
      carros: [carro.trim()],
      comuna: comuna?.trim(),
      attendanceEventId: null,
      estadoMatching: 'pendiente',
      notas: null,
      importedAt: null,
      importedBy: importedByUserId,
      updatedAt: null,
    );
  }
}
