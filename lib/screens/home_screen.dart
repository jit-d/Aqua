import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/container_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/water_provider.dart';
import '../widgets/quick_add_button.dart';
import '../widgets/living_tank.dart';
import '../utils/app_constants.dart';
import '../utils/date_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WaterProvider>();
    if (wp.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: wp.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${AppDateUtils.greeting()} 👋',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(AppDateUtils.formatDate(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          Consumer<WaterProvider>(
            builder: (_, wp, __) {
              if (wp.weatherData == null) return const SizedBox.shrink();
              final isHot = wp.weatherBonusMl > 0;
              final isRain = wp.weatherData!.avgHumidity > 80;
              final icon = isHot ? Icons.wb_sunny : (isRain ? Icons.water_drop : Icons.cloud_outlined);
              final color = isHot ? Colors.orange : (isRain ? Colors.blue : Theme.of(context).colorScheme.primary);
              
              return Card(
                elevation: 2,
                color: color.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: color, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${wp.weatherData!.city} Weather', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Max ${wp.weatherData!.maxTempC.round()}°C • ${wp.weatherData!.avgHumidity.round()}% Humidity', 
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isHot 
                            ? 'Because it is hot today, we added +${wp.weatherBonusMl}ml to your goal. Drink before you feel thirsty.'
                            : 'Comfortable weather today. Stick to your standard goal.',
                        style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Center(
            child: LivingTank(
              progress: wp.progress,
              totalMl: wp.todayTotal,
              goalMl: wp.todayGoal,
            ),
          ),
          const SizedBox(height: 16),
          if (wp.catchUpMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          wp.catchUpMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Consumer<ReminderProvider>(
            builder: (_, rp, __) {
              if (rp.loading) return const SizedBox.shrink();
              if (!rp.enabled) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_off_outlined),
                    title: const Text('Reminders are off'),
                    subtitle: const Text('Enable to get hydration nudges'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Open the Reminders tab')),
                      );
                    },
                  ),
                );
              }
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Reminders active'),
                  subtitle: Text('Every ${rp.interval} minutes'),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Consumer<ContainerProvider>(
            builder: (_, cp, __) {
              if (cp.loading || cp.containers.isEmpty) {
                return const SizedBox.shrink();
              }
              final quick = cp.containers.take(4).toList();
              return Row(
                children: [
                  for (int i = 0; i < quick.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: QuickAddButton(
                        amount: quick[i].volumeMl,
                        onTap: () => wp.addWater(quick[i].volumeMl,
                            drinkType: quick[i].name),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _openCustomAdd(context, wp),
            icon: const Icon(Icons.add),
            label: const Text('Custom amount'),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's History",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (wp.todayEntries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                          child: Text('No entries yet. Add your first glass!')),
                    )
                  else
                    ...wp.todayEntries.map((e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.local_drink_outlined),
                          title: Text('${e.amountMl} ml'),
                          subtitle: Text(
                              '${e.drinkType} • ${AppDateUtils.formatTime(e.createdAt)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => wp.deleteEntry(e.id!),
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40), // End of page
          Center(
            child: Text('You are all caught up! 💧', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 80), // Space for Bottom Nav
        ],
      ),
    );
  }

  Future<void> _openCustomAdd(BuildContext context, WaterProvider wp) async {
    final amountCtrl = TextEditingController();
    String drinkType = AppConstants.drinkTypes.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add water',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (ml)',
                  hintText: 'e.g. 300',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: drinkType,
                decoration: const InputDecoration(labelText: 'Drink type'),
                items: AppConstants.drinkTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSt(() => drinkType = v);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final v = int.tryParse(amountCtrl.text.trim());
                        if (v == null || v <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text('Enter a valid amount')));
                          return;
                        }
                        await wp.addWater(v, drinkType: drinkType);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}