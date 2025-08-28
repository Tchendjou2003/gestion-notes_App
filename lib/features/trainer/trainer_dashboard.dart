// lib/features/trainer/trainer_dashboard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trow_app_frontend/core/models/cours.dart';
import 'package:trow_app_frontend/core/models/profile_model.dart';
import 'package:trow_app_frontend/features/trainer/promotions_list_screen.dart';
import 'package:trow_app_frontend/providers/trainer_provider.dart';

class TrainerDashboard extends StatefulWidget {
  final Profile profile;
  const TrainerDashboard({super.key, required this.profile});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TrainerProvider>(context, listen: false);
      // On charge les données de base (promos/spé) ET les cours du formateur
      provider.fetchInitialData();
      provider.fetchMyCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        centerTitle: false,
      ),
      body: Consumer<TrainerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingCourses) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ??
                          "Une erreur s'est produite.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchMyCourses(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchMyCourses(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue, ${widget.profile.fullName} !',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),

                        /// KPI Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              return Column(
                                children: [
                                  _buildKPICard(context, 'Total Cours', provider.myCourses.length.toString(), Icons.menu_book),
                                  const SizedBox(height: 16),
                                  _buildKPICard(context, 'Étudiants Inscrits', provider.totalStudents.toString(), Icons.school),
                                ],
                              );
                            } else {
                              return Row(
                                children: [
                                  Expanded(child: _buildKPICard(context, 'Total Cours', provider.myCourses.length.toString(), Icons.menu_book)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildKPICard(context, 'Étudiants Inscrits', provider.totalStudents.toString(), Icons.school)),
                                ],
                              );
                            }
                          },
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
                          child: Text(
                            'Mes Cours',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),

                        if (provider.myCourses.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_outlined, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Aucun cours ne vous est assigné.'),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: provider.myCourses.length,
                            itemBuilder: (context, index) {
                              final cours = provider.myCourses[index];
                              return _buildModernCourseCard(context, cours);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implémenter la navigation pour ajouter un nouveau cours
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un cours'),
      ),
    );
  }

  Widget _buildKPICard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Icon(icon, color: Theme.of(context).colorScheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModernCourseCard(BuildContext context, Cours cours) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PromotionsListScreen(cours: cours),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              child: Icon(Icons.school, size: 60, color: Theme.of(context).colorScheme.primary),
              // Vous pouvez remplacer ceci par une image:
              // child: Image.network('URL_DE_VOTRE_IMAGE', fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cours.nom,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.class_outlined, size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cours.specialityName ?? 'Spécialité non définie',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Gérer les notes', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}