import 'package:equatable/equatable.dart';

class TimeLimit extends Equatable {
  final int dailyMinutes; // Tägliches Limit in Minuten
  final int breakIntervalMinutes; // Nach X Minuten Pause erzwingen
  final int breakDurationMinutes; // Pausendauer in Minuten
  final TimeOfDay bedtimeStart; // Schlafenszeit Start
  final TimeOfDay bedtimeEnd; // Schlafenszeit Ende
  final bool bedtimeEnabled;
  final Map<int, int> weekdayLimits; // 1=Mo, 7=So -> Minuten pro Tag

  const TimeLimit({
    this.dailyMinutes = 60,
    this.breakIntervalMinutes = 30,
    this.breakDurationMinutes = 5,
    this.bedtimeStart = const TimeOfDay(hour: 20, minute: 0),
    this.bedtimeEnd = const TimeOfDay(hour: 7, minute: 0),
    this.bedtimeEnabled = true,
    this.weekdayLimits = const {},
  });

  factory TimeLimit.defaultLimit() {
    return const TimeLimit(
      dailyMinutes: 60,
      breakIntervalMinutes: 30,
      breakDurationMinutes: 5,
      bedtimeStart: TimeOfDay(hour: 20, minute: 0),
      bedtimeEnd: TimeOfDay(hour: 7, minute: 0),
      bedtimeEnabled: true,
    );
  }

  factory TimeLimit.fromMap(Map<String, dynamic> map) {
    return TimeLimit(
      dailyMinutes: map['dailyMinutes'] ?? 60,
      breakIntervalMinutes: map['breakIntervalMinutes'] ?? 30,
      breakDurationMinutes: map['breakDurationMinutes'] ?? 5,
      bedtimeStart: _parseTimeOfDay(map['bedtimeStart']),
      bedtimeEnd: _parseTimeOfDay(map['bedtimeEnd']),
      bedtimeEnabled: map['bedtimeEnabled'] ?? true,
      weekdayLimits: _parseWeekdayLimits(map['weekdayLimits']),
    );
  }

  static TimeOfDay _parseTimeOfDay(dynamic data) {
    if (data == null) return const TimeOfDay(hour: 20, minute: 0);
    if (data is Map) {
      return TimeOfDay(
        hour: data['hour'] ?? 20,
        minute: data['minute'] ?? 0,
      );
    }
    return const TimeOfDay(hour: 20, minute: 0);
  }

  static Map<int, int> _parseWeekdayLimits(dynamic data) {
    if (data == null) return {};
    final map = data as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(int.parse(key), value as int));
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyMinutes': dailyMinutes,
      'breakIntervalMinutes': breakIntervalMinutes,
      'breakDurationMinutes': breakDurationMinutes,
      'bedtimeStart': {'hour': bedtimeStart.hour, 'minute': bedtimeStart.minute},
      'bedtimeEnd': {'hour': bedtimeEnd.hour, 'minute': bedtimeEnd.minute},
      'bedtimeEnabled': bedtimeEnabled,
      'weekdayLimits': weekdayLimits.map((key, value) => MapEntry(key.toString(), value)),
    };
  }

  TimeLimit copyWith({
    int? dailyMinutes,
    int? breakIntervalMinutes,
    int? breakDurationMinutes,
    TimeOfDay? bedtimeStart,
    TimeOfDay? bedtimeEnd,
    bool? bedtimeEnabled,
    Map<int, int>? weekdayLimits,
  }) {
    return TimeLimit(
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,
      breakIntervalMinutes: breakIntervalMinutes ?? this.breakIntervalMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      bedtimeStart: bedtimeStart ?? this.bedtimeStart,
      bedtimeEnd: bedtimeEnd ?? this.bedtimeEnd,
      bedtimeEnabled: bedtimeEnabled ?? this.bedtimeEnabled,
      weekdayLimits: weekdayLimits ?? this.weekdayLimits,
    );
  }

  /// Prüft ob aktuell Schlafenszeit ist
  bool isCurrentlyBedtime() {
    if (!bedtimeEnabled) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = bedtimeStart.hour * 60 + bedtimeStart.minute;
    final endMinutes = bedtimeEnd.hour * 60 + bedtimeEnd.minute;

    // Über Mitternacht (z.B. 20:00 - 07:00)
    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
    // Am selben Tag (z.B. 13:00 - 15:00)
    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  /// Gibt das Limit für einen bestimmten Wochentag zurück
  int getLimitForDay(int weekday) {
    return weekdayLimits[weekday] ?? dailyMinutes;
  }

  @override
  List<Object?> get props => [
        dailyMinutes,
        breakIntervalMinutes,
        breakDurationMinutes,
        bedtimeStart,
        bedtimeEnd,
        bedtimeEnabled,
        weekdayLimits,
      ];
}

class TimeOfDay extends Equatable {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  String format() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [hour, minute];
}
