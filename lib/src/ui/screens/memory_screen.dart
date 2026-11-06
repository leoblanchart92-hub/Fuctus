/// MemoryScreen — inspect, search, add and purge JARVIS's persistent memory.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/jarvis_controller.dart';
import '../../memory/memory_entry.dart';
import '../hud_theme.dart';
import '../widgets/hud_panel.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  String _query = '';
  List<MemoryEntry>? _results;

  Future<void> _refresh() async {
    setState(() {}); // entries are read fresh from the repository on each build
  }

  Future<List<MemoryEntry>> _entries() async {
    final controller = context.read<JarvisController>();
    if (_query.trim().isEmpty) {
      return controller.memory.all(limit: 100);
    }
    return controller.memory.search(_query.trim(), limit: 50);
  }

  Future<void> _addMemory() async {
    final field = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HudPalette.panelSolid,
        title: const Text('Ajouter un souvenir', style: TextStyle(color: HudPalette.cyan, fontSize: 16)),
        content: TextField(
          controller: field,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: HudPalette.textPrimary),
          decoration: const InputDecoration(hintText: 'Ex : j’aime le thé à la menthe…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler', style: TextStyle(color: HudPalette.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: HudPalette.cyan, foregroundColor: const Color(0xFF032530)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mémoriser'),
          ),
        ],
      ),
    );
    if (added == true && field.text.trim().isNotEmpty) {
      await context.read<JarvisController>().memory.remember(
            content: field.text.trim(),
            kind: 'fact',
            importance: 3,
          );
      if (mounted) setState(() {});
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HudPalette.panelSolid,
        title: const Text('Effacer toute la mémoire ?', style: TextStyle(color: HudPalette.red)),
        content: const Text(
          'Cette opération supprimera définitivement tous les faits, préférences et notes.',
          style: TextStyle(color: HudPalette.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Garder', style: TextStyle(color: HudPalette.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: HudPalette.red, foregroundColor: Colors.black),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<JarvisController>().memory.clear();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JarvisController>();
    return Scaffold(
      backgroundColor: HudPalette.background,
      appBar: AppBar(
        title: const Text('MÉMOIRE'),
        actions: [
          IconButton(
            tooltip: 'Ajouter',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addMemory,
          ),
          IconButton(
            tooltip: 'Tout effacer',
            icon: const Icon(Icons.delete_sweep_outlined, color: HudPalette.red),
            onPressed: () => _clearAll(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              style: const TextStyle(color: HudPalette.textPrimary),
              decoration: InputDecoration(
                hintText: 'Rechercher dans ma mémoire…',
                prefixIcon: const Icon(Icons.search, color: HudPalette.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: HudPalette.textSecondary),
                        onPressed: () => setState(() {
                          _query = '';
                          _results = null;
                        }),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {
                _query = value;
                _results = null;
              }),
            ),
          ),
          FutureBuilder<List<MemoryEntry>>(
            future: _entries(),
            builder: (context, snapshot) {
              final entries = _results = snapshot.data ?? _results;
              return Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            entries == null ? '—' : '${entries.length} SOUVENIR(S)',
                            style: const TextStyle(fontSize: 9, letterSpacing: 2.2, color: HudPalette.textSecondary),
                          ),
                          const Spacer(),
                          if (controller.busy)
                            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.4, color: HudPalette.cyan)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: entries == null
                          ? const Center(child: CircularProgressIndicator(color: HudPalette.cyan))
                          : entries.isEmpty
                              ? const _EmptyMemory()
                              : RefreshIndicator(
                                  color: HudPalette.cyan,
                                  backgroundColor: HudPalette.panelSolid,
                                  onRefresh: _refresh,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: entries.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) => _MemoryCard(
                                      entry: entries[index],
                                      onDelete: () async {
                                        final id = entries[index].id;
                                        if (id != null) {
                                          await controller.memory.delete(id);
                                          if (mounted) setState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyMemory extends StatelessWidget {
  const _EmptyMemory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.psychology_alt_outlined, size: 64, color: HudPalette.panelBorder),
          const SizedBox(height: 12),
          const Text('MÉMOIRE VIERGE', style: TextStyle(letterSpacing: 3, color: HudPalette.textSecondary)),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Dites « souviens-toi que j’aime le thé à la menthe » et JARVIS n’oubliera plus jamais.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: HudPalette.textFaint, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final MemoryEntry entry;
  final VoidCallback onDelete;
  const _MemoryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final (icon, kindLabel) = switch (entry.kind) {
      'note' => (Icons.sticky_note_2_outlined, 'NOTE'),
      'preference' => (Icons.favorite_border, 'PRÉFÉRENCE'),
      'identity' => (Icons.badge_outlined, 'IDENTITÉ'),
      _ => (Icons.memory_outlined, 'FAIT'),
    };
    final date = '${entry.createdAt.day.toString().padLeft(2, '0')}/${entry.createdAt.month.toString().padLeft(2, '0')}/${entry.createdAt.year}';
    return HudPanel(
      cornerRadius: 10,
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: HudPalette.cyanDim),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.content, style: const TextStyle(fontSize: 13, height: 1.4, color: HudPalette.textPrimary)),
                const SizedBox(height: 5),
                Text(
                  '$kindLabel · $date · importance ${entry.importance}/5',
                  style: const TextStyle(fontSize: 8.5, letterSpacing: 1.4, color: HudPalette.textFaint),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Oublier',
            icon: const Icon(Icons.close, size: 18, color: HudPalette.textSecondary),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
