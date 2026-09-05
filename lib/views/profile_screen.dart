import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/history_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Consumer2<ProfileProvider, HistoryProvider>(
                  builder: (context, profileProvider, historyProvider, child) {
                    final profile = profileProvider.profile;
                    final username = profile?.username ?? 'Student';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 38,
                                  backgroundColor: AppColors.navyBlue,
                                  child: Text(
                                    username.trim().isEmpty
                                        ? 'N'
                                        : username.trim()[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  username,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit username'),
                                  onPressed: () =>
                                      _showUsernameDialog(context, username),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_outlined,
                                  color: AppColors.darkGold,
                                  size: 32,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${historyProvider.activityStreak} day streak',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(fontSize: 20),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'A day counts when you complete at least one exam.',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Activity',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontSize: 20),
                                ),
                                const SizedBox(height: 12),
                                _MetricRow(
                                  icon: Icons.fact_check_outlined,
                                  label: 'Completed attempts',
                                  value: historyProvider.attempts.length
                                      .toString(),
                                ),
                                _MetricRow(
                                  icon: Icons.percent,
                                  label: 'Average score',
                                  value: _averageScore(historyProvider),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUsernameDialog(
    BuildContext context,
    String currentUsername,
  ) async {
    final controller = TextEditingController(text: currentUsername);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Username'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || !context.mounted) return;
    final saved = await context.read<ProfileProvider>().updateUsername(result);
    if (!context.mounted || saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<ProfileProvider>().error ??
              'The username could not be saved.',
        ),
      ),
    );
  }

  String _averageScore(HistoryProvider historyProvider) {
    if (historyProvider.attempts.isEmpty) return '0%';
    final total = historyProvider.attempts.fold<double>(
      0,
      (sum, attempt) => sum + attempt.scorePercentage,
    );
    return '${(total / historyProvider.attempts.length).toStringAsFixed(0)}%';
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lightNavy),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
