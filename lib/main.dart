// lib/main.dart of ryan
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trow_app_frontend/core/services/api_service.dart';
import 'package:trow_app_frontend/providers/auth_provider.dart';
import 'package:trow_app_frontend/providers/student_provider.dart';
import 'package:trow_app_frontend/providers/trainer_provider.dart'; // ✅ AJOUTER

import 'package:trow_app_frontend/providers/admin_provider.dart';   // ✅ AJOUTER
import 'package:trow_app_frontend/features/auth/login_screen.dart';
import 'package:trow_app_frontend/features/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Provider d'authentification principal
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Provider pour l'étudiant
        ChangeNotifierProxyProvider<AuthProvider, StudentProvider>(
          create: (context) => StudentProvider(
            ApiService(),
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => StudentProvider(ApiService(), auth),
        ),

        // ✅ Provider pour le formateur
        ChangeNotifierProxyProvider<AuthProvider, TrainerProvider>(
          create: (context) => TrainerProvider(
            apiService: ApiService(),
            auth: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => TrainerProvider(apiService: ApiService(), auth: auth),
        ),

        // ✅ Provider pour l'administrateur
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (context) => AdminProvider(
            apiService: ApiService(),
            auth: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => AdminProvider(apiService: ApiService(), auth: auth),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion des Notes',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
