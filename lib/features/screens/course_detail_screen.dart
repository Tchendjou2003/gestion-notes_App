import 'dart:html' as html; // pour le téléchargement CSV (Flutter Web)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:trow_app_frontend/core/models/cours.dart';
import 'package:trow_app_frontend/core/models/note.dart';
import 'package:trow_app_frontend/core/services/api_service.dart';
import 'package:trow_app_frontend/providers/auth_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final Cours cours;

  const CourseDetailScreen({super.key, required this.cours});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isLoading = false;
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      _notes = await apiService.getGradesByCourse(
        authProvider.accessToken!,
        widget.cours.id,
      );
    } catch (e) {
      print("Erreur récupération notes : $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _exportCSV() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      final csvData = await apiService.exportGradesCSV(
        authProvider.accessToken!,
        widget.cours.id,
      );

      // ✅ Créer un blob et déclencher le téléchargement
      final blob = html.Blob([csvData]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "notes_${widget.cours.nom}.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print("Erreur export CSV : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l’export CSV")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cours.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Exporter en CSV",
            onPressed: _exportCSV,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text("Aucune note disponible pour ce cours."))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Text(
                            note.valeur.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          "Note en ${note.coursNom}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Publiée le : ${DateFormat('dd/MM/yyyy').format(note.datePublication)}",
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
