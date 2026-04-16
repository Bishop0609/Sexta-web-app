class RifaEntidadExternaModel {
  final String id;
  final String nombre;
  final String tipo;
  final String? contacto;
  final String? telefono;
  final int porcentajeDescuento;
  final String? notas;
  final DateTime? createdAt;

  RifaEntidadExternaModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.contacto,
    this.telefono,
    required this.porcentajeDescuento,
    this.notas,
    this.createdAt,
  });

  factory RifaEntidadExternaModel.fromJson(Map<String, dynamic> json) {
    return RifaEntidadExternaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
      contacto: json['contacto'] as String?,
      telefono: json['telefono'] as String?,
      porcentajeDescuento: json['porcentaje_descuento'] as int? ?? 0,
      notas: json['notas'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'contacto': contacto,
      'telefono': telefono,
      'porcentaje_descuento': porcentajeDescuento,
      'notas': notas,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get tipoDisplay {
    switch (tipo) {
      case 'compania':
        return 'Compañía';
      case 'empresa':
        return 'Empresa';
      case 'particular':
        return 'Particular';
      default:
        return 'Otro';
    }
  }

  String get descripcionDescuento => 'Paga ${100 - porcentajeDescuento}% del valor';
}
