// lib/models/note.dart

class Note {
  final int id;
  final String etudiantUsername;
  final String coursNom;
  final double valeur; // En Dart, on utilise double pour les DecimalFields de Django
  final DateTime datePublication;
  final String publieParUsername;
   final int coursId;
   final int promotionId;
   final int specialityId;
   final int etudiantId;

  Note({
    required this.id,
    required this.etudiantUsername,
    required this.coursNom,
    required this.valeur,
    required this.datePublication,
    required this.publieParUsername,
    required this.coursId,
    required this.promotionId,
    required this.specialityId,
    required this.etudiantId,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      etudiantUsername: json['etudiant_username'],
      coursNom: json['cours_nom'],
      // Convertir la valeur String en double
      valeur: double.parse(json['valeur']),
      // Convertir la date String en DateTime
      datePublication: DateTime.parse(json['date_publication']),
      publieParUsername: json['publie_par_username'],
       coursId: json['cours'],
       promotionId: json['promotion'],
       specialityId: json['specialite'],
       etudiantId: json['etudiant'],
    );
  }
}