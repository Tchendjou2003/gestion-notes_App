// lib/core/models/profile_model.dart



import 'package:trow_app_frontend/core/models/speciality_model.dart'; 



class Profile {
  final int id;
  /// 'admin' | 'formateur' | 'etudiant'
  final String role;
  /// Nom du rôle formaté pour l'affichage (ex: "Administrateur")
  final String role_display;

  final String username;
  final String? email;
  final String? first_name;
  final String? last_name;

  /// Nom de la promotion (si étudiant).
  final String? promotion_name;

  /// Nom de la spécialité (déduit de la promotion de l'étudiant).
  final String? speciality_name;

  /// Pour les formateurs : la liste des spécialités qui leur sont assignées.
  final List<Speciality> assigned_specialities;

  Profile({
    required this.id,
    required this.role,
    required this.role_display,
    required this.username,
    this.email,
    this.first_name,
    this.last_name,
    this.promotion_name,
    this.speciality_name,
    this.assigned_specialities = const [], // Valeur par défaut
  });

  factory Profile.fromJson(Map<String, dynamic> j) {
    final extractedUsername = j['username'] as String? ?? '';

    final specialitiesData = j['assigned_specialities'] as List<dynamic>? ?? [];
    final specialities = specialitiesData
        .map((item) => Speciality.fromJson(item as Map<String, dynamic>))
        .toList();

    return Profile(
      id: j['id'] as int,
      role: j['role'] as String,
      role_display: j['role_display'] as String,
      username: extractedUsername,
      email: j['email'] as String?,
      first_name: j['first_name'] as String?,
      last_name: j['last_name'] as String?,
      promotion_name: j['promotion_name'] as String?,
      speciality_name: j['speciality_name'] as String?,
      assigned_specialities: specialities,
    );
  }

  /// Helper d’affichage
  String get fullName =>
      [first_name, last_name].where((s) => (s ?? '').trim().isNotEmpty).join(' ').trim();

  Profile copyWith({
    int? id,
    String? role,
    String? role_display,
    String? username,
    String? email,
    String? first_name,
    String? last_name,
    String? promotion_name,
    String? speciality_name,
    List<Speciality>? assigned_specialities,
  }) {
    return Profile(
      id: id ?? this.id,
      role: role ?? this.role,
      role_display: role_display ?? this.role_display,
      username: username ?? this.username,
      email: email ?? this.email,
      first_name: first_name ?? this.first_name,
      last_name: last_name ?? this.last_name,
      promotion_name: promotion_name ?? this.promotion_name,
      speciality_name: speciality_name ?? this.speciality_name,
      assigned_specialities: assigned_specialities ?? this.assigned_specialities,
    );
  }
}