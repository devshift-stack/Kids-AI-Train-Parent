import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pin_provider.dart';
import 'co_parent_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinConfig = ref.watch(pinConfigProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Einstellungen',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Familie',
            children: [
              _buildSettingTile(
                icon: Icons.people,
                title: 'Elternteile verwalten',
                subtitle: 'Weiteren Elternteil einladen',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoParentScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Sicherheit',
            children: [
              _buildSettingTile(
                icon: Icons.lock,
                title: 'PIN-Schutz',
                subtitle: pinConfig.isPinEnabled ? 'Aktiviert' : 'Deaktiviert',
                trailing: Switch(
                  value: pinConfig.isPinEnabled,
                  onChanged: (value) {
                    if (value) {
                      _showSetPinDialog(context, ref);
                    } else {
                      _showDisablePinDialog(context, ref);
                    }
                  },
                  activeTrackColor: const Color(0xFF6C63FF),
                ),
              ),
              if (pinConfig.isPinEnabled)
                _buildSettingTile(
                  icon: Icons.edit,
                  title: 'PIN ändern',
                  subtitle: 'Neuen PIN festlegen',
                  onTap: () => _showChangePinDialog(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.white70),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withValues(alpha:0.5), fontSize: 12),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }

  Future<void> _showSetPinDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('PIN festlegen', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '••••',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha:0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (pin != null && pin.length == 4) {
      final pinNotifier = ref.read(pinConfigProvider.notifier);
      await pinNotifier.setPin(pin);
    }
  }

  Future<void> _showDisablePinDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('PIN deaktivieren', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gib deinen aktuellen PIN ein:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha:0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Deaktivieren'),
          ),
        ],
      ),
    );

    if (pin != null && pin.length == 4) {
      final pinNotifier = ref.read(pinConfigProvider.notifier);
      final success = await pinNotifier.disablePin(pin);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falscher PIN'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _showChangePinDialog(BuildContext context, WidgetRef ref) async {
    final oldController = TextEditingController();
    final newController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('PIN ändern', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Alter PIN',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha:0.5)),
                filled: true,
                fillColor: Colors.white.withValues(alpha:0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Neuer PIN',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha:0.5)),
                filled: true,
                fillColor: Colors.white.withValues(alpha:0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'old': oldController.text,
              'new': newController.text,
            }),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            child: const Text('Ändern'),
          ),
        ],
      ),
    );

    if (result != null && result['old']!.length == 4 && result['new']!.length == 4) {
      final pinNotifier = ref.read(pinConfigProvider.notifier);
      final success = await pinNotifier.changePin(result['old']!, result['new']!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'PIN geändert' : 'Falscher PIN'),
            backgroundColor: success ? Colors.green : Colors.redAccent,
          ),
        );
      }
    }
  }

}
