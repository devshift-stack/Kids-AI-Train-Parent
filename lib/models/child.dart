import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'time_limit.dart';
import 'leaderboard_consent.dart';
import 'accessibility_settings.dart';
import 'youtube_settings.dart';

class Child extends Equatable {
  final String id;
  final String name;
  final int age;
  final String? avatarUrl;
  final String parentCode;
  final DateTime parentCodeExpiresAt;
  final bool isLinked;
  final List<String> linkedDeviceIds;
  final TimeLimit timeLimit;
  final LeaderboardConsent leaderboardConsent;
  final AccessibilitySettings accessibilitySettings;
  final Map<String, GameSettings> gameSettings;
  final YouTubeSettings youtubeSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Child({
    required this.id,
    required this.name,
    required this.age,
    this.avatarUrl,
    required this.parentCode,
    required this.parentCodeExpiresAt,
    this.isLinked = false,
    this.linkedDeviceIds = const [],
    required this.timeLimit,
    required this.leaderboardConsent,
    this.accessibilitySettings = const AccessibilitySettings(),
    this.gameSettings = const {},
    this.youtubeSettings = const YouTubeSettings(),
    required this.createdAt,
    required this.updatedAt,
  });

  factory Child.create({
    required String id,
    required String name,
    required int age,
    required String parentCode,
  }) {
    final now = DateTime.now();
    return Child(
      id: id,
      name: name,
      age: age,
      parentCode: parentCode,
      parentCodeExpiresAt: now.add(const Duration(days: 7)),
      timeLimit: TimeLimit.defaultLimit(),
      leaderboardConsent: const LeaderboardConsent(),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Child.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Child(
      id: doc.id,
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      avatarUrl: data['avatarUrl'],
      parentCode: data['parentCode'] ?? '',
      parentCodeExpiresAt: (data['parentCodeExpiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLinked: data['isLinked'] ?? false,
      linkedDeviceIds: List<String>.from(data['linkedDeviceIds'] ?? []),
      timeLimit: TimeLimit.fromMap(data['timeLimit'] ?? {}),
      leaderboardConsent: LeaderboardConsent.fromMap(data['leaderboardConsent'] ?? {}),
      accessibilitySettings: AccessibilitySettings.fromMap(data['accessibilitySettings'] ?? {}),
      gameSettings: _parseGameSettings(data['gameSettings']),
      youtubeSettings: YouTubeSettings.fromMap(data['youtubeSettings'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, GameSettings> _parseGameSettings(dynamic data) {
    if (data == null) return {};
    final map = data as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, GameSettings.fromMap(value)));
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'age': age,
      'avatarUrl': avatarUrl,
      'parentCode': parentCode,
      'parentCodeExpiresAt': Timestamp.fromDate(parentCodeExpiresAt),
      'isLinked': isLinked,
      'linkedDeviceIds': linkedDeviceIds,
      'timeLimit': timeLimit.toMap(),
      'leaderboardConsent': leaderboardConsent.toMap(),
      'accessibilitySettings': accessibilitySettings.toMap(),
      'gameSettings': gameSettings.map((key, value) => MapEntry(key, value.toMap())),
      'youtubeSettings': youtubeSettings.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  Child copyWith({
    String? name,
    int? age,
    String? avatarUrl,
    String? parentCode,
    DateTime? parentCodeExpiresAt,
    bool? isLinked,
    List<String>? linkedDeviceIds,
    TimeLimit? timeLimit,
    LeaderboardConsent? leaderboardConsent,
    AccessibilitySettings? accessibilitySettings,
    Map<String, GameSettings>? gameSettings,
    YouTubeSettings? youtubeSettings,
  }) {
    return Child(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      parentCode: parentCode ?? this.parentCode,
      parentCodeExpiresAt: parentCodeExpiresAt ?? this.parentCodeExpiresAt,
      isLinked: isLinked ?? this.isLinked,
      linkedDeviceIds: linkedDeviceIds ?? this.linkedDeviceIds,
      timeLimit: timeLimit ?? this.timeLimit,
      leaderboardConsent: leaderboardConsent ?? this.leaderboardConsent,
      accessibilitySettings: accessibilitySettings ?? this.accessibilitySettings,
      gameSettings: gameSettings ?? this.gameSettings,
      youtubeSettings: youtubeSettings ?? this.youtubeSettings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, age, parentCode, isLinked, timeLimit, leaderboardConsent, youtubeSettings];
}

class GameSettings extends Equatable {
  final bool isEnabled;
  final int maxDailyMinutes;
  final int difficultyLevel; // 1-5
  final bool soundEnabled;
  final bool voiceGuidanceEnabled;

  const GameSettings({
    this.isEnabled = true,
    this.maxDailyMinutes = 30,
    this.difficultyLevel = 3,
    this.soundEnabled = true,
    this.voiceGuidanceEnabled = true,
  });

  factory GameSettings.fromMap(Map<String, dynamic> map) {
    return GameSettings(
      isEnabled: map['isEnabled'] ?? true,
      maxDailyMinutes: map['maxDailyMinutes'] ?? 30,
      difficultyLevel: map['difficultyLevel'] ?? 3,
      soundEnabled: map['soundEnabled'] ?? true,
      voiceGuidanceEnabled: map['voiceGuidanceEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'maxDailyMinutes': maxDailyMinutes,
      'difficultyLevel': difficultyLevel,
      'soundEnabled': soundEnabled,
      'voiceGuidanceEnabled': voiceGuidanceEnabled,
    };
  }

  GameSettings copyWith({
    bool? isEnabled,
    int? maxDailyMinutes,
    int? difficultyLevel,
    bool? soundEnabled,
    bool? voiceGuidanceEnabled,
  }) {
    return GameSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      maxDailyMinutes: maxDailyMinutes ?? this.maxDailyMinutes,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
    );
  }

  @override
  List<Object?> get props => [isEnabled, maxDailyMinutes, difficultyLevel, soundEnabled, voiceGuidanceEnabled];
}
