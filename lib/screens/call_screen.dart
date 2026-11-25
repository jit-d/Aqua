import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import '../providers/container_provider.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _logged = false;

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WaterProvider>();
    final cp = context.watch<ContainerProvider>();
    final amount = cp.primary?.volumeMl ?? 250;

    return Scaffold(
      backgroundColor: const Color(0xFF1565C0), // Deep Blue
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.water_drop, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Aqua Reminder Call',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Time to drink $amount ml!',
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const Spacer(),
              
              if (!_logged) ...[
                // "Swipe Up" style confirmation button
                GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity! < 0) {
                      _logWater(wp, amount);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.keyboard_arrow_up, color: Color(0xFF1565C0), size: 30),
                        Text(
                          'Swipe up to Log',
                          style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Text('Logged! Stay hydrated 💧', style: TextStyle(color: Colors.white, fontSize: 20)),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.access_time, color: Colors.white70),
                    label: const Text('Snooze 5m', style: TextStyle(color: Colors.white70)),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.do_not_disturb_on_outlined, color: Colors.white70),
                    label: const Text('Later', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logWater(WaterProvider wp, int amount) async {
    await wp.addWater(amount, drinkType: 'Aqua Call');
    setState(() => _logged = true);
  }
}
