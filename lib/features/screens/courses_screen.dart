import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trow_app_frontend/features/screens/course_detail_screen.dart';
import 'package:trow_app_frontend/providers/student_provider.dart';
import 'package:trow_app_frontend/core/models/cours.dart';


class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Cours'),
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingCourses) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.courses.isEmpty) {
            return const Center(child: Text('Aucun cours trouvé.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: provider.courses.length,
            itemBuilder: (context, index) {
              final Cours cours = provider.courses[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: const Icon(Icons.book, color: Colors.deepPurple),
                  title: Text(
                    cours.nom,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Formateur: ${cours.formateurUsername ?? 'Non assigné'}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // ✅ Navigation vers le détail du cours
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(cours: cours),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
