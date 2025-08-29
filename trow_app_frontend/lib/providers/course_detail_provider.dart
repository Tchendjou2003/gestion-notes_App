import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trow_app_frontend/core/services/api_service.dart';
import 'package:trow_app_frontend/core/models/note.dart';

class CourseDetailProvider with ChangeNotifier {
  final ApiService apiService;
  final String accessToken;
  CourseDetailProvider({required this.apiService, required this.accessToken});

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charger les notes d’un cours précis
  Future<void> fetchNotesByCourse(int courseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notes = await apiService.getGradesByCourse(accessToken, courseId);
    } catch (e) {
      _errorMessage = "Impossible de charger les notes pour ce cours.";
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Exporter les notes en CSV et déclencher le téléchargement sur le web.
  /// Retourne un message d'erreur en cas d'échec, sinon null.
  Future<String?> exportNotesAsCSV(int courseId, String courseName) async {
    try {
      final csvData = await apiService.exportGradesCSV(accessToken, courseId);

      // La logique de téléchargement ne fonctionne que sur le web.
      if (kIsWeb) {
        final blob = html.Blob([csvData]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        html.AnchorElement(href: url)
          ..setAttribute("download", "notes_$courseName.csv")
          ..click();

        html.Url.revokeObjectUrl(url);
        return null; // Succès
      } else {
        return "L'export CSV n'est supporté que sur le web pour le moment.";
      }
    } catch (e) {
      return "Erreur lors de l'export CSV : $e";
    }
  }
}
