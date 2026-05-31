// © Copyright 2026 parvanshu. All rights reserved.
// This application codebase was designed, developed, and optimized by parvanshu.
// Unauthorized copying, reuse, or distribution of this code is strictly regulated.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/firebase_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/lecture_player_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'screens/account_screen.dart';
import 'screens/social_screen.dart';
import 'screens/about_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/study_hub_screen.dart';
import 'models/course_model.dart';
import 'screens/attendance_screen.dart';
import 'screens/dpp_screen.dart';
import 'screens/timetable_screen.dart';
import 'screens/marks_screen.dart';
import 'screens/fee_screen.dart';
import 'screens/student_id_screen.dart';
import 'screens/doubt_forum_screen.dart';
import 'screens/parent_portal_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization skipped or failed: $e");
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => FirebaseService(),
      child: const CrestAchieversApp(),
    ),
  );
}

class CrestAchieversApp extends StatelessWidget {
  const CrestAchieversApp({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    return MaterialApp(
      title: 'Crest Achievers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: service.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainGatekeeper(),
    );
  }
}

class MainGatekeeper extends StatelessWidget {
  const MainGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    
    // Auth Gate: If user is not logged in, show AuthScreen. Else, show premium MainLayout.
    if (service.currentUser == null) {
      return const AuthScreen();
    }
    
    return const MainLayout();
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentTabIndex = 0; // 0: Home, 1: Shop, 2: Circle, 3: About/Admin, etc.

  // Navigation Backstack states to drill down details
  Course? _selectedCourse;
  Lecture? _selectedLecture;
  Note? _selectedNote;
  Chapter? _activeChapter;

  StreamSubscription? _notificationsSubscription;
  int _lastUnreadCount = 0;

  // Professional Navigation States
  bool _isStudyHubExpanded = false;
  String _searchQuery = '';
  final TextEditingController _drawerSearchController = TextEditingController();
  List<UserModel> _parentChildren = [];
  UserModel? _activeChildForParent;
  bool _isParentSelectorExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<FirebaseService>(context, listen: false);
      _notificationsSubscription = service.getNotificationsStream().listen((list) {
        final unreadCount = list.where((n) => !(n['isRead'] as bool)).length;
        if (unreadCount > _lastUnreadCount) {
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.vibrate();
          debugPrint("🔔 Ringing notification alert trigger! Count increased to $unreadCount");
        }
        _lastUnreadCount = unreadCount;
      });

