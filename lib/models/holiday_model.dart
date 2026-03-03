class Holiday {
  final String id;
  final DateTime holidayDate;
  final String name;
  final int year;

  Holiday({required this.id, required this.holidayDate, required this.name, required this.year});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'] as String,
      holidayDate: DateTime.parse(json['holiday_date'] as String),
      name: json['name'] as String,
      year: json['year'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'holiday_date': holidayDate.toIso8601String().split('T')[0],
    'name': name,
    'year': year,
  };
}
