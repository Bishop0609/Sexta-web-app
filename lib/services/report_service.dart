import 'package:supabase_flutter/supabase_flutter.dart';

class ReportBombero {
  final String id;
  final String fullName;
  final String rut;

  ReportBombero({
    required this.id,
    required this.fullName,
    required this.rut,
  });

  factory ReportBombero.fromJson(Map<String, dynamic> json) {
    return ReportBombero(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      rut: json['rut'] as String? ?? '',
    );
  }
}

class ReportEmergencyEvent {
  final String id;
  final String eventDate;
  final String subtype;
  final String location;

  ReportEmergencyEvent({
    required this.id,
    required this.eventDate,
    required this.subtype,
    required this.location,
  });

  factory ReportEmergencyEvent.fromJson(Map<String, dynamic> json) {
    return ReportEmergencyEvent(
      id: json['id'] as String? ?? '',
      eventDate: json['event_date'] as String? ?? '',
      subtype: json['subtype'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }
}

class ReportCitationEvent {
  final String id;
  final String eventDate;
  final String actTypeName;
  final String? subtype;
  final String location;

  ReportCitationEvent({
    required this.id,
    required this.eventDate,
    required this.actTypeName,
    this.subtype,
    required this.location,
  });

  factory ReportCitationEvent.fromJson(Map<String, dynamic> json) {
    return ReportCitationEvent(
      id: json['id'] as String? ?? '',
      eventDate: json['event_date'] as String? ?? '',
      actTypeName: json['act_type_name'] as String? ?? '',
      subtype: json['subtype'] as String?,
      location: json['location'] as String? ?? '',
    );
  }
}

class ReportSection {
  final List<dynamic> eventos;
  final Map<String, double> asistencia;

  ReportSection({
    required this.eventos,
    required this.asistencia,
  });

  factory ReportSection.fromEmergencyJson(Map<String, dynamic> json) {
    final eventosJson = json['eventos'] as List<dynamic>? ?? [];
    final asistenciaJson = json['asistencia'] as Map<String, dynamic>? ?? {};

    return ReportSection(
      eventos: eventosJson
          .map((e) => ReportEmergencyEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      asistencia: asistenciaJson.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  factory ReportSection.fromCitationJson(Map<String, dynamic> json) {
    final eventosJson = json['eventos'] as List<dynamic>? ?? [];
    final asistenciaJson = json['asistencia'] as Map<String, dynamic>? ?? {};

    return ReportSection(
      eventos: eventosJson
          .map((e) => ReportCitationEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      asistencia: asistenciaJson.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }
}

class MonthlyReportData {
  final String mes;
  final List<ReportBombero> bomberos;
  final ReportSection emergencias;
  final ReportSection citaciones;

  MonthlyReportData({
    required this.mes,
    required this.bomberos,
    required this.emergencias,
    required this.citaciones,
  });

  factory MonthlyReportData.fromJson(Map<String, dynamic> json) {
    final bomberosJson = json['bomberos'] as List<dynamic>? ?? [];

    return MonthlyReportData(
      mes: json['mes'] as String? ?? '',
      bomberos: bomberosJson
          .map((e) => ReportBombero.fromJson(e as Map<String, dynamic>))
          .toList(),
      emergencias: ReportSection.fromEmergencyJson(
          json['emergencias'] as Map<String, dynamic>? ?? {}),
      citaciones: ReportSection.fromCitationJson(
          json['citaciones'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class ReportService {
  Future<MonthlyReportData> getMonthlyAttendanceReport(
      int year, int month) async {
    final response = await Supabase.instance.client.rpc(
      'get_monthly_attendance_report',
      params: {
        'p_year': year,
        'p_month': month,
      },
    );

    return MonthlyReportData.fromJson(response as Map<String, dynamic>);
  }
  Future<GuardRosterReportData> getGuardRosterReport(int year, int month) async {
    final response = await Supabase.instance.client.rpc(
      'get_guard_roster_report',
      params: {'p_year': year, 'p_month': month},
    );
    final data = response as Map<String, dynamic>;

    // Parsear usuarios
    final usuariosJson = data['usuarios'] as Map<String, dynamic>? ?? {};
    final usuarios = usuariosJson.map(
      (key, value) => MapEntry(key, GuardUserInfo.fromJson(value as Map<String, dynamic>)),
    );

    // Parsear semanas desde el JSON y AGRUPAR por week_start_date
    final semanasJson = data['semanas'] as List<dynamic>? ?? [];
    
    // Agrupar: mismo week_start_date = mismo bloque
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final semana in semanasJson) {
      final s = semana as Map<String, dynamic>;
      final weekStart = s['week_start_date'] as String;
      final guardType = s['guard_type'] as String;
      final dailyJson = s['daily_rosters'] as List<dynamic>? ?? [];
      final dailyRosters = dailyJson
          .map((d) => GuardDailyRoster.fromJson(d as Map<String, dynamic>))
          .toList();

      if (!grouped.containsKey(weekStart)) {
        grouped[weekStart] = {
          'week_start_date': weekStart,
          'week_end_date': s['week_end_date'] as String,
          'nocturnos': <GuardDailyRoster>[],
          'fds': <GuardDailyRoster>[],
        };
      }

      if (guardType == 'nocturna') {
        (grouped[weekStart]!['nocturnos'] as List<GuardDailyRoster>).addAll(dailyRosters);
      } else {
        (grouped[weekStart]!['fds'] as List<GuardDailyRoster>).addAll(dailyRosters);
      }
    }

    // Convertir a lista ordenada
    final sortedKeys = grouped.keys.toList()..sort();
    final semanas = sortedKeys.map((key) {
      final g = grouped[key]!;
      return GuardWeekBlock(
        weekStartDate: g['week_start_date'] as String,
        weekEndDate: g['week_end_date'] as String,
        nocturnos: g['nocturnos'] as List<GuardDailyRoster>,
        fdsRosters: g['fds'] as List<GuardDailyRoster>,
      );
    }).toList();

    return GuardRosterReportData(
      mes: data['mes'] as String? ?? '',
      semanas: semanas,
      usuarios: usuarios,
    );
  }
}

class GuardRosterReportData {
  final String mes;
  final List<GuardWeekBlock> semanas;
  final Map<String, GuardUserInfo> usuarios;

  GuardRosterReportData({required this.mes, required this.semanas, required this.usuarios});
}

class GuardWeekBlock {
  final String weekStartDate;
  final String weekEndDate;
  final List<GuardDailyRoster> nocturnos;
  final List<GuardDailyRoster> fdsRosters;

  GuardWeekBlock({
    required this.weekStartDate,
    required this.weekEndDate,
    required this.nocturnos,
    required this.fdsRosters,
  });
}

class GuardDailyRoster {
  final String guardDate;
  final String shiftPeriod;
  final String? maquinistaId;
  final String? obacId;
  final List<String> bomberoIds;

  GuardDailyRoster({
    required this.guardDate,
    required this.shiftPeriod,
    this.maquinistaId,
    this.obacId,
    required this.bomberoIds,
  });

  factory GuardDailyRoster.fromJson(Map<String, dynamic> json) {
    return GuardDailyRoster(
      guardDate: json['guard_date'] as String? ?? '',
      shiftPeriod: json['shift_period'] as String? ?? '',
      maquinistaId: json['maquinista_id'] as String?,
      obacId: json['obac_id'] as String?,
      bomberoIds: (json['bombero_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }
}

class GuardUserInfo {
  final String fullName;
  final String rut;
  final String rank;
  final String role;
  final String registroCompania;

  GuardUserInfo({
    required this.fullName,
    required this.rut,
    required this.rank,
    required this.role,
    required this.registroCompania,
  });

  factory GuardUserInfo.fromJson(Map<String, dynamic> json) {
    return GuardUserInfo(
      fullName: json['full_name'] as String? ?? '',
      rut: json['rut'] as String? ?? '',
      rank: json['rank'] as String? ?? '',
      role: json['role'] as String? ?? '',
      registroCompania: json['registro_compania'] as String? ?? '',
    );
  }
}
