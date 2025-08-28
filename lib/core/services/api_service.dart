// lib/api/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trow_app_frontend/core/models/promotion_model.dart';
import 'package:trow_app_frontend/core/models/speciality_model.dart';
import 'package:trow_app_frontend/utils/constant.dart';
import 'package:trow_app_frontend/core/models/profile_model.dart';
import 'package:trow_app_frontend/core/models/cours.dart';
import 'package:trow_app_frontend/core/models/note.dart';

class ApiService {
  // =====================
  // LOGIN
  // =====================
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login. Status code: ${response.statusCode}');
    }
  }

  // =====================
  // GET MY PROFILE
  // =====================
  Future<Profile> getMyProfile(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profiles/me/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load profile. Status code: ${response.statusCode}');
    }
  }

  // =====================
  // GET COURSES
  // =====================
  Future<List<Cours>> getCourses(String accessToken, String role) async {
    // role ∈ { "etudiant", "formateur", "admin" }
    final uri = Uri.parse('$baseUrl/courses/');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Cours.fromJson(item)).toList();
    } else {
      throw Exception(
        'Failed to load courses (role: $role). '
        'Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  // =====================
  // GRADES
  // =====================
  Future<List<Note>> getMyGrades(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grades/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Note.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load grades. Status code: ${response.statusCode}');
    }
  }

  // Récupérer les notes d’un cours spécifique
  Future<List<Note>> getGradesByCourse(String accessToken, int courseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grades/?cours=$courseId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Note.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load grades for course $courseId');
    }
  }

  // Exporter les notes en CSV
  Future<String> exportGradesCSV(String accessToken, int courseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grades/export_csv/?cours=$courseId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    } else {
      throw Exception('Failed to export grades as CSV');
    }
  }

  // --- Récupérer les notes d’un cours précis ---
  Future<List<Note>> getNotesByCourse(String accessToken, int courseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grades/?cours=$courseId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((item) => Note.fromJson(item)).toList();
    } else {
      throw Exception(
          'Échec lors de la récupération des notes pour le cours $courseId');
    }
  }

  /// ADMIN: Récupère TOUS les profils
  Future<List<Profile>> getAllProfiles(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profiles/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Profile.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load all profiles');
    }
  }

  /// TRAINER: Récupère les notes pour un cours spécifique
  Future<List<Note>> getNotesForCourse(String accessToken, int courseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grades/?cours=$courseId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Note.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load notes for course $courseId');
    }
  }

  /// TRAINER: Ajoute une nouvelle note
  Future<Note> createNote(
    String accessToken, {
    required int etudiantId,
    required int coursId,
    required double valeur,
    required int promotionId,
    required int specialiteId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/grades/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'etudiant': etudiantId,
        'cours': coursId,
        'valeur': valeur.toString(),
        'promotion': promotionId,
        'specialite': specialiteId,
      }),
    );
    if (response.statusCode == 201) {
      return Note.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to create note. Body: ${response.body}');
    }
  }

  // Met à jour une note existante
  Future<Note> updateNote(
    String accessToken, {
    required int noteId,
    required int etudiantId,
    required int coursId,
    required double valeur,
    required int promotionId,
    required int specialiteId,
  }) async {
    final Map<String, dynamic> body = {
      'etudiant': etudiantId,
      'cours': coursId,
      'valeur': valeur,
      'promotion': promotionId,
      'specialite': specialiteId,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/grades/$noteId/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return Note.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to update note $noteId. Body: ${response.body}');
    }
  }

  // Supprime une note
  Future<void> deleteNote(String accessToken, int noteId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/grades/$noteId/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete note $noteId. Status: ${response.statusCode}');
    }
  }

  // Récupérer la liste des promotions
  Future<List<Promotion>> getPromotions(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/promotions/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Promotion.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load promotions. Status code: ${response.statusCode}');
    }
  }

  // Récupérer la liste des spécialités
  Future<List<Speciality>> getSpecialities(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/specialities/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Speciality.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load specialities. Status code: ${response.statusCode}');
    }
  }

  // Mettre à jour un profil utilisateur ADMIN
  Future<Profile> updateProfile(
      String accessToken, int profileId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profiles/$profileId/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to update profile. Body: ${response.body}');
    }
  }

  // Supprimer un profil utilisateur
  Future<void> deleteProfile(String accessToken, int profileId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/profiles/$profileId/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete profile. Status code: ${response.statusCode}');
    }
  }

  // Créer un nouveau profil utilisateur
  Future<Profile> createProfile(
      String accessToken, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profiles/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return Profile.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to create profile. Body: ${response.body}');
    }
  }

  // Créer un cours
  Future<Cours> createCourse(String accessToken, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/courses/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return Cours.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la création du cours: ${response.body}');
    }
  }

  // Mettre à jour un cours
  Future<Cours> updateCourse(String accessToken, int courseId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/courses/$courseId/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Cours.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la mise à jour du cours: ${response.body}');
    }
  }

  // Supprimer un cours
  Future<void> deleteCourse(String accessToken, int courseId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/courses/$courseId/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression du cours: ${response.body}');
    }
  }

  Future<Profile> updateUserProfile(String token, int userId, Map<String, dynamic> profileData) async {
    final url = Uri.parse('$baseUrl/profiles/$userId/');
    
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return Profile.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Erreur d\'authentification. Le token est invalide.');
    } else if (response.statusCode == 404) {
      throw Exception('Profil non trouvé.');
    } else if (response.statusCode == 400) {
      final errorData = json.decode(utf8.decode(response.bodyBytes));
      throw Exception('Erreur de validation : $errorData');
    } else {
      throw Exception('Échec de la mise à jour du profil. Statut : ${response.statusCode}');
    }
  }
}
