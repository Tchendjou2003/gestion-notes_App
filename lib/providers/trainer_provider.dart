// lib/providers/trainer_provider.dart
import 'package:flutter/foundation.dart';
import 'package:trow_app_frontend/core/models/cours.dart';
import 'package:trow_app_frontend/core/models/note.dart';
import 'package:trow_app_frontend/core/models/profile_model.dart';
import 'package:trow_app_frontend/core/models/promotion_model.dart';
import 'package:trow_app_frontend/core/models/speciality_model.dart';
import 'package:trow_app_frontend/core/services/api_service.dart';
import 'package:trow_app_frontend/providers/auth_provider.dart';

class TrainerProvider with ChangeNotifier {
  static const int unassignedId = -1;

  final ApiService _apiService;
  final AuthProvider _auth;

  // Data
  List<Cours> _myCourses = [];
  List<Promotion> _promotions = [];
  List<Speciality> _specialities = [];
  List<Profile> _allProfiles = [];

  final Map<int, Map<int, Map<int, List<Note>>>> _notesHierarchy = {};

  // State
  bool _isLoadingCourses = false;
  bool _isLoadingNotes = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Getters
  List<Cours> get myCourses => _myCourses;
  bool get isLoadingCourses => _isLoadingCourses;
  bool get isLoadingNotes => _isLoadingNotes;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  List<Promotion> get promotions => _promotions;
  List<Speciality> get specialities => _specialities;

  int get totalStudents =>
      _allProfiles.where((p) => p.role == 'etudiant').length;

  TrainerProvider({required ApiService apiService, required AuthProvider auth})
      : _apiService = apiService,
        _auth = auth;

  String get _token {
    final t = _auth.accessToken;
    if (t == null || t.isEmpty) {
      throw StateError('No access token available. User must be logged in.');
    }
    return t;
  }

  Future<void> fetchInitialData() async {
    debugPrint("Fetching initial data...");
    try {
      final results = await Future.wait([
        _apiService.getPromotions(_token),
        _apiService.getSpecialities(_token),
        _apiService.getAllProfiles(_token),
      ]);
      _promotions = results[0] as List<Promotion>;
      _specialities = results[1] as List<Speciality>;
      _allProfiles = results[2] as List<Profile>;
      debugPrint("Fetched ${_promotions.length} promotions, ${_specialities.length} specialities, and ${_allProfiles.length} profiles.");
    } catch (e) {
      _errorMessage = "Erreur lors du chargement des données de base.";
      debugPrint("Erreur fetchInitialData: $e");
    }
    notifyListeners();
  }

  String getPromotionName(int promoId) {
    try {
      final name = _promotions.firstWhere((p) => p.id == promoId).name;
      debugPrint("Found promotion name for ID $promoId: $name");
      return name;
    } catch (e) {
      debugPrint("Could not find promotion name for ID $promoId. Error: $e");
      return "Promotion ID: $promoId";
    }
  }

  String getSpecialityName(int specId) {
    try {
      final name = _specialities.firstWhere((s) => s.id == specId).name;
      debugPrint("Found speciality name for ID $specId: $name");
      return name;
    } catch (e) {
      debugPrint("Could not find speciality name for ID $specId. Error: $e");
      return "Spécialité ID: $specId";
    }
  }

  List<Profile> getStudentsForSpeciality(int promoId, int specId) {
    final promoName = getPromotionName(promoId);
    final specName = getSpecialityName(specId);
    debugPrint("Filtering students for promo: $promoName (ID: $promoId) and spec: $specName (ID: $specId)");
    final filteredStudents = _allProfiles
        .where((p) =>
            p.role == 'etudiant' &&
            p.promotion_name == promoName &&
            p.speciality_name == specName)
        .toList();
    debugPrint("Found ${filteredStudents.length} students for this filter.");
    return filteredStudents;
  }

  Future<void> fetchMyCourses() async {
    _isLoadingCourses = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _myCourses = await _apiService.getCourses(_token, 'formateur');
    } catch (e) {
      _errorMessage = "Erreur lors du chargement des cours.";
      debugPrint("Erreur fetchMyCourses: $e");
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }

  Future<void> fetchNotesForCourse(int courseId) async {
    _isLoadingNotes = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final notes = await _apiService.getNotesForCourse(_token, courseId);
      final grouped = <int, Map<int, List<Note>>>{};
      for (final note in notes) {
        final promoId = note.promotionId;
        final specId = note.specialityId;
        grouped.putIfAbsent(promoId, () => {});
        grouped[promoId]!.putIfAbsent(specId, () => []);
        grouped[promoId]![specId]!.add(note);
      }
      _notesHierarchy[courseId] = grouped;
    } catch (e) {
      _errorMessage = "Erreur lors du chargement des notes.";
      debugPrint("Erreur fetchNotesForCourse: $e");
    } finally {
      _isLoadingNotes = false;
      notifyListeners();
    }
  }

  Map<int, Map<int, List<Note>>> notesHierarchyFor(int courseId) {
    return _notesHierarchy[courseId] ?? {};
  }

  Future<void> createNote({
    required int etudiantId,
    required int coursId,
    required double valeur,
    required int promoId,
    required int specialityId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newNote = await _apiService.createNote(
        _token,
        etudiantId: etudiantId,
        coursId: coursId,
        valeur: valeur,
        promotionId: promoId,
        specialiteId: specialityId,
      );
      _notesHierarchy[coursId]?[promoId]?[specialityId]?.add(newNote);
    } catch (e) {
      _errorMessage = "Erreur lors de la création de la note.";
      debugPrint("Erreur createNote: $e");
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> updateNote({
    required int noteId,
    required int etudiantId,
    required int coursId,
    required double valeur,
    required int promoId,
    required int specialityId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedNote = await _apiService.updateNote(
        _token,
        noteId: noteId,
        etudiantId: etudiantId,
        coursId: coursId,
        valeur: valeur,
        promotionId: promoId,
        specialiteId: specialityId,
      );
      final list = _notesHierarchy[coursId]?[promoId]?[specialityId];
      if (list != null) {
        final idx = list.indexWhere((n) => n.id == noteId);
        if (idx != -1) list[idx] = updatedNote;
      }
    } catch (e) {
      _errorMessage = "Erreur lors de la mise à jour de la note.";
      debugPrint("Erreur updateNote: $e");
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteNote({
    required int noteId,
    required int coursId,
    required int promoId,
    required int specialityId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.deleteNote(_token, noteId);
      _notesHierarchy[coursId]?[promoId]?[specialityId]
          ?.removeWhere((n) => n.id == noteId);
    } catch (e) {
      _errorMessage = "Erreur lors de la suppression de la note.";
      debugPrint("Erreur deleteNote: $e");
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
