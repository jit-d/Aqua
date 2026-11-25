import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/container.dart';
import '../providers/container_provider.dart';

class ContainersScreen extends StatelessWidget {
  const ContainersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContainerProvider>();
    if (cp.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Containers')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'These are the quick-add buttons on your home screen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ...cp.containers.map((c) => Card(
                child: ListTile(
                  leading: Icon(_iconFor(c.icon)),
                  title: Text(c.name),
                  subtitle: Text('${c.volumeMl} ml'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditDialog(context, c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => cp.remove(c.id!),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showEditDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Add container'),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'coffee':
        return Icons.coffee;
      case 'water_drop':
        return Icons.water_drop;
      default:
        return Icons.local_drink;
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, WaterContainer? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final volumeCtrl =
        TextEditingController(text: existing?.volumeMl.toString() ?? '');
    String icon = existing?.icon ?? 'local_drink';
    final cp = context.read<ContainerProvider>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add container' : 'Edit container'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: volumeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Volume (ml)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: icon,
              decoration: const InputDecoration(labelText: 'Icon'),
              items: const [
                DropdownMenuItem(
                    value: 'local_drink', child: Text('Glass')),
                DropdownMenuItem(value: 'coffee', child: Text('Mug')),
                DropdownMenuItem(
                    value: 'water_drop', child: Text('Bottle')),
              ],
              onChanged: (v) {
                if (v != null) icon = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final vol = int.tryParse(volumeCtrl.text.trim());
              if (name.isEmpty || vol == null || vol <= 0) return;
              if (existing == null) {
                await cp.add(
                    WaterContainer(name: name, volumeMl: vol, icon: icon));
              } else {
                await cp.update(WaterContainer(
                    id: existing.id,
                    name: name,
                    volumeMl: vol,
                    icon: icon));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
