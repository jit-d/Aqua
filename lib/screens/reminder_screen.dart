import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/container_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_constants.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  String _fmt(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    final ampm = h < 12 ? 'AM' : 'PM';
    final hh = h % 12 == 0 ? 12 : h % 12;
    return '$hh:${m.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _pickTime(
      BuildContext context, int current, ValueChanged<int> onPicked) async {
    final h = current ~/ 60;
    final m = current % 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
    );
    if (picked != null) onPicked(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReminderProvider>();
    if (rp.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Reminders',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            title: const Text('Enable reminders'),
            subtitle: const Text('Get periodic hydration nudges during your day'),
            value: rp.enabled,
            onChanged: (v) => rp.setEnabled(v),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Start time'),
                trailing: Text(_fmt(rp.startMinutes),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () =>
                    _pickTime(context, rp.startMinutes, rp.setStart),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('End time'),
                trailing: Text(_fmt(rp.endMinutes),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _pickTime(context, rp.endMinutes, rp.setEnd),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Interval'),
                trailing: DropdownButton<int>(
                  value: AppConstants.reminderIntervals.contains(rp.interval)
                      ? rp.interval
                      : null,
                  items: AppConstants.reminderIntervals
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text('$e min')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) rp.setInterval(v);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Quiet hours'),
                subtitle: Text(
                    '${_fmt(rp.quietStart)} – ${_fmt(rp.quietEnd)}'),
                value: rp.quietEnabled,
                onChanged: rp.setQuietEnabled,
              ),
              if (rp.quietEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  title: const Text('Quiet start'),
                  trailing: Text(_fmt(rp.quietStart)),
                  onTap: () =>
                      _pickTime(context, rp.quietStart, rp.setQuietStart),
                ),
                ListTile(
                  title: const Text('Quiet end'),
                  trailing: Text(_fmt(rp.quietEnd)),
                  onTap: () =>
                      _pickTime(context, rp.quietEnd, rp.setQuietEnd),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Aqua Call Mode (Full-Screen)'),
                subtitle: const Text('Rings like a phone call. Highly visible.'),
                value: rp.callMode,
                onChanged: rp.setCallMode,
              ),
              if (rp.callMode) ...[
                const Divider(height: 1),
                ListTile(
                  title: const Text('Notification Sound'),
                  subtitle: Text(rp.customSound ?? 'Default Alarm Sound'),
                  trailing: const Icon(Icons.music_note),
                  onTap: () {
                    // In a real app, you'd use flutter_ringtone_player or native picker.
                    // For this snippet, we'll cycle through default system alarms.
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Select Sound'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Default Alarm'),
                              onTap: () { rp.setCustomSound(null); Navigator.pop(ctx); },
                            ),
                            ListTile(
                              title: const Text('Ping (System)'),
                              onTap: () { rp.setCustomSound('content://settings/system/notification_sound'); Navigator.pop(ctx); },
                            ),
                            ListTile(
                              title: const Text('Chime (System)'),
                              onTap: () { rp.setCustomSound('content://settings/system/ringtone'); Navigator.pop(ctx); },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            title: const Text('Pause after goal reached'),
            subtitle: const Text(
                'Stop reminders for the day once you hit your goal'),
            value: rp.pauseAfterGoal,
            onChanged: rp.setPauseAfterGoal,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            final cp = context.read<ContainerProvider>();
            final primary = cp.primary?.volumeMl ?? 250;
            NotificationService().showTestCall(primaryVolume: primary);
          },
          icon: const Icon(Icons.notifications_active),
          label: const Text('Send test notification'),
        ),
        const SizedBox(height: 12),
        Text(
          'Note: Android may deliver reminders a few minutes late to save battery. '
          'This is normal and expected.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}