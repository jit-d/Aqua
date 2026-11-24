import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import '../widgets/quick_add_button.dart';
import '../widgets/water_progress_ring.dart';
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
          Center(
            child: WaterProgressRing(
              progress: wp.progress,
              totalMl: wp.todayTotal,
              goalMl: wp.todayGoal,
              remainingMl: wp.remaining,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (final a in AppConstants.quickAddAmounts)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: QuickAddButton(amount: a, onTap: () => wp.addWater(a)),
                ),
            ],
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
        ],
      ),
    );
  }
}