      // Load children if logged in as a parent
      final user = service.currentUser;
      if (user?.role == 'parent') {
        service.getChildrenForParent(user!.uid).then((list) {
          if (list.isNotEmpty && mounted) {
            setState(() {
              _parentChildren = list;
              _activeChildForParent = list.first;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _getTabs(UserModel? user) {
    final List<Map<String, dynamic>> tabs = [
      {'icon': Icons.dashboard_outlined, 'title': 'Home Dashboard', 'label': 'Home'},
      {'icon': Icons.video_library_outlined, 'title': 'Syllabus Library', 'label': 'Library'},
      {'icon': Icons.stars_outlined, 'title': 'Study Tools Hub', 'label': 'Study Hub'},
      {'icon': Icons.group_outlined, 'title': 'Study Circle', 'label': 'Circle'},
      {'icon': Icons.info_outline, 'title': 'About & Centres', 'label': 'About'},
    ];

    // Give extra access: Admin tab only for teacher role
    if (user != null && user.role == 'teacher') {
      tabs.add({'icon': Icons.admin_panel_settings_outlined, 'title': 'Admin Console', 'label': 'Admin'});
    }

    tabs.add({'icon': Icons.person_outline, 'title': 'My Account Profile', 'label': 'Account'});
    return tabs;
  }

  void _onCourseSelect(Course course) {
    setState(() {
      _selectedCourse = course;
      _selectedLecture = null;
      _selectedNote = null;
      _activeChapter = null;
    });
  }

  void _onLectureSelect(Lecture lecture, Chapter chapter) {
    setState(() {
      _selectedLecture = lecture;
      _activeChapter = chapter;
      _selectedNote = null;
    });
  }

  void _onNoteSelect(Note note, Chapter chapter) {
    setState(() {
      _selectedNote = note;
      _activeChapter = chapter;
      _selectedLecture = null;
    });
  }

  void _resetDrilldown() {
    setState(() {
      _selectedCourse = null;
      _selectedLecture = null;
      _selectedNote = null;
      _activeChapter = null;
    });
  }

  void _onTabChange(int index) {
    setState(() {
      _currentTabIndex = index;
      _resetDrilldown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final user = service.currentUser;
    final tabs = _getTabs(user);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (isDesktop) ...[
              const Icon(Icons.stars, color: AppColors.primaryBlue, size: 28),
              const SizedBox(width: 8),
            ],
            const Text(
              'Crest Achievers',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentIndigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'PREMIUM',
                style: TextStyle(
                  color: AppColors.accentIndigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: service.getNotificationsStream(),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              final unreadCount = list.where((n) => !(n['isRead'] as bool)).length;

              return Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(unreadCount.toString()),
                child: IconButton(
                  icon: Icon(
                    unreadCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                    color: unreadCount > 0 ? AppColors.accentIndigo : (service.isDarkMode ? Colors.white70 : AppColors.textDark),
                  ),
                  onPressed: () {
                    _showNotificationsDialog(context, service, list);
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: isDesktop ? null : _buildMobileDrawer(context, service, user, tabs),
      body: Row(
        children: [
          // Dynamic Desktop Navigation Sidebar Drawer (only for larger viewports)
          if (isDesktop) _buildSidebar(context, service, user, tabs),

          // Main View Panel
          Expanded(
            child: Container(
              color: service.isDarkMode ? const Color(0xFF111827) : AppColors.bgSoftWhite,
              child: _buildActiveViewport(context, tabs),
            ),
          ),
        ],
      ),
      // Mobile Bottom Navigation Bar (only for compact viewports)
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(context, tabs),
    );
  }

  Widget _buildSidebar(BuildContext context, FirebaseService service, UserModel? user, List<Map<String, dynamic>> tabs) {
    final isDark = service.isDarkMode;
    int getIdx(String label) => tabs.indexWhere((t) => t['label'] == label);
    final targetUser = user?.role == 'parent' ? _activeChildForParent : user;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF8FAFC),
        border: Border(right: BorderSide(color: isDark ? const Color(0xFF1E293B) : AppColors.borderLight, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Parent Child switcher in sidebar header
          if (user?.role == 'parent' && _parentChildren.isNotEmpty)
            _buildSidebarParentProfileSelector(context, service, user!)
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accentGold.withOpacity(0.15),
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accentGold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Achiever User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : AppColors.primaryNavy,
                          ),
                        ),
                        Text(
                          user?.role.toUpperCase() ?? 'STUDENT',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Search Field for High-Speed Drawer Filtering
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _drawerSearchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textDark,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search tools, catalogs...',
                hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 11),
                prefixIcon: const Icon(Icons.search, size: 14, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _drawerSearchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: const Icon(Icons.clear, size: 14, color: AppColors.textMuted),
                      )
                    : null,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Render Navigation Items
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildFilteredList(context, service, targetUser, tabs)
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildSidebarHeader(service, 'DAILY WORKSPACE'),
                      _buildSidebarNavItem(Icons.dashboard_outlined, 'Home Dashboard', getIdx('Home'), service),
                      
                      // COLLAPSIBLE NESTED ACCORDION drawer-in-drawer
                      _buildSidebarAccordion(context, service, targetUser, getIdx('Study Hub')),
                      
                      _buildSidebarNavItem(Icons.group_outlined, 'Study Circle', getIdx('Circle'), service),
                      
                      const SizedBox(height: 18),
                      _buildSidebarHeader(service, 'SYLLABUS & CONTENT'),
                      _buildSidebarNavItem(Icons.video_library_outlined, 'Syllabus Library', getIdx('Library'), service),
                      _buildSidebarNavItem(Icons.info_outline, 'About & Centres', getIdx('About'), service),
                      
                      const SizedBox(height: 18),
                      _buildSidebarHeader(service, 'SYSTEM CONTEXT'),
                      if (user?.role == 'teacher')
                        _buildSidebarNavItem(Icons.admin_panel_settings_outlined, 'Admin Console', getIdx('Admin'), service),
                      _buildSidebarNavItem(Icons.person_outline, 'My Account', getIdx('Account'), service),
                    ],
                  ),
          ),

          // Gurugram Active Branch selector dropdown widget in footer
          if (user != null)
            _buildSidebarBranchSelector(context, service, user),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(FirebaseService service, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: service.isDarkMode ? Colors.white30 : AppColors.textMuted.withOpacity(0.7),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarNavItem(IconData icon, String title, int index, FirebaseService service) {
    final isSelected = _currentTabIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
      child: InkWell(
        onTap: () => _onTabChange(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primaryBlue : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.primaryBlue : (service.isDarkMode ? Colors.white70 : AppColors.textDark),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomNav(BuildContext context, List<Map<String, dynamic>> tabs) {
    // Mobile bottom navigation only shows key daily workspaces
    final List<Map<String, dynamic>> mobileTabs = tabs.where((t) {
      final lbl = t['label'];
      return lbl == 'Home' || lbl == 'Shop' || lbl == 'Study Hub' || lbl == 'Circle';
    }).toList();

    int activeIndex = mobileTabs.indexWhere((t) {
      final idx = tabs.indexOf(t);
      return idx == _currentTabIndex;
    });
    if (activeIndex == -1) activeIndex = 0; // Fallback

    return BottomNavigationBar(
      currentIndex: activeIndex,
      onTap: (mobIdx) {
        final globalIdx = tabs.indexOf(mobileTabs[mobIdx]);
        _onTabChange(globalIdx);
      },
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textMuted,
      backgroundColor: const Color(0xFFF1F5F9), // Muted bottom nav
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      items: mobileTabs.map((tab) {
        return BottomNavigationBarItem(
          icon: Icon(tab['icon'] as IconData),
          activeIcon: Icon(tab['icon'] as IconData),
          label: tab['label'] as String,
        );
      }).toList(),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, FirebaseService service, UserModel? user, List<Map<String, dynamic>> tabs) {
    final branchId = service.getBranchIdForStudent(user?.uid ?? '');
    final branchName = branchId == 'sector_56' ? 'Sector 56, Gurugram' : 'Sector 14, Gurugram';
    final targetUser = user?.role == 'parent' ? _activeChildForParent : user;
    final isDark = service.isDarkMode;
    int getIdx(String label) => tabs.indexWhere((t) => t['label'] == label);

    return Drawer(
      child: Container(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [AppColors.primaryNavy, const Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.accentGold.withOpacity(0.2),
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                ),
              ),
              accountName: Row(
                children: [
                  Expanded(
                    child: Text(
                      user?.name ?? 'Achiever User',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  if (user?.role == 'parent' && _parentChildren.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        _isParentSelectorExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isParentSelectorExpanded = !_isParentSelectorExpanded;
                        });
                      },
                    ),
                ],
              ),
              accountEmail: _isParentSelectorExpanded
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.email ?? '', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user?.role.toUpperCase() ?? 'STUDENT',
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on, size: 10, color: Colors.white70),
                            const SizedBox(width: 2),
                            Text(
                              branchName,
                              style: const TextStyle(fontSize: 10, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            
            // If parent child selector is expanded, show sub-list of children to switch between!
            if (_isParentSelectorExpanded && user?.role == 'parent' && _parentChildren.isNotEmpty)
              Expanded(
                child: Container(
                  color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF8FAFC),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'SWITCH ACTIVE STUDENT PROFILE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white30 : AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ..._parentChildren.map((child) {
                        final isActive = _activeChildForParent?.uid == child.uid;
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: isActive ? AppColors.primaryBlue : AppColors.textMuted.withOpacity(0.15),
                            child: Text(
                              child.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white : AppColors.textDark),
                            ),
                          ),
                          title: Text(
                            child.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? AppColors.primaryBlue : (isDark ? Colors.white70 : AppColors.textDark),
                            ),
                          ),
                          subtitle: Text(child.studentClass, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          trailing: isActive ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 16) : null,
                          onTap: () {
                            setState(() {
                              _activeChildForParent = child;
                              _isParentSelectorExpanded = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Switched view to child profile: ${child.name}!'),
                                backgroundColor: AppColors.successGreen,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      }),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.add_link, size: 18),
                        title: const Text('Manage Linked Children', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onTap: () {
                          Navigator.of(context).pop();
                          _onTabChange(getIdx('Study Hub'));
                          // Wait, study hub has children link manager or we can open ParentPortal directly!
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ParentPortalScreen())).then((_) {
                            // Reload children list
                            service.getChildrenForParent(user!.uid).then((list) {
                              if (list.isNotEmpty && mounted) {
                                setState(() {
                                  _parentChildren = list;
                                });
                              }
                            });
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Search Input field in Mobile Drawer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _drawerSearchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textDark,
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search tools, features...',
                    hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 11),
                    prefixIcon: const Icon(Icons.search, size: 14, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _drawerSearchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            child: const Icon(Icons.clear, size: 14, color: AppColors.textMuted),
                          )
                        : null,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    ),
                  ),
                ),
              ),

              // Filtered list or standard structured list
              Expanded(
                child: _searchQuery.isNotEmpty
                    ? _buildFilteredList(context, service, targetUser, tabs, popOnTap: true)
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildDrawerSectionHeader(service, 'DAILY WORKSPACE'),
                          _buildDrawerItem(Icons.dashboard_outlined, 'Home Dashboard', 'Home', service, tabs),
                          
                          // Collapsible Accordion Study Tools Hub Drawer Menu
                          _buildMobileAccordion(context, service, targetUser, tabs),
                          
                          _buildDrawerItem(Icons.group_outlined, 'Study Circle', 'Circle', service, tabs),
                          
                          _buildDrawerSectionHeader(service, 'COURSES & SHOP'),
                          _buildDrawerItem(Icons.shopping_bag_outlined, 'Courses Shop', 'Shop', service, tabs),
                          _buildDrawerItem(Icons.info_outline, 'About & Centres', 'About', service, tabs),
                          
                          _buildDrawerSectionHeader(service, 'SYSTEM CONTEXT'),
                          if (user?.role == 'teacher')
                            _buildDrawerItem(Icons.admin_panel_settings_outlined, 'Admin Console', 'Admin', service, tabs),
                          _buildDrawerItem(Icons.person_outline, 'My Account', 'Account', service, tabs),
                        ],
                      ),
              ),

              // Active Gurugram branch selector dropdown in footer
              if (user != null)
                _buildSidebarBranchSelector(context, service, user),
              
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  service.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
                  color: service.isDarkMode ? Colors.orange : AppColors.primaryNavy,
                ),
                title: Text(service.isDarkMode ? 'Toggle Warm Light' : 'Toggle Dark Mode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  service.toggleDarkMode();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.errorRed),
                title: const Text('Sign Out', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  Navigator.of(context).pop();
                  service.signOut();
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionHeader(FirebaseService service, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: service.isDarkMode ? Colors.white30 : AppColors.textMuted.withOpacity(0.7),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String tabLabel, FirebaseService service, List<Map<String, dynamic>> tabs) {
    final tabIndex = tabs.indexWhere((t) => t['label'] == tabLabel);
    final isSelected = _currentTabIndex == tabIndex;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryBlue : AppColors.textMuted),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? AppColors.primaryBlue : (service.isDarkMode ? Colors.white70 : AppColors.textDark),
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primaryBlue.withOpacity(0.08),
      onTap: () {
        _onTabChange(tabIndex);
        Navigator.of(context).pop();
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  PREMIUM UX/UI REFINE WORKSPACE HELPERS (NEW)
  // ─────────────────────────────────────────────────────────────

  Widget _buildSidebarParentProfileSelector(BuildContext context, FirebaseService service, UserModel parentUser) {
    final isDark = service.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.family_restroom, size: 12, color: AppColors.accentGold),
                const SizedBox(width: 6),
                Text(
                  'PARENT CONTEXT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                    color: isDark ? Colors.white30 : AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.15),
                  child: Text(
                    _activeChildForParent?.name.substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserModel>(
                      value: _activeChildForParent,
                      dropdownColor: isDark ? const Color(0xFF131D2E) : Colors.white,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primaryNavy,
                      ),
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      items: _parentChildren.map((child) {
                        return DropdownMenuItem<UserModel>(
                          value: child,
                          child: Text(
                            child.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (newChild) {
                        if (newChild != null) {
                          setState(() {
                            _activeChildForParent = newChild;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched view to child profile: ${newChild.name}!'),
                              backgroundColor: AppColors.successGreen,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarBranchSelector(BuildContext context, FirebaseService service, UserModel user) {
    final isDark = service.isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 12, color: AppColors.accentGold),
              const SizedBox(width: 6),
              Text(
                'ACTIVE CENTRE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                  color: isDark ? Colors.white30 : AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: service.studentBranchId,
              dropdownColor: isDark ? const Color(0xFF131D2E) : Colors.white,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primaryNavy,
              ),
              isDense: true,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 18),
              items: const [
                DropdownMenuItem(
                  value: 'sector_14',
                  child: Text('Sector 14 (Gurugram)', style: TextStyle(fontSize: 11)),
                ),
                DropdownMenuItem(
                  value: 'sector_56',
                  child: Text('Sector 56 (Gurugram)', style: TextStyle(fontSize: 11)),
                ),
              ],
              onChanged: (newBranch) {
                if (newBranch != null) {
                  service.setStudentBranch(user.uid, newBranch);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to ${newBranch == 'sector_56' ? 'Sector 56' : 'Sector 14'} branch context!'),
                      backgroundColor: AppColors.successGreen,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarAccordion(BuildContext context, FirebaseService service, UserModel? targetUser, int studyHubIdx) {
    final isDark = service.isDarkMode;
    final isSelected = _currentTabIndex == studyHubIdx;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isStudyHubExpanded = !_isStudyHubExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars_outlined,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Study Tools Hub',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    _isStudyHubExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_isStudyHubExpanded) ...[
            const SizedBox(height: 4),
            _buildSidebarAccordionSubItem(Icons.calendar_month, 'Attendance Heatmap', AttendanceScreen(studentUid: targetUser?.uid ?? ''), service),
            _buildSidebarAccordionSubItem(Icons.assignment_outlined, 'Daily Practice DPP', DppScreen(studentUid: targetUser?.uid ?? ''), service),
            _buildSidebarAccordionSubItem(Icons.forum_outlined, 'Doubts Forum', DoubtForumScreen(studentUid: targetUser?.uid ?? ''), service),
            _buildSidebarAccordionSubItem(Icons.schedule_outlined, 'Weekly Timetable', TimetableScreen(batch: targetUser?.studentClass ?? 'JEE 2026'), service),
            _buildSidebarAccordionSubItem(Icons.bar_chart_outlined, 'Marks & Test Analytics', MarksScreen(studentUid: targetUser?.uid ?? ''), service),
            _buildSidebarAccordionSubItem(Icons.account_balance_wallet_outlined, 'Fee Ledger & Invoices', FeeScreen(studentUid: targetUser?.uid ?? ''), service),
            _buildSidebarAccordionSubItem(Icons.badge_outlined, 'Digital Student ID', StudentIdScreen(student: targetUser), service),
          ]
        ],
      ),
    );
  }

  Widget _buildSidebarAccordionSubItem(IconData icon, String title, Widget route, FirebaseService service) {
    final isDark = service.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(left: 36.0, top: 2.0, bottom: 2.0, right: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => route));
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAccordion(BuildContext context, FirebaseService service, UserModel? targetUser, List<Map<String, dynamic>> tabs) {
    final isDark = service.isDarkMode;
    final int studyHubIdx = tabs.indexWhere((t) => t['label'] == 'Study Hub');
    final isSelected = _currentTabIndex == studyHubIdx;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.stars_outlined, color: AppColors.primaryBlue),
            title: Text(
              'Study Tools Hub',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.white70 : AppColors.textDark),
                fontSize: 13,
              ),
            ),
            trailing: Icon(
              _isStudyHubExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.textMuted,
              size: 18,
            ),
            selected: isSelected,
            selectedTileColor: AppColors.primaryBlue.withOpacity(0.08),
            onTap: () {
              setState(() {
                _isStudyHubExpanded = !_isStudyHubExpanded;
              });
            },
          ),
          if (_isStudyHubExpanded) ...[
            _buildMobileAccordionSubItem(Icons.calendar_month, 'Attendance Heatmap', AttendanceScreen(studentUid: targetUser?.uid ?? ''), service),
            _buildMobileAccordionSubItem(Icons.assignment_outlined, 'Daily Practice DPP', DppScreen(studentUid: targetUser?.uid ?? ''), service),
            _buildMobileAccordionSubItem(Icons.forum_outlined, 'Doubts Forum', DoubtForumScreen(studentUid: targetUser?.uid ?? ''), service),
            _buildMobileAccordionSubItem(Icons.schedule_outlined, 'Weekly Timetable', TimetableScreen(batch: targetUser?.studentClass ?? 'JEE 2026'), service),
            _buildMobileAccordionSubItem(Icons.bar_chart_outlined, 'Marks & Test Analytics', MarksScreen(studentUid: targetUser?.uid ?? ''), service),
            _buildMobileAccordionSubItem(Icons.account_balance_wallet_outlined, 'Fee Ledger & Invoices', FeeScreen(studentUid: targetUser?.uid ?? ''), service),
            _buildMobileAccordionSubItem(Icons.badge_outlined, 'Digital Student ID', StudentIdScreen(student: targetUser), service),
          ]
        ],
      ),
    );
  }

  Widget _buildMobileAccordionSubItem(IconData icon, String title, Widget route, FirebaseService service) {
    final isDark = service.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(left: 48.0),
      child: ListTile(
        leading: Icon(icon, size: 16, color: AppColors.textMuted),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : AppColors.textMuted,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop(); // Close drawer
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => route));
        },
      ),
    );
  }

  Widget _buildFilteredList(BuildContext context, FirebaseService service, UserModel? targetUser, List<Map<String, dynamic>> tabs, {bool popOnTap = false}) {
    final query = _searchQuery.toLowerCase();
    final isDark = service.isDarkMode;

    // Define all searchable items
    final List<Map<String, dynamic>> allSearchItems = [
      {'title': 'Home Dashboard', 'type': 'tab', 'label': 'Home', 'icon': Icons.dashboard_outlined},
      {'title': 'Syllabus & Video Library', 'type': 'tab', 'label': 'Library', 'icon': Icons.video_library_outlined},
      {'title': 'Study Tools Hub', 'type': 'tab', 'label': 'Study Hub', 'icon': Icons.stars_outlined},
      {'title': 'Study Circle Doubt Forum & Socials', 'type': 'tab', 'label': 'Circle', 'icon': Icons.group_outlined},
      {'title': 'About Crest & Physical Centres', 'type': 'tab', 'label': 'About', 'icon': Icons.info_outline},
      {'title': 'My Account Profile Settings', 'type': 'tab', 'label': 'Account', 'icon': Icons.person_outline},
      
      // Study Hub sub-items
      {'title': 'Attendance Heatmap & Calendar', 'type': 'route', 'icon': Icons.calendar_month, 'route': AttendanceScreen(studentUid: targetUser?.uid ?? '')},
      {'title': 'Daily Practice DPP Question Sheets', 'type': 'route', 'icon': Icons.assignment_outlined, 'route': DppScreen(studentUid: targetUser?.uid ?? '')},
      {'title': 'Doubts Forum shooting & replies', 'type': 'route', 'icon': Icons.forum_outlined, 'route': DoubtForumScreen(studentUid: targetUser?.uid ?? '')},
      {'title': 'Weekly Batch Timetable schedule', 'type': 'route', 'icon': Icons.schedule_outlined, 'route': TimetableScreen(batch: targetUser?.studentClass ?? 'JEE 2026')},
      {'title': 'Marks, Ranks & Test Analytics', 'type': 'route', 'icon': Icons.bar_chart_outlined, 'route': MarksScreen(studentUid: targetUser?.uid ?? '')},
      {'title': 'Fee Payment ledger Invoices & Receipts', 'type': 'route', 'icon': Icons.account_balance_wallet_outlined, 'route': FeeScreen(studentUid: targetUser?.uid ?? '')},
      {'title': 'Digital Student ID Card & Profile QR', 'type': 'route', 'icon': Icons.badge_outlined, 'route': StudentIdScreen(student: targetUser)},
    ];

    if (targetUser?.role == 'teacher') {
      allSearchItems.add({'title': 'Admin Console Student Grants', 'type': 'tab', 'label': 'Admin', 'icon': Icons.admin_panel_settings_outlined});
    }

    final filtered = allSearchItems.where((item) {
      return (item['title'] as String).toLowerCase().contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 28, color: AppColors.textMuted.withOpacity(0.5)),
              const SizedBox(height: 10),
              Text(
                'No matching utilities found',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: InkWell(
            onTap: () {
              if (popOnTap) Navigator.of(context).pop(); // Close mobile drawer
              
              if (item['type'] == 'tab') {
                final targetTabIdx = tabs.indexWhere((t) => t['label'] == item['label']);
                if (targetTabIdx != -1) {
                  _onTabChange(targetTabIdx);
                }
              } else {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => item['route'] as Widget));
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textDark,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveViewport(BuildContext context, List<Map<String, dynamic>> tabs) {
    // 1. Lecture Video Sub-Screen
    if (_selectedLecture != null && _activeChapter != null) {
      return LecturePlayerScreen(
        lecture: _selectedLecture!,
        chapter: _activeChapter!,
        onBack: () {
          setState(() {
            _selectedLecture = null;
          });
        },
      );
    }

    // 2. Note PDF Sub-Screen
    if (_selectedNote != null && _activeChapter != null) {
      return PdfViewerScreen(
        note: _selectedNote!,
        chapter: _activeChapter!,
        onBack: () {
          setState(() {
            _selectedNote = null;
          });
        },
      );
    }

    // 3. Course Details Sub-Screen
    if (_selectedCourse != null) {
      return CourseDetailScreen(
        course: _selectedCourse!,
        onBack: _resetDrilldown,
        onLectureSelect: _onLectureSelect,
        onNoteSelect: _onNoteSelect,
      );
    }

    // 4. Mapped Viewports
    final activeIndex = _currentTabIndex >= tabs.length ? 0 : _currentTabIndex;
    final activeLabel = tabs[activeIndex]['label'] as String;

    switch (activeLabel) {
      case 'Home':
        return HomeScreen(
          onTabChange: (targetIndex) {
            setState(() {
              _currentTabIndex = targetIndex;
              _resetDrilldown();
            });
          },
          onCourseSelect: _onCourseSelect,
        );
      case 'Library':
        return ShopScreen(
          onCourseSelect: _onCourseSelect,
        );
      case 'Study Hub':
        return StudyHubScreen(
          onCourseSelect: _onCourseSelect,
        );
      case 'Circle':
        return const SocialScreen();
      case 'About':
        return const AboutScreen();
      case 'Admin':
        return const AdminScreen();
      case 'Account':
        return AccountScreen(
          onCourseSelect: _onCourseSelect,
        );
      default:
        return const Center(child: Text('Viewport Error'));
    }
  }

  void _showNotificationsDialog(BuildContext context, FirebaseService service, List<Map<String, dynamic>> list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active, color: AppColors.accentIndigo),
                SizedBox(width: 8),
                Text('Achiever Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 350,
          child: list.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text('No notifications yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.borderLight),
                  itemBuilder: (context, index) {
                    final n = list[index];
                    final isRead = n['isRead'] as bool;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isRead)
                            const Padding(
                              padding: EdgeInsets.only(top: 6.0, right: 8.0),
                              child: Icon(Icons.circle, size: 8, color: AppColors.accentIndigo),
                            )
                          else
                            const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n['title'] ?? '',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n['body'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          if (list.any((n) => !(n['isRead'] as bool)))
            TextButton.icon(
              onPressed: () async {
                await service.markNotificationsAsRead();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All alerts marked as read!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Mark all as read'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
