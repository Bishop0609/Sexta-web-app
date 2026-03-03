import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/models/holiday_model.dart';

class HolidayService {
  final _supabase = Supabase.instance.client;

  Future<List<Holiday>> getHolidaysByYear(int year) async {
    final response = await _supabase
        .from('holidays')
        .select()
        .eq('year', year)
        .order('holiday_date', ascending: true);
    return (response as List).map((e) => Holiday.fromJson(e)).toList();
  }

  Future<Holiday> addHoliday({required DateTime date, required String name}) async {
    final response = await _supabase
        .from('holidays')
        .insert({
          'holiday_date': date.toIso8601String().split('T')[0],
          'name': name,
          'year': date.year,
        })
        .select()
        .single();
    return Holiday.fromJson(response);
  }

  Future<void> deleteHoliday(String id) async {
    await _supabase.from('holidays').delete().eq('id', id);
  }

  Future<bool> isHoliday(DateTime date) async {
    final response = await _supabase
        .from('holidays')
        .select('id')
        .eq('holiday_date', date.toIso8601String().split('T')[0])
        .maybeSingle();
    return response != null;
  }

  Future<List<DateTime>> getHolidayDates(int year) async {
    final holidays = await getHolidaysByYear(year);
    return holidays.map((h) => h.holidayDate).toList();
  }
}
