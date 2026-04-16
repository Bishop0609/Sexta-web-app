class RifaTalonarioModel {
  final String id;
  final String rifaId;
  final int numeroTalonario;
  final int correlativoDesde;
  final int correlativoHasta;
  final String estado;
  final String? asignadoA;
  final DateTime? fechaEntrega;
  final String? entregadoPor;
  final int numerosVendidos;
  final int montoRecaudado;
  final int montoEntregado;
  final DateTime? fechaDevolucion;
  final String? recibidoPor;
  final String? notas;
  final DateTime? createdAt;
  
  final String? entidadExternaId;
  final int descuentoAplicado;

  // Campo opcional para JOIN
  final String? bomberoNombre;
  final String? entidadNombre;
  final int? entidadDescuento;

  RifaTalonarioModel({
    required this.id,
    required this.rifaId,
    required this.numeroTalonario,
    required this.correlativoDesde,
    required this.correlativoHasta,
    required this.estado,
    this.asignadoA,
    this.fechaEntrega,
    this.entregadoPor,
    this.numerosVendidos = 0,
    this.montoRecaudado = 0,
    this.montoEntregado = 0,
    this.fechaDevolucion,
    this.recibidoPor,
    this.notas,
    this.createdAt,
    this.bomberoNombre,
    this.entidadNombre,
    this.entidadExternaId,
    this.descuentoAplicado = 0,
    this.entidadDescuento,
  });

  factory RifaTalonarioModel.fromJson(Map<String, dynamic> json) {
    // Manejo de bomberoNombre desde diferentes posibles estructuras de JOIN
    String? bNombre;
    if (json.containsKey('users')) {
      if (json['users'] != null) bNombre = json['users']['full_name'] as String?;
    } else if (json.containsKey('bombero_nombre')) {
      bNombre = json['bombero_nombre'] as String?;
    }

    String? eNombre;
    int? eDescuento;
    if (json['rifa_entidades_externas'] is Map) {
      eNombre = json['rifa_entidades_externas']['nombre'] as String?;
      eDescuento = json['rifa_entidades_externas']['porcentaje_descuento'] as int?;
    }

    return RifaTalonarioModel(
      id: json['id'] as String,
      rifaId: json['rifa_id'] as String,
      numeroTalonario: json['numero_talonario'] as int,
      correlativoDesde: json['correlativo_desde'] as int,
      correlativoHasta: json['correlativo_hasta'] as int,
      estado: json['estado'] as String,
      asignadoA: json['asignado_a'] as String?,
      entidadExternaId: json['entidad_externa_id'] as String?,
      fechaEntrega: json['fecha_entrega'] != null
          ? DateTime.parse(json['fecha_entrega'] as String)
          : null,
      entregadoPor: json['entregado_por'] as String?,
      numerosVendidos: json['numeros_vendidos'] as int? ?? 0,
      montoRecaudado: json['monto_recaudado'] as int? ?? 0,
      montoEntregado: json['monto_entregado'] as int? ?? 0,
      fechaDevolucion: json['fecha_devolucion'] != null
          ? DateTime.parse(json['fecha_devolucion'] as String)
          : null,
      recibidoPor: json['recibido_por'] as String?,
      notas: json['notas'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      bomberoNombre: bNombre,
      entidadNombre: eNombre,
      descuentoAplicado: json['descuento_aplicado'] as int? ?? 0,
      entidadDescuento: eDescuento,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rifa_id': rifaId,
      'numero_talonario': numeroTalonario,
      'correlativo_desde': correlativoDesde,
      'correlativo_hasta': correlativoHasta,
      'estado': estado,
      'asignado_a': asignadoA,
      'fecha_entrega': fechaEntrega?.toIso8601String(),
      'entregado_por': entregadoPor,
      'numeros_vendidos': numerosVendidos,
      'monto_recaudado': montoRecaudado,
      'monto_entregado': montoEntregado,
      'fecha_devolucion': fechaDevolucion?.toIso8601String(),
      'recibido_por': recibidoPor,
      'notas': notas,
      'created_at': createdAt?.toIso8601String(),
      'entidad_externa_id': entidadExternaId,
      'descuento_aplicado': descuentoAplicado,
      // bomberoNombre normalmente no se envía en toJson porque es de lectura (JOIN)
    };
  }

  // Propiedades calculadas
  String get rangoDisplay => '$correlativoDesde - $correlativoHasta';
  bool get estaDisponible => estado == 'disponible';
  bool get estaEntregado => estado == 'entregado';
  bool get fueDevuelto => estado.startsWith('devuelto');
  int get diferenciaDinero => montoEntregado - montoRecaudado;

  bool get esExterno => entidadExternaId != null;
  bool get esInterno => asignadoA != null;
  String? get nombreAsignado => esExterno ? entidadNombre : bomberoNombre;
  int get montoEsperadoConDescuento => montoRecaudado - descuentoAplicado;

  // Método para color de estado
  String estadoColor() {
    switch (estado) {
      case 'disponible':
        return 'grey';
      case 'entregado':
        return 'orange';
      case 'devuelto_total':
        return 'green';
      case 'devuelto_parcial':
        return 'blue';
      case 'devuelto_sin_venta':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Método estadoDisplay
  String estadoDisplay() {
    switch (estado) {
      case 'disponible':
        return 'Disponible';
      case 'entregado':
        return 'Entregado';
      case 'devuelto_total':
        return 'Devuelto (completo)';
      case 'devuelto_parcial':
        return 'Devuelto (parcial)';
      case 'devuelto_sin_venta':
        return 'Devuelto (sin venta)';
      default:
        return estado;
    }
  }
}
