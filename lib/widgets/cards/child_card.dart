import 'package:flutter/material.dart';
import '../../models/child.dart';

class ChildCard extends StatelessWidget {
  final Child child;
  final VoidCallback onTap;

  const ChildCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getColorForAge(child.age).withValues(alpha:0.3),
              _getColorForAge(child.age).withValues(alpha:0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha:0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _getColorForAge(child.age),
                    child: Text(
                      child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${child.age} Jahre',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha:0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDeviceCount(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isLinked = child.isLinked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLinked
            ? Colors.green.withValues(alpha:0.2)
            : Colors.orange.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLinked ? Icons.link : Icons.link_off,
            size: 12,
            color: isLinked ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isLinked ? 'Aktiv' : 'Warte',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isLinked ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCount() {
    final deviceCount = child.linkedDeviceIds.length;
    return Row(
      children: [
        Icon(
          Icons.devices,
          size: 14,
          color: Colors.white.withValues(alpha:0.4),
        ),
        const SizedBox(width: 4),
        Text(
          '$deviceCount ${deviceCount == 1 ? 'Gerät' : 'Geräte'}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha:0.4),
          ),
        ),
      ],
    );
  }

  Color _getColorForAge(int age) {
    if (age <= 5) return const Color(0xFFFF6B6B); // Rot für Kleine
    if (age <= 8) return const Color(0xFF6C63FF); // Lila für Mittlere
    return const Color(0xFF4ECDC4); // Türkis für Größere
  }
}
