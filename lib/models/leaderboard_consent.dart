import 'package:equatable/equatable.dart';

class LeaderboardConsent extends Equatable {
  /// Kind darf Ranglisten anderer Kinder sehen
  final bool canSeeLeaderboard;

  /// Kind erscheint auf Ranglisten für andere sichtbar
  final bool canBeOnLeaderboard;

  /// Anzeigename auf Ranglisten (statt echtem Namen)
  final String? leaderboardDisplayName;

  /// Nur Altersgruppe zeigen statt exaktem Alter
  final bool showAgeGroupOnly;

  const LeaderboardConsent({
    this.canSeeLeaderboard = false,
    this.canBeOnLeaderboard = false,
    this.leaderboardDisplayName,
    this.showAgeGroupOnly = true,
  });

  factory LeaderboardConsent.fromMap(Map<String, dynamic> map) {
    return LeaderboardConsent(
      canSeeLeaderboard: map['canSeeLeaderboard'] ?? false,
      canBeOnLeaderboard: map['canBeOnLeaderboard'] ?? false,
      leaderboardDisplayName: map['leaderboardDisplayName'],
      showAgeGroupOnly: map['showAgeGroupOnly'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'canSeeLeaderboard': canSeeLeaderboard,
      'canBeOnLeaderboard': canBeOnLeaderboard,
      'leaderboardDisplayName': leaderboardDisplayName,
      'showAgeGroupOnly': showAgeGroupOnly,
    };
  }

  LeaderboardConsent copyWith({
    bool? canSeeLeaderboard,
    bool? canBeOnLeaderboard,
    String? leaderboardDisplayName,
    bool? showAgeGroupOnly,
  }) {
    return LeaderboardConsent(
      canSeeLeaderboard: canSeeLeaderboard ?? this.canSeeLeaderboard,
      canBeOnLeaderboard: canBeOnLeaderboard ?? this.canBeOnLeaderboard,
      leaderboardDisplayName: leaderboardDisplayName ?? this.leaderboardDisplayName,
      showAgeGroupOnly: showAgeGroupOnly ?? this.showAgeGroupOnly,
    );
  }

  /// Gibt den Anzeigenamen zurück (oder Fallback)
  String getDisplayName(String childName) {
    if (leaderboardDisplayName != null && leaderboardDisplayName!.isNotEmpty) {
      return leaderboardDisplayName!;
    }
    // Fallback: Erste 2 Buchstaben + ***
    if (childName.length >= 2) {
      return '${childName.substring(0, 2)}***';
    }
    return '${childName[0]}***';
  }

  @override
  List<Object?> get props => [canSeeLeaderboard, canBeOnLeaderboard, leaderboardDisplayName, showAgeGroupOnly];
}
