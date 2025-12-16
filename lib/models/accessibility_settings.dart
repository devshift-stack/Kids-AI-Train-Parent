import 'package:equatable/equatable.dart';

/// Barrierefreiheit-Einstellungen für ein Kind
class AccessibilitySettings extends Equatable {
  /// Untertitel aktiviert (Standard: aus)
  final bool subtitlesEnabled;

  /// Sprache für Untertitel (ISO 639-1 Code)
  final String subtitleLanguage;

  /// Verfügbare Sprachen für Untertitel (aus Alanko/Lianko Apps)
  static const List<SubtitleLanguage> availableLanguages = [
    SubtitleLanguage(code: 'de', name: 'Deutsch', nativeName: 'Deutsch'),
    SubtitleLanguage(code: 'en', name: 'Englisch', nativeName: 'English'),
    SubtitleLanguage(code: 'bs', name: 'Bosnisch', nativeName: 'Bosanski'),
    SubtitleLanguage(code: 'hr', name: 'Kroatisch', nativeName: 'Hrvatski'),
    SubtitleLanguage(code: 'sr', name: 'Serbisch', nativeName: 'Srpski'),
    SubtitleLanguage(code: 'tr', name: 'Türkisch', nativeName: 'Türkçe'),
  ];

  const AccessibilitySettings({
    this.subtitlesEnabled = false, // Standard: AUS
    this.subtitleLanguage = 'de',
  });

  factory AccessibilitySettings.fromMap(Map<String, dynamic> map) {
    return AccessibilitySettings(
      subtitlesEnabled: map['subtitlesEnabled'] ?? false,
      subtitleLanguage: map['subtitleLanguage'] ?? 'de',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subtitlesEnabled': subtitlesEnabled,
      'subtitleLanguage': subtitleLanguage,
    };
  }

  AccessibilitySettings copyWith({
    bool? subtitlesEnabled,
    String? subtitleLanguage,
  }) {
    return AccessibilitySettings(
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
    );
  }

  /// Gibt den Namen der aktuellen Sprache zurück
  String get currentLanguageName {
    final lang = availableLanguages.firstWhere(
      (l) => l.code == subtitleLanguage,
      orElse: () => availableLanguages.first,
    );
    return lang.name;
  }

  @override
  List<Object?> get props => [subtitlesEnabled, subtitleLanguage];
}

/// Sprache für Untertitel
class SubtitleLanguage {
  final String code;
  final String name;
  final String nativeName;

  const SubtitleLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}
