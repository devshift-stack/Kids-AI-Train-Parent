import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/children_provider.dart';
import '../../models/child.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _selectedAge = 6;
  bool _isLoading = false;
  Child? _createdChild;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _createdChild != null ? 'Kind erstellt!' : 'Kind hinzufügen',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _createdChild != null
          ? _buildSuccessView()
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wie heißt dein Kind?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Name eingeben',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha:0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.person, color: Colors.white54),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte gib einen Namen ein';
                }
                if (value.trim().length < 2) {
                  return 'Name muss mindestens 2 Zeichen haben';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Wie alt ist dein Kind?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildAgeSelector(),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createChild,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Kind erstellen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$_selectedAge Jahre',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6C63FF),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF6C63FF),
              overlayColor: const Color(0xFF6C63FF).withValues(alpha:0.2),
            ),
            child: Slider(
              value: _selectedAge.toDouble(),
              min: 3,
              max: 12,
              divisions: 9,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedAge = value.round();
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3 Jahre',
                style: TextStyle(color: Colors.white.withValues(alpha:0.5)),
              ),
              Text(
                '12 Jahre',
                style: TextStyle(color: Colors.white.withValues(alpha:0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha:0.2),
            ),
            child: const Icon(
              Icons.check,
              size: 50,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '${_createdChild!.name} wurde erstellt!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Gib diesen Code in der Kinder-App ein:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha:0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildParentCodeDisplay(),
          const SizedBox(height: 16),
          Text(
            'Gültig für 7 Tage',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha:0.5),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyCode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Code kopieren'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Fertig'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParentCodeDisplay() {
    final code = _createdChild!.parentCode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha:0.5),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: code.split('').map((char) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              char,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _createChild() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final notifier = ref.read(childrenNotifierProvider.notifier);
    final child = await notifier.createChild(
      _nameController.text.trim(),
      _selectedAge,
    );

    setState(() {
      _isLoading = false;
      _createdChild = child;
    });
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _createdChild!.parentCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code kopiert!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
