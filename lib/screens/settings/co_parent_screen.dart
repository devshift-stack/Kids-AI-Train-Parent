import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/co_parent_provider.dart';
import '../../services/co_parent_service.dart';

class CoParentScreen extends ConsumerStatefulWidget {
  const CoParentScreen({super.key});

  @override
  ConsumerState<CoParentScreen> createState() => _CoParentScreenState();
}

class _CoParentScreenState extends ConsumerState<CoParentScreen> {
  @override
  Widget build(BuildContext context) {
    final coParentsAsync = ref.watch(coParentsProvider);
    final inviteCodeAsync = ref.watch(currentInviteCodeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Elternteile verwalten',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInviteSection(inviteCodeAsync),
            const SizedBox(height: 24),
            _buildJoinSection(),
            const SizedBox(height: 24),
            _buildLinkedParentsSection(coParentsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteSection(AsyncValue<CoParentInviteInfo?> inviteCodeAsync) {
    return _buildSection(
      title: 'Elternteil einladen',
      icon: Icons.person_add,
      child: Column(
        children: [
          Text(
            'Erstelle einen Code, den der andere Elternteil eingeben kann.',
            style: TextStyle(color: Colors.white.withValues(alpha:0.7)),
          ),
          const SizedBox(height: 16),
          inviteCodeAsync.when(
            data: (info) => info != null
                ? _buildActiveCode(info)
                : _buildGenerateButton(),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Fehler: $e', style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCode(CoParentInviteInfo info) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha:0.5)),
          ),
          child: Column(
            children: [
              Text(
                info.code,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Noch ${info.daysRemaining} Tage gültig',
                style: TextStyle(color: Colors.white.withValues(alpha:0.5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyCode(info.code),
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
                onPressed: _generateNewCode,
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
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generateNewCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Einladungscode erstellen'),
      ),
    );
  }

  Widget _buildJoinSection() {
    return _buildSection(
      title: 'Code eingeben',
      icon: Icons.input,
      child: Column(
        children: [
          Text(
            'Hast du einen Code vom anderen Elternteil erhalten?',
            style: TextStyle(color: Colors.white.withValues(alpha:0.7)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showJoinDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Code eingeben'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedParentsSection(AsyncValue<List<CoParentInfo>> coParentsAsync) {
    return _buildSection(
      title: 'Verknüpfte Elternteile',
      icon: Icons.people,
      child: coParentsAsync.when(
        data: (coParents) => coParents.isEmpty
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white.withValues(alpha:0.5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Noch keine Elternteile verknüpft.',
                        style: TextStyle(color: Colors.white.withValues(alpha:0.5)),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: coParents.map((cp) => _buildCoParentTile(cp)).toList(),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Fehler: $e', style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }

  Widget _buildCoParentTile(CoParentInfo coParent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF6C63FF),
            child: Text(
              coParent.email.isNotEmpty ? coParent.email[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coParent.email,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Verknüpft am ${_formatDate(coParent.linkedAt)}',
                  style: TextStyle(color: Colors.white.withValues(alpha:0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.link_off, color: Colors.redAccent),
            onPressed: () => _confirmUnlink(coParent),
          ),
        ],
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

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code kopiert!')),
    );
  }

  Future<void> _generateNewCode() async {
    final notifier = ref.read(coParentNotifierProvider.notifier);
    final code = await notifier.generateInviteCode();
    if (code != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Neuer Code: $code')),
      );
    }
  }

  Future<void> _showJoinDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('Code eingeben', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, letterSpacing: 4),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'ABC123',
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
            child: const Text('Verknüpfen'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _joinWithCode(result);
    }
  }

  Future<void> _joinWithCode(String code) async {
    final notifier = ref.read(coParentNotifierProvider.notifier);
    final result = await notifier.joinWithCode(code);

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler bei der Verknüpfung')),
      );
    } else if (result.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erfolgreich mit ${result.targetEmail} verknüpft!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Unbekannter Fehler'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmUnlink(CoParentInfo coParent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('Verknüpfung aufheben?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Möchtest du die Verknüpfung mit ${coParent.email} aufheben?\n\nDer andere Elternteil verliert den Zugriff auf die Kinder.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Aufheben'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(coParentNotifierProvider.notifier);
      await notifier.unlinkCoParent(coParent.id);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
