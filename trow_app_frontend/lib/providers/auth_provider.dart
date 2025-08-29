// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trow_app_frontend/core/services/api_service.dart';
import 'package:trow_app_frontend/core/models/profile_model.dart';

class AuthProvider with ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  bool _isAuthenticated = false;

  Profile? _userProfile;

  // === Nouveaux ajouts ===
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Profile? get userProfile => _userProfile;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final ApiService _apiService = ApiService();

  // =====================
  // CONSTRUCTEUR : restauration auto
  // =====================
  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAccess = prefs.getString('accessToken');
    final savedRefresh = prefs.getString('refreshToken');

    if (savedAccess != null && savedRefresh != null) {
      _accessToken = savedAccess;
      _refreshToken = savedRefresh;
      try {
        _userProfile = await _apiService.getMyProfile(_accessToken!);
        _isAuthenticated = true;
      } catch (e) {
        _isAuthenticated = false;
        _errorMessage = "Session expirée, veuillez vous reconnecter.";
      }
      notifyListeners();
    }
  }

  // =====================
  // LOGIN
  // =====================
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);
      _accessToken = response['access'];
      _refreshToken = response['refresh'];

      // Sauvegarder les jetons
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _accessToken!);
      await prefs.setString('refreshToken', _refreshToken!);

      // ✅ Récupérer le profil utilisateur
      _userProfile = await _apiService.getMyProfile(_accessToken!);

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Échec de la connexion. Vérifiez vos identifiants.";
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // =====================
  // LOGOUT
  // =====================
  void logout() async {
    _accessToken = null;
    _refreshToken = null;
    _isAuthenticated = false;
    _userProfile = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  // =====================
  // MàJ du profil
  // =====================
  void updateUserProfile(Profile newProfile) {
    _userProfile = newProfile;
    notifyListeners();
  }
    // ✅ NOUVELLE MÉTHODE pour mettre à jour le profil via l'API
  Future<bool> updateMyProfile({required String username, required String email}) async {
    if (_accessToken == null || _userProfile == null) return false;

    // Structure du payload attendu par le ProfileSerializer
    final Map<String, dynamic> payload = {
      'user': {
        'username': username,
        'email': email,
        'first_name': _userProfile!.first_name, // Conserver les valeurs existantes
        'last_name': _userProfile!.last_name,
      },
      // Envoyer le rôle et d'autres champs de profil si nécessaire
      'role': _userProfile!.role,
    };

    try {
      final updatedProfile = await _apiService.updateUserProfile(
        _accessToken!,
        _userProfile!.id,
        payload,
      );
      _userProfile = updatedProfile; // Mettre à jour l'état local avec la réponse du serveur
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Erreur de mise à jour du profil: $e");
      return false;
    }
  }
}
