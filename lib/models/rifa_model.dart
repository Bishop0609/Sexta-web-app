class RifaModel {
  final String id;
  final String nombre;
  final int anio;
  final int numerosPorTalonario;
  final int precioNumero;
  final int totalTalonarios;
  final int correlativoInicio;
  final int correlativoFin;
  final String estado;
  final DateTime? createdAt;
  final String? createdBy;

  RifaModel({
    required this.id,
    required this.nombre,
    required this.anio,
    required this.numerosPorTalonario,
    required this.precioNumero,
    required this.totalTalonarios,
    required this.correlativoInicio,
    required this.correlativoFin,
    required this.estado,
    this.createdAt,
    this.createdBy,
  });

  factory RifaModel.fromJson(Map<String, dynamic> json) {
    return RifaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      anio: json['anio'] as int,
      numerosPorTalonario: json['numeros_por_talonario'] as int,
      precioNumero: json['precio_numero'] as int,
      totalTalonarios: json['total_talonarios'] as int,
      correlativoInicio: json['correlativo_inicio'] as int,
      correlativoFin: json['correlativo_fin'] as int,
      estado: json['estado'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'anio': anio,
      'numeros_por_talonario': numerosPorTalonario,
      'precio_numero': precioNumero,
      'total_talonarios': totalTalonarios,
      'correlativo_inicio': correlativoInicio,
      'correlativo_fin': correlativoFin,
      'estado': estado,
      'created_at': createdAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  int get precioTalonario => numerosPorTalonario * precioNumero;
  int get totalNumeros => totalTalonarios * numerosPorTalonario;
  int get recaudacionMaxima => totalNumeros * precioNumero;
  bool get estaActiva => estado == 'activa';
}
