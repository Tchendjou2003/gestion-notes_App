import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trow_app_frontend/features/admin/admin_dashboard.dart';
import 'package:trow_app_frontend/features/students/student_dashboard.dart';
import 'package:trow_app_frontend/features/trainer/trainer_dashboard.dart';
import 'package:trow_app_frontend/features/screens/profile_screen.dart'; // Import the new profile screen

import 'package:trow_app_frontend/providers/auth_provider.dart';
import 'package:trow_app_frontend/core/models/profile_model.dart';

// Import des écrans

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.userProfile;

    return Scaffold(
     appBar: AppBar(
        title: Row(
          children: [
            // Remplacez cette icône par votre logo si vous en avez un
            Image.asset('assets/images/Logo TrOW.png', width: 80, height: 80),
            const SizedBox(width: 25),
            const Text('Tableau de Bord'),
          ],
        ),
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Gérer le profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(context, profile),
    );
  }

   Widget _buildDashboard(BuildContext context, Profile profile) {
    switch (profile.role) {
      case 'etudiant':
        return StudentDashboard(profile: profile); // Correct
      case 'formateur':
        // ✅ Remplacez le placeholder par le bon widget
        return TrainerDashboard(profile: profile);
      case 'admin':
        // ✅ Remplacez le placeholder par le bon widget
        return AdminDashboard(profile: profile);
      default:
        return const Center(child: Text("Rôle non reconnu."));
    }
}
}