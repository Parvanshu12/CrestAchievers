// © Copyright 2026 parvanshu. All rights reserved.
// This application codebase was designed, developed, and optimized by parvanshu.
// Unauthorized copying, reuse, or distribution of this code is strictly regulated.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';
import 'attendance_screen.dart';
import 'dpp_screen.dart';
import 'doubt_forum_screen.dart';
import 'timetable_screen.dart';
import 'marks_screen.dart';
import 'fee_screen.dart';
import 'student_id_screen.dart';
import 'parent_portal_screen.dart';
import 'offline_manager_screen.dart';

class StudyHubScreen extends StatefulWidget {
  final Function(Course) onCourseSelect;
  const StudyHubScreen({super.key, required this.onCourseSelect});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> {
  UserModel? _activeChild;

  @override
  void initState() {
    super.initState();
    _loadParentChildren();
  }

  Future<void> _loadParentChildren() async {
    final service = Provider.of<FirebaseService>(context, listen: false);
    if (service.currentUser?.role == 'parent') {
      final children = await service.getChildrenForParent(service.currentUser!.uid);
      if (children.isNotEmpty) {
        setState(() {
          _activeChild = children.first;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final user = service.currentUser;
    final isParent = user?.role == 'parent';
    final targetUser = isParent ? _activeChild : user;

    return Scaffold(
      backgroundColor: service.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isParent ? 'Parent Portal' : 'Study Tools Hub',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: service.isDarkMode ? Colors.white : AppColors.primaryNavy,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isParent 
                            ? 'Monitoring academic journey of your child'
                            : 'All your academic utilities in one premium dashboard',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.stars,
                    color: AppColors.accentGold,
                    size: 32,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Parent view: Children Switcher
              if (isParent) ...[
                _buildChildrenSelector(service),
                const SizedBox(height: 24),
              ],

              if (isParent && _activeChild == null) ...[
                _buildNoLinkedChildrenCard(service),
              ] else ...[
                // Quick Performance Banner
                _buildOverviewBanner(service, targetUser),
                const SizedBox(height: 28),

                // Grid of Tools
                Text(
                  'Academic Utility Suite',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: service.isDarkMode ? Colors.white70 : AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 16),
                _buildToolsGrid(context, service, targetUser),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenSelector(FirebaseService service) {
    return FutureBuilder<List<UserModel>>(
      future: service.getChildrenForParent(service.currentUser!.uid),
      builder: (context, snapshot) {
        final children = snapshot.data ?? [];
        if (children.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.child_care, color: AppColors.accentGold, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'SELECT CHILD TO MONITOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    final isSelected = _activeChild?.uid == child.uid;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          child.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Colors.white 
                                : (service.isDarkMode ? Colors.white70 : AppColors.primaryNavy),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _activeChild = child;
                            });
                          }
                        },
                        selectedColor: AppColors.primaryNavy,
                        backgroundColor: service.isDarkMode ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 16, thickness: 0.5),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ParentPortalScreen(),
                    ),
                  ).then((_) => _loadParentChildren());
                },
                icon: const Icon(Icons.add_link, size: 18, color: AppColors.primaryBlue),
                label: const Text(
                  'Manage Linked Children / Add New Link',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoLinkedChildrenCard(FirebaseService service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 64, color: AppColors.accentGold.withOpacity(0.8)),
          const SizedBox(height: 16),
          Text(
            'No Linked Children Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: service.isDarkMode ? Colors.white : AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'To see attendance, test results, and fee reports, you need to link your parent account with your child\'s student profile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ParentPortalScreen(),
                ),
              ).then((_) => _loadParentChildren());
            },
            icon: const Icon(Icons.add_link),
            label: const Text('Link a Student Profile Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewBanner(FirebaseService service, UserModel? targetUser) {
    final name = targetUser?.name ?? 'Student';
    final target = targetUser?.studentClass ?? 'JEE 2026';
    final branch = service.studentBranchId == 'sector_56' ? 'Sector 56' : 'Sector 14';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: service.isDarkMode 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [AppColors.primaryNavy, const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accentGold.withOpacity(0.15),
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.accentGold, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$branch Branch',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  target,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Attendance', '94%', Icons.calendar_today_outlined),
              _buildMiniStat('Last Test', '82%', Icons.grade_outlined),
              _buildMiniStat('Fee Status', 'Paid', Icons.check_circle_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildToolsGrid(BuildContext context, FirebaseService service, UserModel? targetUser) {
    final tools = [
      {
        'title': 'Attendance Heatmap',
        'subtitle': 'Class presence calendar logs',
        'icon': Icons.calendar_month,
        'color': AppColors.primaryBlue,
        'route': AttendanceScreen(studentUid: targetUser?.uid ?? ''),
      },
      {
        'title': 'Daily Practice DPP',
        'subtitle': 'Solve worksheets and question sheets',
        'icon': Icons.assignment_outlined,
        'color': AppColors.accentGold,
        'route': DppScreen(studentUid: targetUser?.uid ?? ''),
      },
      {
        'title': 'Doubts Forum',
        'subtitle': 'Shoot doubts & see faculty replies',
        'icon': Icons.forum_outlined,
        'color': const Color(0xFF10B981), // Emerald Success
        'route': DoubtForumScreen(studentUid: targetUser?.uid ?? ''),
      },
      {
        'title': 'Weekly Timetable',
        'subtitle': 'Batch schedule & class rooms',
        'icon': Icons.schedule_outlined,
        'color': const Color(0xFF8B5CF6), // Violet
        'route': TimetableScreen(batch: targetUser?.studentClass ?? 'JEE 2026'),
      },
      {
        'title': 'Marks & Test Analytics',
        'subtitle': 'Test ranks & progress report charts',
        'icon': Icons.bar_chart_outlined,
        'color': const Color(0xFFEF4444), // Rose Error
        'route': MarksScreen(studentUid: targetUser?.uid ?? ''),
      },
      {
        'title': 'Fee payment ledger',
        'subtitle': 'Monthly invoices & status logs',
        'icon': Icons.account_balance_wallet_outlined,
        'color': const Color(0xFF06B6D4), // Cyan
        'route': FeeScreen(studentUid: targetUser?.uid ?? ''),
      },
      {
        'title': 'Digital Student ID',
        'subtitle': 'Virtual identity card & QR sharing',
        'icon': Icons.badge_outlined,
        'color': AppColors.primaryNavy,
        'route': StudentIdScreen(student: targetUser),
      },
      {
        'title': 'Offline Cache Manager',
        'subtitle': 'Manage videos & sheets offline',
        'icon': Icons.offline_pin_outlined,
        'color': const Color(0xFFD97706), // Golden amber
        'route': const OfflineManagerScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.15,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        final iconColor = tool['color'] as Color;

        return InteractiveHoverCard(
          isDarkMode: service.isDarkMode,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => tool['route'] as Widget),
            );
          },
          child: Card(
            color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      tool['icon'] as IconData,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: service.isDarkMode ? Colors.white : AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tool['subtitle'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class InteractiveHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDarkMode;
  const InteractiveHoverCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  State<InteractiveHoverCard> createState() => _InteractiveHoverCardState();
}

class _InteractiveHoverCardState extends State<InteractiveHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.diagonal3Values(
            _isHovered ? 1.03 : 1.0,
            _isHovered ? 1.03 : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.accentIndigo.withOpacity(0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: AnimatedTheme(
            data: Theme.of(context).copyWith(
              cardTheme: CardThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _isHovered
                        ? AppColors.accentIndigo
                        : (widget.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
                    width: _isHovered ? 2.0 : 1.0,
                  ),
                ),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
