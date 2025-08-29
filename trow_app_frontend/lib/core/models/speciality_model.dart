// lib/core/models/speciality_model.dart
class Speciality {
  final int id;
  final String name;
  Speciality({required this.id, required this.name});
  factory Speciality.fromJson(Map<String, dynamic> j) => Speciality(id: j['id'], name: j['name']);
}