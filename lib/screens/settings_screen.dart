import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/water_dao.dart';
import '../providers/achievement_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/water_provider.dart';
import '../services/export_service.dart';
import '../utils/app_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final wp = context.watch<WaterProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        _SectionTitle('General'),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Daily water goal'),
                subtitle: Text('${wp.todayGoal} ml'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showGoalDialog(context, wp.todayGoal),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Measurement units'),
                trailing: DropdownButton<String>(
                  value: sp.unit,
                  items: const [
                    DropdownMenuItem(value: 'ml', child: Text('ml')),
                    DropdownMenuItem(value: 'oz', child: Text('oz')),
                  ],
                  onChanged: (v) {
                    if (v != null) sp.setUnit(v);
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('First day of week'),
                trailing: DropdownButton<int>(
                  value: sp.firstDayOfWeek,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Monday')),
                    DropdownMenuItem(value: 7, child: Text('Sunday')),
                  ],
                  onChanged: (v) {
                    if (v != null) sp.setFirstDayOfWeek(v);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _SectionTitle('Appearance'),
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('System default'),
                value: 'system',
                groupValue: sp.darkMode,
                onChanged: (v) => sp.setDarkMode(v!),
              ),
              RadioListTile<String>(
                title: const Text('Light'),
                value: 'light',
                groupValue: sp.darkMode,
                onChanged: (v) => sp.setDarkMode(v!),
              ),
              RadioListTile<String>(
                title: const Text('Dark'),
                value: 'dark',
                groupValue: sp.darkMode,
                onChanged: (v) => sp.setDarkMode(v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _SectionTitle('Data'),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Export records to CSV'),
                subtitle: const Text('Saved to app documents folder'),
                trailing: const Icon(Icons.download_outlined),
                onTap: () => _export(context),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Clear all data'),
                subtitle: const Text('Delete every entry and achievement'),
                trailing: const Icon(Icons.delete_forever_outlined),
                textColor: Theme.of(context).colorScheme.error,
                onTap: () => _confirmClear(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _SectionTitle('About'),
        Card(
          child: Column(
            children: const [
              ListTile(
                title: Text('Aqua Reminder'),
                subtitle: Text(AppConstants.tagline),
              ),
              Divider(height: 1),
              ListTile(
                title: Text('Version'),
                trailing: Text('1.0.0'),
              ),
              Divider(height: 1),
              ListTile(
                title: Text('Privacy'),
                subtitle: Text(
                  'All data stays on your device. No account, no network, no tracking.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showGoalDialog(BuildContext context, int current) async {
    final presets = AppConstants.presetGoals;
    final controller = TextEditingController(text: '$current');
    final waterProvider = context.read<WaterProvider>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily water goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (ml)'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: presets
                  .map((g) => ActionChip(
                        label: Text('$g'),
                        onPressed: () => controller.text = '$g',
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v > 0) {
                waterProvider.setGoal(v);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await ExportService().exportCsv();
      messenger.showSnackBar(SnackBar(content: Text('Exported to $path')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This permanently deletes all water records and achievements. It cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final waterProvider = context.read<WaterProvider>();
    final achievementProvider = context.read<AchievementProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await WaterDao().clearAll();
    await waterProvider.refresh();
    await achievementProvider.refresh();
    messenger.showSnackBar(const SnackBar(content: Text('All data cleared')));
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}