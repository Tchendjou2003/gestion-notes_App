// lib/features/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:trow_app_frontend/core/models/profile_model.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required Profile profile});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord Admin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(leading: Icon(Icons.person), title: Text('Gérer les utilisateurs')),
          ListTile(leading: Icon(Icons.school), title: Text('Gérer les cours')),
          ListTile(leading: Icon(Icons.category), title: Text('Spécialités & Promotions')),
          ListTile(leading: Icon(Icons.file_download), title: Text('Exporter les notes (CSV)')),
        ],
      ),
    );
  }
}
