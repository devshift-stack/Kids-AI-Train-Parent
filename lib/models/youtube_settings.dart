import 'package:equatable/equatable.dart';

/// Einstellungen für YouTube-Belohnungssystem
///
/// Kind schaut X Minuten YouTube → muss Y Aufgaben erledigen → darf weiterschauen
class YouTubeSettings extends Equatable {
  /// YouTube-Feature aktiviert
  final bool enabled;

  /// Minuten Video schauen bevor Aufgaben erforderlich sind
  final int watchMinutesBeforeTasks;

  /// Anzahl Aufgaben die erledigt werden müssen
  final int tasksRequired;

  /// Schwierigkeit der Aufgaben (1-5)
  final int taskDifficulty;

  /// Maximale YouTube-Zeit pro Tag (0 = unbegrenzt)
  final int maxDailyMinutes;

  /// Nur freigegebene Videos erlauben
  final bool onlyApprovedVideos;

  /// Liste freigegebener YouTube Video/Channel IDs
  final List<String> approvedVideoIds;
  final List<String> approvedChannelIds;

  const YouTubeSettings({
    this.enabled = false,
    this.watchMinutesBeforeTasks = 10,
    this.tasksRequired = 3,
    this.taskDifficulty = 2,
    this.maxDailyMinutes = 60,
    this.onlyApprovedVideos = true,
    this.approvedVideoIds = const [],
    this.approvedChannelIds = const [],
  });

  /// Standard-Einstellungen für neue Kinder
  factory YouTubeSettings.defaults() {
    return const YouTubeSettings(
      enabled: false,
      watchMinutesBeforeTasks: 10,
      tasksRequired: 3,
      taskDifficulty: 2,
      maxDailyMinutes: 60,
      onlyApprovedVideos: true,
      approvedVideoIds: [],
      approvedChannelIds: [
        // Kindersichere Kanäle (Beispiele)
        // 'UC_x5XG1OV2P6uZZ5FSM9Ttw', // Google Developers
      ],
    );
  }

  factory YouTubeSettings.fromMap(Map<String, dynamic> map) {
    return YouTubeSettings(
      enabled: map['enabled'] ?? false,
      watchMinutesBeforeTasks: map['watchMinutesBeforeTasks'] ?? 10,
      tasksRequired: map['tasksRequired'] ?? 3,
      taskDifficulty: map['taskDifficulty'] ?? 2,
      maxDailyMinutes: map['maxDailyMinutes'] ?? 60,
      onlyApprovedVideos: map['onlyApprovedVideos'] ?? true,
      approvedVideoIds: List<String>.from(map['approvedVideoIds'] ?? []),
      approvedChannelIds: List<String>.from(map['approvedChannelIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'watchMinutesBeforeTasks': watchMinutesBeforeTasks,
      'tasksRequired': tasksRequired,
      'taskDifficulty': taskDifficulty,
      'maxDailyMinutes': maxDailyMinutes,
      'onlyApprovedVideos': onlyApprovedVideos,
      'approvedVideoIds': approvedVideoIds,
      'approvedChannelIds': approvedChannelIds,
    };
  }

  YouTubeSettings copyWith({
    bool? enabled,
    int? watchMinutesBeforeTasks,
    int? tasksRequired,
    int? taskDifficulty,
    int? maxDailyMinutes,
    bool? onlyApprovedVideos,
    List<String>? approvedVideoIds,
    List<String>? approvedChannelIds,
  }) {
    return YouTubeSettings(
      enabled: enabled ?? this.enabled,
      watchMinutesBeforeTasks: watchMinutesBeforeTasks ?? this.watchMinutesBeforeTasks,
      tasksRequired: tasksRequired ?? this.tasksRequired,
      taskDifficulty: taskDifficulty ?? this.taskDifficulty,
      maxDailyMinutes: maxDailyMinutes ?? this.maxDailyMinutes,
      onlyApprovedVideos: onlyApprovedVideos ?? this.onlyApprovedVideos,
      approvedVideoIds: approvedVideoIds ?? this.approvedVideoIds,
      approvedChannelIds: approvedChannelIds ?? this.approvedChannelIds,
    );
  }

  /// Beschreibung für UI
  String get description {
    if (!enabled) return 'Deaktiviert';
    return '$watchMinutesBeforeTasks Min Video → $tasksRequired Aufgaben';
  }

  @override
  List<Object?> get props => [
        enabled,
        watchMinutesBeforeTasks,
        tasksRequired,
        taskDifficulty,
        maxDailyMinutes,
        onlyApprovedVideos,
        approvedVideoIds,
        approvedChannelIds,
      ];
}
