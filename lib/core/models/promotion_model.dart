// lib/core/models/promotion_model.dart
class Promotion {
  final int id;
  final String name;
  final int year; // ✅ AJOUTER
  final String? speciality_name; 

  Promotion({
    required this.id,
    required this.name,
    required this.year, 
    this.speciality_name, 
  });

  factory Promotion.fromJson(Map<String, dynamic> j) {
    return Promotion(
      id: j['id'],
      name: j['name'],
      year: j['year'], // ✅ AJOUTER
      speciality_name: j['speciality_name'], 
    );
  }
}
