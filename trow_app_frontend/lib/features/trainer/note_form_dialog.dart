import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trow_app_frontend/core/models/note.dart';
import 'package:trow_app_frontend/core/models/profile_model.dart';

class NoteFormDialog extends StatefulWidget {
  final Note? note;
  final List<Profile> students;
  final Function(int etudiantId, double valeur) onSubmit;

  const NoteFormDialog({
    super.key,
    this.note,
    required this.students,
    required this.onSubmit,
  });

    State<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends State<NoteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _valeurController;
  int? _selectedEtudiantId;

  bool get _isEditing => widget.note != null;

  
  void initState() {
    super.initState();
    _selectedEtudiantId = widget.note?.etudiantId;
    _valeurController = TextEditingController(
      text: widget.note?.valeur.toStringAsFixed(2) ?? '',
    );
  }

  
  void dispose() {
    _valeurController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // French locale uses comma, so we replace it with a dot for parsing
      final valeur = double.tryParse(_valeurController.text.replaceAll(',', '.'));

      // Ensure student is selected. For editing, it's always selected.
      if (valeur != null && _selectedEtudiantId != null) {
        widget.onSubmit(_selectedEtudiantId!, valeur);
        Navigator.of(context).pop(); // Close dialog on success
      }
    }
  }

  
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Modifier la note' : 'Ajouter une note'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isEditing)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person),
                  title: Text(widget.note!.etudiantUsername),
                  subtitle: const Text("Étudiant"),
                ),
              if (!_isEditing)
                DropdownButtonFormField<int>(
                  value: _selectedEtudiantId,
                  hint: const Text('Sélectionner un étudiant'),
                  isExpanded: true,
                  items: widget.students.map<DropdownMenuItem<int>>((student) {
                    return DropdownMenuItem(
                      value: student.id,
                      child: Text(student.username),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEtudiantId = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Veuillez sélectionner un étudiant' : null,
                  decoration: const InputDecoration(
                    labelText: 'Étudiant',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valeurController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                ],
                decoration: const InputDecoration(
                  labelText: 'Note / 20',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une note';
                  }
                  final n = double.tryParse(value.replaceAll(',', '.'));
                  if (n == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  if (n < 0 || n > 20) {
                    return 'La note doit être entre 0 et 20';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}