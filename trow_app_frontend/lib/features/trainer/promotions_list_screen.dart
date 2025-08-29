// lib/features/trainer/promotions_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trow_app_frontend/core/models/cours.dart';
import 'package:trow_app_frontend/features/trainer/specialities_list_screen.dart';
import 'package:trow_app_frontend/providers/trainer_provider.dart';

class PromotionsListScreen extends StatefulWidget {
  final Cours cours;
  const PromotionsListScreen({super.key, required this.cours});

  @override
  State<PromotionsListScreen> createState() => _PromotionsListScreenState();
}

class _PromotionsListScreenState extends State<PromotionsListScreen> {
  bool _hasFetchedNotes = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Charger les notes une seule fois
    if (!_hasFetchedNotes) {
      final provider = context.read<TrainerProvider>();
      provider.fetchNotesForCourse(widget.cours.id);
      _hasFetchedNotes = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cours.nom),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Consumer<TrainerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingNotes) {
            return const Center(child: CircularProgressIndicator());
          }

          final notesHierarchy = provider.notesHierarchyFor(widget.cours.id);
          final promoIds = notesHierarchy.keys.toList();

          if (promoIds.isEmpty) {
            return const Center(
              child: Text("Aucune promotion n'a de notes pour ce cours."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: promoIds.length,
            itemBuilder: (context, index) {
              final promoId = promoIds[index];
              final promoName = provider.getPromotionName(promoId);
              final specialities = notesHierarchy[promoId]!;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                                    leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: const Icon(Icons.school_outlined),
                  ),
                  title: Text(
                    promoName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Row(
                    children: [
                      Text("${specialities.length} spécialité(s)"),
                      const SizedBox(width: 8),
                      // Badge coloré pour indiquer le nombre de notes
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _countNotes(specialities).toString(),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpecialitiesListScreen(
                          cours: widget.cours,
                          promoId: promoId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Compte le nombre total de notes pour cette promo
  int _countNotes(Map<int, List<dynamic>> specialities) {
    int total = 0;
    for (var notes in specialities.values) {
      total += notes.length;
    }
    return total;
  }
}
