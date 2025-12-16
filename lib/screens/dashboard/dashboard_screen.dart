import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/children_provider.dart';
import '../../models/child.dart';
import '../children/add_child_screen.dart';
import '../children/child_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/cards/child_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Kids AI Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: childrenAsync.when(
        data: (children) => _buildContent(context, ref, children),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, _) => Center(
          child: Text(
            'Fehler: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddChild(context),
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add),
        label: const Text('Kind hinzufügen'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Child> children) {
    if (children.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(childrenProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(children.length),
          const SizedBox(height: 24),
          _buildChildrenGrid(context, children),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care,
              size: 80,
              color: Colors.white.withValues(alpha:0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Noch keine Kinder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Füge dein erstes Kind hinzu, um die Lern-Apps zu verbinden.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha:0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddChild(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Kind hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int childCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Willkommen zurück!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha:0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$childCount ${childCount == 1 ? 'Kind' : 'Kinder'} verwaltet',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenGrid(BuildContext context, List<Child> children) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];
        return ChildCard(
          child: child,
          onTap: () => _navigateToChildDetail(context, child),
        );
      },
    );
  }

  void _navigateToAddChild(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddChildScreen(),
      ),
    );
  }

  void _navigateToChildDetail(BuildContext context, Child child) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChildDetailScreen(child: child),
      ),
    );
  }
}
