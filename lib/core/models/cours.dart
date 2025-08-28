// lib/models/cours.dart
class Cours {
    final int id;
    final String nom;
    final String? description;
    final String? formateurUsername;
    final String? specialityName;
    final String? promotionName;

    Cours({
        required this.id,
        required this.nom,
        this.description,
        this.formateurUsername,
        this.specialityName,
        this.promotionName,
    });

    factory Cours.fromJson(Map<String, dynamic> json) {
        return Cours(
            id: json['id'],
            nom: json['nom'],
            description: json['description'],
            formateurUsername: json['formateur_username'],
            specialityName: json['speciality_name'],
            promotionName: json['promotion_name'],
        );
    }
}