// lib/core/models/note_model.dart
class Note {
  final int id;
  final double valeur;
  final String datePublication; // ISO
  final int cours;
  final int etudiant;
  final int? publiePar;
  Note({
    required this.id,
    required this.valeur,
    required this.datePublication,
    required this.cours,
    required this.etudiant,
    this.publiePar,
  });
  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'],
        valeur: (j['valeur'] as num).toDouble(),
        datePublication: j['date_publication'],
        cours: j['cours'],
        etudiant: j['etudiant'],
        publiePar: j['publie_par'],
      );
}