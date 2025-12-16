import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as material show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/child.dart';
import '../../models/time_limit.dart';
import '../../providers/children_provider.dart';

class TimeLimitScreen extends ConsumerStatefulWidget {
  final Child child;

  const TimeLimitScreen({super.key, required this.child});

  @override
  ConsumerState<TimeLimitScreen> createState() => _TimeLimitScreenState();
}

class _TimeLimitScreenState extends ConsumerState<TimeLimitScreen> {
  late int _dailyMinutes;
  late int _breakInterval;
  late int _breakDuration;
  late bool _bedtimeEnabled;
  late TimeOfDay _bedtimeStart;
  late TimeOfDay _bedtimeEnd;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final tl = widget.child.timeLimit;
    _dailyMinutes = tl.dailyMinutes;
    _breakInterval = tl.breakIntervalMinutes;
    _breakDuration = tl.breakDurationMinutes;
    _bedtimeEnabled = tl.bedtimeEnabled;
    _bedtimeStart = tl.bedtimeStart;
    _bedtimeEnd = tl.bedtimeEnd;
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _save() async {
    final newTimeLimit = TimeLimit(
      dailyMinutes: _dailyMinutes,
      breakIntervalMinutes: _breakInterval,
      breakDurationMinutes: _breakDuration,
      bedtimeEnabled: _bedtimeEnabled,
      bedtimeStart: _bedtimeStart,
      bedtimeEnd: _bedtimeEnd,
    );

    final notifier = ref.read(childrenNotifierProvider.notifier);
    await notifier.updateChild(
      widget.child.copyWith(timeLimit: newTimeLimit),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zeitlimits gespeichert')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Zeitlimits', style: TextStyle(color: Colors.white)),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _save,
              child: const Text('Speichern'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Tägliches Limit',
            icon: Icons.schedule,
            child: _buildSlider(
              value: _dailyMinutes,
              min: 15,
              max: 180,
              divisions: 11,
              label: '$_dailyMinutes Minuten',
              onChanged: (v) {
                setState(() => _dailyMinutes = v.round());
                _markChanged();
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Pause erzwingen nach',
            icon: Icons.pause_circle_outline,
            child: _buildSlider(
              value: _breakInterval,
              min: 10,
              max: 60,
              divisions: 10,
              label: '$_breakInterval Minuten',
              onChanged: (v) {
                setState(() => _breakInterval = v.round());
                _markChanged();
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Pausendauer',
            icon: Icons.coffee,
            child: _buildSlider(
              value: _breakDuration,
              min: 1,
              max: 15,
              divisions: 14,
              label: '$_breakDuration Minuten',
              onChanged: (v) {
                setState(() => _breakDuration = v.round());
                _markChanged();
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Schlafenszeit',
            icon: Icons.bedtime,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Schlafenszeit aktivieren',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Kein Spielen während der Schlafenszeit',
                    style: TextStyle(color: Colors.white.withValues(alpha:0.5)),
                  ),
                  value: _bedtimeEnabled,
                  activeTrackColor: const Color(0xFF6C63FF),
                  onChanged: (v) {
                    setState(() => _bedtimeEnabled = v);
                    _markChanged();
                  },
                ),
                if (_bedtimeEnabled) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeButton(
                          label: 'Von',
                          time: _bedtimeStart,
                          onTap: () => _pickTime(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeButton(
                          label: 'Bis',
                          time: _bedtimeEnd,
                          onTap: () => _pickTime(isStart: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoCard(),
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

  Widget _buildSlider({
    required int value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6C63FF),
          ),
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: const Color(0xFF6C63FF),
          inactiveColor: Colors.white.withValues(alpha:0.2),
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${min.round()} Min',
              style: TextStyle(color: Colors.white.withValues(alpha:0.5), fontSize: 12),
            ),
            Text(
              '${max.round()} Min',
              style: TextStyle(color: Colors.white.withValues(alpha:0.5), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha:0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _bedtimeStart : _bedtimeEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: material.TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              surface: Color(0xFF2D2D44),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _bedtimeStart = TimeOfDay(hour: picked.hour, minute: picked.minute);
        } else {
          _bedtimeEnd = TimeOfDay(hour: picked.hour, minute: picked.minute);
        }
      });
      _markChanged();
    }
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF6C63FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Änderungen werden sofort auf alle verbundenen Geräte übertragen.',
              style: TextStyle(
                color: Colors.white.withValues(alpha:0.8),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
