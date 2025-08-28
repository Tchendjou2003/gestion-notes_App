// lib/providers/admin_provider.dart
import 'package:flutter/foundation.dart';
import 'package:trow_app_frontend/core/services/api_service.dart';
import 'package:trow_app_frontend/providers/auth_provider.dart';
import 'package:trow_app_frontend/core/models/profile_model.dart';
import 'package:trow_app_frontend/core/models/cours.dart';
import 'package:trow_app_frontend/core/models/promotion_model.dart';
import 'package:trow_app_frontend/core/models/speciality_model.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _auth;

  // Data
  List<Profile> _profiles = [];
  List<Cours> _courses = [];
  List<Promotion> _promotions = [];
  List<Speciality> _specialities = [];

  // State
  bool _isLoading = false;
  String? _errorMessage;

  List<Profile> get profiles => _profiles;
  List<Cours> get courses => _courses;
  List<Promotion> get promotions => _promotions;
  List<Speciality> get specialities => _specialities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AdminProvider({required ApiService apiService, required AuthProvider auth})
      : _apiService = apiService,
        _auth = auth;

  String get _token {
    final t = _auth.accessToken;
    if (t == null || t.isEmpty) {
      throw StateError("Aucun token disponible, utilisateur non connecté");
    }
    return t;
  }

  /// Charger toutes les données de base
  Future<void> fetchInitialData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _apiService.getAllProfiles(_token),
        _apiService.getCourses(_token, 'admin'),
        _apiService.getPromotions(_token),
        _apiService.getSpecialities(_token),
      ]);
      _profiles = results[0] as List<Profile>;
      _courses = results[1] as List<Cours>;
      _promotions = results[2] as List<Promotion>;
      _specialities = results[3] as List<Speciality>;
    } catch (e) {
      _errorMessage = "Erreur lors du chargement des données Admin";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprimer un utilisateur
  Future<void> deleteProfile(int profileId) async {
    try {
      await _apiService.deleteProfile(_token, profileId);
      _profiles.removeWhere((p) => p.id == profileId);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Erreur lors de la suppression du profil";
      notifyListeners();
    }
  }

  /// Créer un utilisateur
  Future<void> createProfile(Map<String, dynamic> data) async {
    try {
      final profile = await _apiService.createProfile(_token, data);
      _profiles.add(profile);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Erreur lors de la création du profil";
      notifyListeners();
    }
  }

  /// Mettre à jour un utilisateur
  Future<void> updateProfile(int profileId, Map<String, dynamic> data) async {
    try {
      final updated = await _apiService.updateProfile(_token, profileId, data);
      final index = _profiles.indexWhere((p) => p.id == profileId);
      if (index != -1) {
        _profiles[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = "Erreur lors de la mise à jour du profil";
      notifyListeners();
    }
  }
}
