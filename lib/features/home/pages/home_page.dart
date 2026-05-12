import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../video/pages/create_video_page.dart';
import 'profile_page.dart';
import 'project_page.dart';

/// Màn hình chính của ứng dụng.
class HomePage extends StatefulWidget {
  /// Khởi tạo [HomePage].
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CreateVideoPage(),
    ProjectPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.15,
            colors: [Color(0xFF102A56), AppTheme.background],
            stops: [0.0, 0.52],
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.38),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_motion_outlined),
                  selectedIcon: Icon(Icons.auto_awesome_motion),
                  label: 'Tạo video',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_copy_outlined),
                  selectedIcon: Icon(Icons.folder_copy),
                  label: 'Dự án',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Tôi',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
