// lib/models/user_profile.dart
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }
}

class Profile {
  final int id;
  final User user;
  final String role;
  final String roleDisplay;
  final String? specialityName;
  final String? promotionName;

  Profile({
    required this.id,
    required this.user,
    required this.role,
    required this.roleDisplay,
    this.specialityName,
    this.promotionName,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      user: User.fromJson(json['user']),
      role: json['role'],
      roleDisplay: json['role_display'],
      specialityName: json['speciality_name'],
      promotionName: json['promotion_name'],
    );
  }
}