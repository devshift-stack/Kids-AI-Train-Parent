import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/child.dart';
import '../../models/accessibility_settings.dart';
import '../../providers/children_provider.dart';
import 'time_limit_screen.dart';

class ChildDetailScreen extends ConsumerWidget {
  final Child child;

  const ChildDetailScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          child.name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 24),
            _buildParentCodeSection(context, ref),
            const SizedBox(height: 24),
            _buildTimeLimitSection(context),
            const SizedBox(height: 24),
            _buildLeaderboardSection(context, ref),
            const SizedBox(height: 24),
            _buildSubtitlesSection(context, ref),
            const SizedBox(height: 24),
            _buildGamesSection(context, ref),
            const SizedBox(height: 24),
            _buildYouTubeSection(context, ref),
            const SizedBox(height: 24),
            _buildLinkedDevicesSection(context, ref),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withValues(alpha:0.3),
            const Color(0xFF6C63FF).withValues(alpha:0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF6C63FF),
            child: Text(
              child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${child.age} Jahre alt',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha:0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: child.isLinked ? Colors.green.withValues(alpha:0.2) : Colors.orange.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    child.isLinked ? 'Verbunden' : 'Nicht verbunden',
                    style: TextStyle(
                      color: child.isLinked ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentCodeSection(BuildContext context, WidgetRef ref) {
    final isExpired = DateTime.now().isAfter(child.parentCodeExpiresAt);

    return _buildSection(
      title: 'Verbindungscode',
      icon: Icons.qr_code,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  child.parentCode,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: isExpired ? Colors.grey : Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isExpired
                      ? 'Code abgelaufen'
                      : 'Gültig bis ${_formatDate(child.parentCodeExpiresAt)}',
                  style: TextStyle(
                    color: isExpired ? Colors.redAccent : Colors.white.withValues(alpha:0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyCode(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Kopieren'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _regenerateCode(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Neuer Code'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLimitSection(BuildContext context) {
    final timeLimit = child.timeLimit;

    return _buildSection(
      title: 'Zeitlimits',
      icon: Icons.timer,
      child: Column(
        children: [
          _buildSettingRow(
            'Tägliches Limit',
            '${timeLimit.dailyMinutes} Minuten',
            Icons.schedule,
          ),
          _buildSettingRow(
            'Pause nach',
            '${timeLimit.breakIntervalMinutes} Minuten',
            Icons.pause_circle_outline,
          ),
          _buildSettingRow(
            'Pausendauer',
            '${timeLimit.breakDurationMinutes} Minuten',
            Icons.coffee,
          ),
          _buildSettingRow(
            'Schlafenszeit',
            timeLimit.bedtimeEnabled
                ? '${timeLimit.bedtimeStart.format()} - ${timeLimit.bedtimeEnd.format()}'
                : 'Deaktiviert',
            Icons.bedtime,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TimeLimitScreen(child: child),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
              child: const Text('Zeitlimits bearbeiten'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection(BuildContext context, WidgetRef ref) {
    final consent = child.leaderboardConsent;

    return _buildSection(
      title: 'Ranglisten',
      icon: Icons.leaderboard,
      child: Column(
        children: [
          _buildToggleRow(
            'Ranglisten sehen',
            'Kind kann Ranglisten anderer sehen',
            consent.canSeeLeaderboard,
            (value) async {
              final notifier = ref.read(childrenNotifierProvider.notifier);
              await notifier.updateChild(
                child.copyWith(
                  leaderboardConsent: consent.copyWith(canSeeLeaderboard: value),
                ),
              );
            },
          ),
          _buildToggleRow(
            'Auf Ranglisten erscheinen',
            'Kind ist für andere sichtbar',
            consent.canBeOnLeaderboard,
            (value) async {
              final notifier = ref.read(childrenNotifierProvider.notifier);
              await notifier.updateChild(
                child.copyWith(
                  leaderboardConsent: consent.copyWith(canBeOnLeaderboard: value),
                ),
              );
            },
          ),
          if (consent.canBeOnLeaderboard) ...[
            const SizedBox(height: 12),
            _buildSettingRow(
              'Anzeigename',
              consent.leaderboardDisplayName ?? consent.getDisplayName(child.name),
              Icons.badge,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtitlesSection(BuildContext context, WidgetRef ref) {
    final settings = child.accessibilitySettings;

    return _buildSection(
      title: 'Untertitel',
      icon: Icons.subtitles,
      child: Column(
        children: [
          _buildToggleRow(
            'Untertitel aktivieren',
            'Zeigt Text für Sprachausgabe an',
            settings.subtitlesEnabled,
            (value) async {
              final notifier = ref.read(childrenNotifierProvider.notifier);
              await notifier.updateChild(
                child.copyWith(
                  accessibilitySettings: settings.copyWith(subtitlesEnabled: value),
                ),
              );
            },
          ),
          if (settings.subtitlesEnabled) ...[
            const SizedBox(height: 16),
            _buildLanguageSelector(context, ref, settings),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    AccessibilitySettings settings,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sprache für Untertitel',
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AccessibilitySettings.availableLanguages.map((lang) {
              final isSelected = settings.subtitleLanguage == lang.code;
              return GestureDetector(
                onTap: () async {
                  final notifier = ref.read(childrenNotifierProvider.notifier);
                  await notifier.updateChild(
                    child.copyWith(
                      accessibilitySettings: settings.copyWith(subtitleLanguage: lang.code),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withValues(alpha:0.2),
                    ),
                  ),
                  child: Text(
                    lang.nativeName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha:0.8),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesSection(BuildContext context, WidgetRef ref) {
    // Spiele-Definitionen
    const games = [
      {'id': 'letters', 'name': 'ABC Buchstaben', 'icon': Icons.abc},
      {'id': 'numbers', 'name': '123 Zahlen', 'icon': Icons.pin},
      {'id': 'colors', 'name': 'Farben', 'icon': Icons.palette},
      {'id': 'shapes', 'name': 'Formen', 'icon': Icons.category},
      {'id': 'animals', 'name': 'Tiere', 'icon': Icons.pets},
      {'id': 'stories', 'name': 'Geschichten', 'icon': Icons.auto_stories},
      {'id': 'quiz', 'name': 'Quiz', 'icon': Icons.quiz},
    ];

    return _buildSection(
      title: 'Spiele',
      icon: Icons.sports_esports,
      child: Column(
        children: [
          Text(
            'Aktiviere oder deaktiviere einzelne Spiele für ${child.name}.',
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ...games.map((game) {
            final gameId = game['id'] as String;
            final gameName = game['name'] as String;
            final gameIcon = game['icon'] as IconData;

            // Hole aktuelle Einstellung (Default: aktiviert)
            final currentSettings = child.gameSettings[gameId] ?? const GameSettings();
            final isEnabled = currentSettings.isEnabled;

            return _buildGameToggle(
              gameId: gameId,
              name: gameName,
              icon: gameIcon,
              isEnabled: isEnabled,
              isLiankoOnly: gameId == 'quiz',
              onChanged: (value) async {
                final notifier = ref.read(childrenNotifierProvider.notifier);
                final updatedSettings = Map<String, GameSettings>.from(child.gameSettings);
                updatedSettings[gameId] = currentSettings.copyWith(isEnabled: value);

                await notifier.updateChild(
                  child.copyWith(gameSettings: updatedSettings),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGameToggle({
    required String gameId,
    required String name,
    required IconData icon,
    required bool isEnabled,
    required Function(bool) onChanged,
    bool isLiankoOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:isEnabled ? 0.08 : 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? const Color(0xFF6C63FF).withValues(alpha:0.3)
              : Colors.white.withValues(alpha:0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isEnabled ? const Color(0xFF6C63FF) : Colors.white38,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isLiankoOnly)
                  Text(
                    'Nur in Lianko',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.4),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeSection(BuildContext context, WidgetRef ref) {
    final settings = child.youtubeSettings;

    return _buildSection(
      title: 'YouTube Belohnungssystem',
      icon: Icons.play_circle_fill,
      child: Column(
        children: [
          // Aktivieren/Deaktivieren Toggle
          _buildToggleRow(
            'YouTube aktivieren',
            'Kind kann Videos als Belohnung schauen',
            settings.enabled,
            (value) async {
              final notifier = ref.read(childrenNotifierProvider.notifier);
              await notifier.updateChild(
                child.copyWith(
                  youtubeSettings: settings.copyWith(enabled: value),
                ),
              );
            },
          ),
          if (settings.enabled) ...[
            const SizedBox(height: 16),
            // Minuten Video vor Aufgaben
            _buildSliderSetting(
              context,
              ref,
              label: 'Video-Zeit vor Aufgaben',
              value: settings.watchMinutesBeforeTasks,
              min: 5,
              max: 30,
              unit: 'Min',
              onChanged: (value) async {
                final notifier = ref.read(childrenNotifierProvider.notifier);
                await notifier.updateChild(
                  child.copyWith(
                    youtubeSettings: settings.copyWith(watchMinutesBeforeTasks: value),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Anzahl Aufgaben
            _buildSliderSetting(
              context,
              ref,
              label: 'Aufgaben zum Freischalten',
              value: settings.tasksRequired,
              min: 1,
              max: 10,
              unit: 'Aufgaben',
              onChanged: (value) async {
                final notifier = ref.read(childrenNotifierProvider.notifier);
                await notifier.updateChild(
                  child.copyWith(
                    youtubeSettings: settings.copyWith(tasksRequired: value),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Max tägliche Zeit
            _buildSliderSetting(
              context,
              ref,
              label: 'Max. YouTube-Zeit pro Tag',
              value: settings.maxDailyMinutes,
              min: 15,
              max: 120,
              unit: 'Min',
              onChanged: (value) async {
                final notifier = ref.read(childrenNotifierProvider.notifier);
                await notifier.updateChild(
                  child.copyWith(
                    youtubeSettings: settings.copyWith(maxDailyMinutes: value),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF0000).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFFF6B6B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nach ${settings.watchMinutesBeforeTasks} Min Video muss ${child.name} ${settings.tasksRequired} Aufgaben lösen.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required int value,
    required int min,
    required int max,
    required String unit,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            Text(
              '$value $unit',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: const Color(0xFF6C63FF),
          inactiveColor: Colors.white.withValues(alpha: 0.2),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  Widget _buildLinkedDevicesSection(BuildContext context, WidgetRef ref) {
    return _buildSection(
      title: 'Verbundene Geräte',
      icon: Icons.devices,
      child: child.linkedDeviceIds.isEmpty
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withValues(alpha:0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Noch keine Geräte verbunden.\nGib den Code in der Kinder-App ein.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha:0.5),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: child.linkedDeviceIds.map((deviceId) {
                return ListTile(
                  leading: const Icon(Icons.phone_android, color: Colors.white54),
                  title: Text(
                    'Gerät ${deviceId.substring(0, 8)}...',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.link_off, color: Colors.redAccent),
                    onPressed: () => _confirmUnlinkDevice(context, ref, deviceId),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Future<void> _confirmUnlinkDevice(BuildContext context, WidgetRef ref, String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text(
          'Gerät trennen?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Das Gerät wird getrennt und muss sich mit einem neuen Code erneut verbinden.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Trennen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(childrenNotifierProvider.notifier);
      final updatedDeviceIds = List<String>.from(child.linkedDeviceIds)
        ..remove(deviceId);

      await notifier.updateChild(
        child.copyWith(
          linkedDeviceIds: updatedDeviceIds,
          isLinked: updatedDeviceIds.isNotEmpty,
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gerät getrennt')),
        );
      }
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha:0.7)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: child.parentCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code kopiert!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _regenerateCode(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text(
          'Neuen Code generieren?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Der alte Code wird ungültig. Bereits verbundene Geräte bleiben verbunden.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Ja, neuen Code'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(childrenNotifierProvider.notifier);
      final newCode = await notifier.regenerateParentCode(child.id);
      if (newCode != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Neuer Code: $newCode'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text(
          'Kind löschen?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Möchtest du ${child.name} wirklich löschen? Alle Daten werden unwiderruflich gelöscht.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(childrenNotifierProvider.notifier);
      await notifier.deleteChild(child.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
