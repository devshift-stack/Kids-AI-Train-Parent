import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/child.dart';
import '../../models/accessibility_settings.dart';
import '../../providers/children_provider.dart';

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
            _buildLeaderboardSection(context),
            const SizedBox(height: 24),
            _buildSubtitlesSection(context, ref),
            const SizedBox(height: 24),
            _buildLinkedDevicesSection(),
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
            const Color(0xFF6C63FF).withOpacity(0.3),
            const Color(0xFF6C63FF).withOpacity(0.1),
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
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: child.isLinked ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
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
              color: Colors.white.withOpacity(0.05),
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
                    color: isExpired ? Colors.redAccent : Colors.white.withOpacity(0.5),
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
                // TODO: Navigate to time limit settings
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

  Widget _buildLeaderboardSection(BuildContext context) {
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
            (value) {
              // TODO: Update leaderboard consent
            },
          ),
          _buildToggleRow(
            'Auf Ranglisten erscheinen',
            'Kind ist für andere sichtbar',
            consent.canBeOnLeaderboard,
            (value) {
              // TODO: Update leaderboard consent
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sprache für Untertitel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
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
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    lang.nativeName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
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

  Widget _buildLinkedDevicesSection() {
    return _buildSection(
      title: 'Verbundene Geräte',
      icon: Icons.devices,
      child: child.linkedDeviceIds.isEmpty
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Noch keine Geräte verbunden.\nGib den Code in der Kinder-App ein.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
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
                    onPressed: () {
                      // TODO: Unlink device
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
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
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6C63FF),
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
