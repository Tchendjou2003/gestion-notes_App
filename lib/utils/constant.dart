// lib/utils/constants.dart

// Utilisez 10.0.2.2 pour l'émulateur Android, sinon localhost pour le web.
// kIsWeb est une constante globale de Flutter.
import 'package:flutter/foundation.dart' show kIsWeb;

const String baseUrl = kIsWeb ? 'http://127.0.0.1:8000/api/v1' : 'http://10.0.2.2:8000/api/v1';