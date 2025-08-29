// lib/features/trainer/specialities_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trow_app_frontend/core/models/cours.dart';
import 'package:trow_app_frontend/core/models/profile_model.dart'; // <-- AJOUT
import 'package:trow_app_frontend/features/trainer/student_notes_list_screen.dart';
import 'package:trow_app_frontend/providers/trainer_provider.dart';

class SpecialitiesListScreen extends StatefulWidget {
  final Cours cours;
  final int promoId;

  const SpecialitiesListScreen({
    super.key,
    required this.cours,
    required this.promoId,
  });

    State<SpecialitiesListScreen> createState() => _SpecialitiesListScreenState();
}

class _SpecialitiesListScreenState extends State<SpecialitiesListScreen> {
  // Note: La logique de chargement est maintenant gérée par le Consumer
  // pour éviter les builds inutiles.

  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<TrainerProvider>(
          builder: (context, provider, child) {
            return Text(provider.getPromotionName(widget.promoId));
          },
        ),
      ),
      body: Consumer<TrainerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingNotes) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.hasError) {
            return Center(child: Text(provider.errorMessage!));
          }

          final specialitiesMap =
              provider.notesHierarchyFor(widget.cours.id)[widget.promoId] ?? {};
          final specIds = specialitiesMap.keys.toList();

          if (specIds.isEmpty) {
            return const Center(
              child: Text("Aucune spécialité pour cette promotion."),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotesForCourse(widget.cours.id),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: specIds.length,
              itemBuilder: (context, index) {
                final specId = specIds[index];
                final specName = provider.getSpecialityName(specId);
                final notes = specialitiesMap[specId] ?? [];

                // <-- AJOUT : Récupérer les étudiants pour cette spécialité
                final List<Profile> studentsInSpec =
                    provider.getStudentsForSpeciality(widget.promoId, specId);

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      child: const Icon(Icons.science_outlined),
                    ),
                    title: Text(
                      specName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text("${studentsInSpec.length} étudiant(s)"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // <-- MODIFICATION : Passer la liste des étudiants
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentNotesListScreen(
                            cours: widget.cours,
                            promoId: widget.promoId,
                            specialityId: specId,
                            students: studentsInSpec, // <-- AJOUT
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}