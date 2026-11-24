import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/water_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  int _goal = AppConstants.defaultGoalMl;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<WaterProvider>().setGoal(_goal);
    await context.read<SettingsProvider>().completeOnboarding();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _welcome(),
                  _goalPage(),
                  _reminderPage(),
                  _permissionPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (_page < 3)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Skip'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      if (_page < 3) {
                        await _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      } else {
                        await _finish();
                      }
                    },
                    child: Text(_page < 3 ? 'Next' : 'Get started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcome() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop,
              size: 96, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text('Welcome to ${AppConstants.appName}',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(AppConstants.tagline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _goalPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Choose your daily goal',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              'Pick a starting target. You can change it any time in Settings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          ...AppConstants.presetGoals.map((g) => Card(
                child: RadioListTile<int>(
                  title: Text('$g ml'),
                  value: g,
                  groupValue: _goal,
                  onChanged: (v) {
                    if (v != null) setState(() => _goal = v);
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _reminderPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.alarm,
              size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text('Stay on track with reminders',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              'You can set reminder times and intervals any time in the Reminders tab.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _permissionPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.notifications_active,
              size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text('Allow notifications',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              'Aqua Reminder needs permission to send hydration reminders. You can change this later in Android settings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              final granted =
                  await NotificationService().requestPermissions();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(granted
                    ? 'Notifications enabled'
                    : 'Notifications not granted — you can enable them later'),
              ));
            },
            child: const Text('Request permission'),
          ),
        ],
      ),
    );
  }
}