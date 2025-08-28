
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trow_app_frontend/core/services/api_service.dart';
import 'package:trow_app_frontend/core/models/cours.dart';
import 'package:trow_app_frontend/core/models/note.dart';
import 'package:trow_app_frontend/providers/auth_provider.dart';

class StudentProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider;

  StudentProvider(this._apiService, this._authProvider);

  List<Cours> _courses = [];
  List<Note> _notes = [];
  bool _isLoadingCourses = false;
  bool _isLoadingNotes = false;
  String? _errorMessage;

  // ✅ Getters publics
  List<Cours> get courses => _courses;
  List<Note> get notes => _notes;
  bool get isLoadingCourses => _isLoadingCourses; // ✅ ajouté
  bool get isLoadingNotes => _isLoadingNotes;
  bool get isLoading => _isLoadingCourses || _isLoadingNotes;
  String? get errorMessage => _errorMessage;

  /// Exporte les notes en CSV. Si un cours est fourni, seules les notes de ce cours sont exportées.
  Future<String?> exportNotesAsCSV({Cours? course}) async {
    if (_authProvider.accessToken == null) {
      return "Utilisateur non authentifié.";
    }
    if (course == null) return "Veuillez sélectionner un cours à exporter.";

    try {
      final csvData = await _apiService.exportGradesCSV(
        _authProvider.accessToken!,
        course.id,
      );

      if (kIsWeb) {
        final blob = html.Blob([csvData]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "notes_${course.nom}.csv")
          ..click();
        html.Url.revokeObjectUrl(url);
        return null; // ✅ succès
      } else {
        return "L'export CSV n'est supporté que sur le web.";
      }
    } catch (e) {
      return "Erreur lors de l'export CSV: $e";
    }
  }

  // ✅ Récupérer uniquement les cours
  Future<void> fetchCourses() async {
    if (_authProvider.accessToken == null) return;
    _isLoadingCourses = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _courses = await _apiService.getCourses(_authProvider.accessToken!, 'etudiant');
    } catch (e) {
      _errorMessage = "Impossible de charger les cours";
      debugPrint("Erreur fetchCourses: $e");
    }

    _isLoadingCourses = false;
    notifyListeners();
  }

  // ✅ Récupérer uniquement les notes
  Future<void> fetchNotes() async {
    if (_authProvider.accessToken == null) return;
    _isLoadingNotes = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notes = await _apiService.getMyGrades(_authProvider.accessToken!);
    } catch (e) {
      _errorMessage = "Impossible de charger les notes";
      debugPrint("Erreur fetchNotes: $e");
    }

    _isLoadingNotes = false;
    notifyListeners();
  }

  // ✅ Récupérer cours + notes en parallèle
  Future<void> fetchAll() async {
    if (_authProvider.accessToken == null) return;
    _isLoadingCourses = true;
    _isLoadingNotes = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getCourses(_authProvider.accessToken!, 'etudiant'),
        _apiService.getMyGrades(_authProvider.accessToken!),
      ]);

      _courses = results[0] as List<Cours>;
      _notes = results[1] as List<Note>;
    } catch (e) {
      _errorMessage = "Erreur lors du chargement des données";
      debugPrint("Erreur fetchAll: $e");
    }

    _isLoadingCourses = false;
    _isLoadingNotes = false;
    notifyListeners();
  }
}
