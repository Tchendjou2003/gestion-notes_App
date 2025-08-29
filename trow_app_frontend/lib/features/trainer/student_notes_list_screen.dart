
// lib/features/trainer/student_notes_list_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:trow_app_frontend/core/models/cours.dart';
import 'package:trow_app_frontend/core/models/note.dart';
import 'package:trow_app_frontend/core/models/profile_model.dart';
import 'package:trow_app_frontend/features/trainer/note_form_dialog.dart';
import 'package:trow_app_frontend/providers/trainer_provider.dart';

class StudentNotesListScreen extends StatefulWidget {
  final Cours cours;
  final int promoId;
  final int specialityId;
  final List<Profile> students; // <-- AJOUT

  const StudentNotesListScreen({
    super.key,
    required this.cours,
    required this.promoId,
    required this.specialityId,
    required this.students, // <-- AJOUT
  });

    State<StudentNotesListScreen> createState() => _StudentNotesListScreenState();
}

class _StudentNotesListScreenState extends State<StudentNotesListScreen> {
  List<Note> _localNotes = [];
  String _searchQuery = "";
  String _sortOption = "Nom A→Z";

  
  void initState() {
    super.initState();
    // Utiliser didChangeDependencies pour une meilleure pratique avec Provider
  }

  
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Met à jour la liste locale des notes lorsque le widget est construit ou mis à jour
    final provider = context.watch<TrainerProvider>();
    _localNotes = provider.notesHierarchyFor(widget.cours.id)[widget.promoId]?[widget.specialityId] ?? [];
  }

  List<Note> get _filteredAndSortedNotes {
    List<Note> filtered = _localNotes.where((note) {
      return note.etudiantUsername.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    switch (_sortOption) {
      case "Nom Z→A":
        filtered.sort((a, b) => b.etudiantUsername.compareTo(a.etudiantUsername));
        break;
      case "Note ↑":
        filtered.sort((a, b) => a.valeur.compareTo(b.valeur));
        break;
      case "Note ↓":
        filtered.sort((a, b) => b.valeur.compareTo(a.valeur));
        break;
      default: // Nom A→Z
        filtered.sort((a, b) => a.etudiantUsername.compareTo(b.etudiantUsername));
    }
    return filtered;
  }

  Future<void> _refreshNotes() async {
    await context.read<TrainerProvider>().fetchNotesForCourse(widget.cours.id);
  }

  void _showNoteDialog({Note? note}) {
    debugPrint("Attempting to show note dialog. Note for editing: ${note?.id}");
    // On filtre pour ne garder que les étudiants qui n'ont pas encore de note
    final studentIdsWithNotes = _localNotes.map((n) => n.etudiantId).toSet();
    final availableStudents = widget.students
        .where((student) => !studentIdsWithNotes.contains(student.id))
        .toList();

    debugPrint("Total students in group: ${widget.students.length}");
    debugPrint("Students with existing notes: ${studentIdsWithNotes.length}");
    debugPrint("Available students for new note: ${availableStudents.length}");

    if (note == null && availableStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tous les étudiants de ce groupe ont déjà une note.")),
      );
      debugPrint("SnackBar shown: All students have notes.");
      return;
    }

    showDialog(
      context: context,
      builder: (_) => NoteFormDialog(
        note: note,
        students: note != null ? [] : availableStudents,
        onSubmit: (etudiantId, valeur) async {
          final provider = context.read<TrainerProvider>();
          if (provider.isSubmitting) return; // Prevent double submission

          try {
            if (note != null) {
              await provider.updateNote(
                noteId: note.id,
                etudiantId: etudiantId,
                coursId: widget.cours.id,
                valeur: valeur,
                promoId: widget.promoId,
                specialityId: widget.specialityId,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Note mise à jour avec succès !")));
            } else {
              await provider.createNote(
                etudiantId: etudiantId,
                coursId: widget.cours.id,
                valeur: valeur,
                promoId: widget.promoId,
                specialityId: widget.specialityId,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Note ajoutée avec succès !")));
            }
            await _refreshNotes();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Erreur: ${provider.errorMessage ?? e.toString()}")));
          }
        },
      ),
    );
  }

  Future<void> _deleteNoteWithConfirm(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text("Supprimer la note de ${note.etudiantUsername} ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<TrainerProvider>();
      await provider.deleteNote(
        noteId: note.id,
        coursId: widget.cours.id,
        promoId: widget.promoId,
        specialityId: widget.specialityId,
      );
       await _refreshNotes();
    }
  }
  
  // ... les fonctions _showExportMenu, _exportCsv, _exportPdf restent identiques ...
  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text("Exporter en CSV"),
              onTap: () {
                Navigator.pop(context);
                _exportCsv();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text("Exporter en PDF"),
              onTap: () {
                Navigator.pop(context);
                _exportPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final notesToExport = _filteredAndSortedNotes;
    if (notesToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune note à exporter")));
      return;
    }
    final csvBuffer = StringBuffer();
    csvBuffer.writeln("etudiant_id;etudiant_username;note");
    for (var note in notesToExport) {
      csvBuffer.writeln("${note.etudiantId};${note.etudiantUsername};${note.valeur}");
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/notes_${widget.cours.nom}.csv';
    final file = File(path);
    await file.writeAsString(csvBuffer.toString());
    await Share.shareXFiles([XFile(path)], text: 'Notes exportées');
  }

  Future<void> _exportPdf() async {
    final notesToExport = _filteredAndSortedNotes;
    if (notesToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune note à exporter")));
      return;
    }
    final provider = context.read<TrainerProvider>();
    final pdf = pw.Document();
    final promoName = provider.getPromotionName(widget.promoId);
    final specName = provider.getSpecialityName(widget.specialityId);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text('Liste des Notes - ${widget.cours.nom}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.Text('Promotion: $promoName', style: const pw.TextStyle(fontSize: 18)),
        pw.Text('Spécialité: $specName', style: const pw.TextStyle(fontSize: 18)),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['ID Étudiant', 'Nom', 'Note /20'],
          data: notesToExport.map((n) => [n.etudiantId.toString(), n.etudiantUsername, n.valeur.toStringAsFixed(2)]).toList(),
        ),
      ],
    ));

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'notes_${widget.cours.nom}_$specName.pdf');
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: note.valeur >= 10 ? Colors.green[300] : Colors.red[300],
          child: Text(note.etudiantUsername.isNotEmpty ? note.etudiantUsername[0].toUpperCase() : '?'),
        ),
        title: Text(note.etudiantUsername),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Note: ${note.valeur.toStringAsFixed(2)} / 20"),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: note.valeur / 20,
              color: note.valeur >= 10 ? Colors.green : Colors.red,
              backgroundColor: Colors.grey[300],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
              onPressed: () => _showNoteDialog(note: note),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteNoteWithConfirm(note),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget build(BuildContext context) {
    final displayedNotes = _filteredAndSortedNotes;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cours.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: "Exporter les notes",
            onPressed: _localNotes.isEmpty ? null : _showExportMenu,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sortOption = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: "Nom A→Z", child: Text("Nom A→Z")),
              const PopupMenuItem(value: "Nom Z→A", child: Text("Nom Z→A")),
              const PopupMenuItem(value: "Note ↑", child: Text("Note ↑")),
              const PopupMenuItem(value: "Note ↓", child: Text("Note ↓")),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rechercher un étudiant...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotes,
        child: displayedNotes.isEmpty
            ? Center(child: Text(_searchQuery.isEmpty ? "Aucun étudiant à noter." : "Aucun étudiant correspondant."))
            : ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: displayedNotes.length,
                itemBuilder: (context, index) {
                  final note = displayedNotes[index];
                  return _buildNoteCard(note);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Ajouter une note',
      ),
    );
  }
}