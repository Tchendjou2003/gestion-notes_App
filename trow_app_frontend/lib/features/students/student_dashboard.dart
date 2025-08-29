import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trow_app_frontend/core/models/profile_model.dart';
import 'package:trow_app_frontend/features/screens/courses_screen.dart';
import 'package:trow_app_frontend/features/screens/grades_screen.dart';
import 'package:trow_app_frontend/providers/auth_provider.dart';

class StudentDashboard extends StatefulWidget {
  final Profile profile;
  const StudentDashboard({super.key, required this.profile});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late final PageController _pageController;
  late final Timer _timer;
  int _currentPage = 0;

  // Liste des images à afficher dans le carrousel.
  final List<String> _imageList = [
    'assets/images/photo1.jpg',
    'assets/images/photo2.jpg',
    'assets/images/photo3.jpg',
    // Ajoutez ici les chemins vers vos autres images.
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage, viewportFraction: 0.9);

    // Le minuteur qui change l'image toutes les secondes
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < _imageList.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile.fullName.isEmpty
        ? widget.profile.username
        : widget.profile.fullName;

    final List<Widget> dashboardCards = [
      _buildDashboardCard(
        context,
        title: "Mes Cours",
        subtitle: "Consulter la liste de vos matières",
        icon: Icons.library_books,
        color: Colors.indigo,
        destination: const StudentCoursesScreen(),
      ),
      _buildDashboardCard(
        context,
        title: "Mes Notes",
        subtitle: "Consulter vos résultats",
        icon: Icons.grade,
        color: Colors.amber,
        destination: const StudentGradesScreen(),
      ),
    ];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWideScreen = constraints.maxWidth > 600;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SizedBox(
                height: isWideScreen ? 200 : 180,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _imageList.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 1.0;
                        if (_pageController.position.haveDimensions) {
                          value = _pageController.page! - index;
                          value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
                        }
                        return Center(
                          child: SizedBox(
                            height: Curves.easeOut.transform(value) * (isWideScreen ? 200 : 180),
                            width: Curves.easeOut.transform(value) * constraints.maxWidth * 0.9,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.asset(
                            _imageList[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildPageIndicator(), // Page indicator
              const SizedBox(height: 16), // Space after indicator
              Text(
                'Bonjour, $name 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.profile.promotion_name ?? ''} - ${widget.profile.speciality_name ?? ''}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              if (isWideScreen)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: dashboardCards,
                )
              else
                Column(
                  children: [
                    dashboardCards[0],
                    const SizedBox(height: 16),
                    dashboardCards[1],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _imageList.map((url) {
        int index = _imageList.indexOf(url);
        return Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Colors.blueAccent
                : Colors.grey.withOpacity(0.5),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  radius: 30,
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(subtitle,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.8),
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}