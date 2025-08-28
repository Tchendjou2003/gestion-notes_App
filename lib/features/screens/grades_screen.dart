// lib/screens/student/grades_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:trow_app_frontend/providers/student_provider.dart';
import 'package:trow_app_frontend/core/models/cours.dart';
import 'package:trow_app_frontend/core/models/note.dart';

class StudentGradesScreen extends StatefulWidget {
  const StudentGradesScreen({super.key});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  Cours? _selectedCourse; // ✅ cours sélectionné pour filtrage

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StudentProvider>(context, listen: false);
      provider.fetchCourses(); // ✅ pour remplir le dropdown
      provider.fetchNotes();   // ✅ toutes les notes par défaut
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              final provider = Provider.of<StudentProvider>(context, listen: false);
              provider.exportNotesAsCSV();
            },
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingNotes) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notes.isEmpty) {
            return const Center(child: Text('Aucune note trouvée.'));
          }

          // ✅ Liste filtrée selon le cours choisi
          List<Note> filteredNotes = _selectedCourse == null
              ? provider.notes
              : provider.notes.where((n) => n.coursId == _selectedCourse!.id).toList();

          return Column(
            children: [
              // ✅ Dropdown pour choisir un cours
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<Cours>(
                  isExpanded: true,
                  hint: const Text("Filtrer par cours"),
                  value: _selectedCourse,
                  items: provider.courses.map((cours) {
                    return DropdownMenuItem<Cours>(
                      value: cours,
                      child: Text(cours.nom),
                    );
                  }).toList(),
                  onChanged: (cours) {
                    setState(() {
                      _selectedCourse = cours;
                    });
                  },
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            note.valeur.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          note.coursNom,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Publiée le: ${DateFormat('dd/MM/yyyy').format(note.datePublication)}',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
