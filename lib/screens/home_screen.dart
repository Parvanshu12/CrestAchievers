// © Copyright 2026 parvanshu. All rights reserved.
// This application codebase was designed, developed, and optimized by parvanshu.
// Unauthorized copying, reuse, or distribution of this code is strictly regulated.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../models/course_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onTabChange;
  final Function(Course) onCourseSelect;

  const HomeScreen({
    super.key,
    required this.onTabChange,
    required this.onCourseSelect,
  });

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final user = service.currentUser;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    // Filter courses purchased by user
    final purchasedCourses = service.courses
        .where((c) => service.isCoursePurchased(c.id))
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Target Class Header Card
          _buildHeaderCard(context, service, user),
          const SizedBox(height: 16),

          // Dynamic Live announcements ticker
          _buildAnnouncementsTicker(context, service),
          const SizedBox(height: 20),

          // Quick Stats Banner Row
          _buildQuickStats(context, service),
          const SizedBox(height: 20),

          // Today's Assigned DPP Worksheet Card
          _buildTodayDppWidget(context, service),
          const SizedBox(height: 24),

          // Main Responsive content row (Side bar for announcements on desktop, stacked on mobile)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMyCoursesSection(context, service, purchasedCourses),
                      const SizedBox(height: 32),
                      _buildStudyAnalytics(context, service, purchasedCourses),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: _buildAnnouncementsSection(context, service),
                ),
              ],
            )
          else ...[
            _buildMyCoursesSection(context, service, purchasedCourses),
            const SizedBox(height: 32),
            _buildAnnouncementsSection(context, service),
            const SizedBox(height: 32),
            _buildStudyAnalytics(context, service, purchasedCourses),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, FirebaseService service, UserModel? user) {
    final name = user?.name ?? 'Guest Achiever';
    final targetClass = user?.studentClass ?? '12th PCM';
    final branchId = user != null ? service.getBranchIdForStudent(user.uid) : 'sector_14';
    final branchName = branchId == 'sector_56' ? 'Sector 56' : 'Sector 14';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.gradientCardDecoration(
        colors: [AppColors.primaryBlue, AppColors.accentIndigo],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🎯 TARGET: $targetClass',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '$branchName Center',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B), // Warm saffron-gold flame accent
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '🔥 7-DAY STREAK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Hello, $name! 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome back to Crest Achievers. Continue your structured physics, chemistry, and math syllabus classes to scale your score.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMyCoursesSection(
    BuildContext context,
    FirebaseService service,
    List<Course> courses,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📚 My Batches & Classes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (courses.isEmpty)
              TextButton(
                onPressed: () => onTabChange(1), // Go to Syllabus Library
                child: const Text('Explore Library'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (courses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: CardTheme.of(context).shape != null
                ? BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: Column(
              children: [
                const Icon(Icons.school_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text(
                  'No active batches approved!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Apply for batch access in the Syllabus Library to unlock offline class notes, videos, and daily worksheets.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => onTabChange(1), // Go to Syllabus Library
                  icon: const Icon(Icons.library_books_outlined, size: 18),
                  label: const Text('Explore Syllabus Library'),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 180,
            ),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildCourseDashboardCard(context, service, course);
            },
          ),
      ],
    );
  }

  Widget _buildCourseDashboardCard(
    BuildContext context,
    FirebaseService service,
    Course course,
  ) {
    // Calculate overall course progress
    int totalChapters = 0;
    double progressSum = 0.0;
    for (var subject in course.subjects) {
      for (var chapter in subject.chapters) {
        totalChapters++;
        progressSum += service.getChapterProgress(chapter);
      }
    }
    double overallProgress = totalChapters > 0 ? progressSum / totalChapters : 0.0;

    return Card(
      child: InkWell(
        onTap: () => onCourseSelect(course),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      course.coverImageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        width: 48,
                        height: 48,
                        child: const Icon(Icons.school, color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${course.subjects.length} Subjects • $totalChapters Chapters',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Course Completion', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(
                    '${(overallProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: overallProgress,
                backgroundColor: AppColors.borderLight,
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildAnnouncementsSection(BuildContext context, FirebaseService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📢 Institute Bulletin',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassCardDecoration(),
          child: StreamBuilder<List<String>>(
            stream: service.getAnnouncementsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final announcements = snapshot.data ?? [];
              if (announcements.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No announcements active today.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                );
              }
              return Column(
                children: announcements.map((announcement) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Icon(Icons.circle, size: 6, color: AppColors.accentIndigo),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            announcement,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudyAnalytics(
    BuildContext context,
    FirebaseService service,
    List<Course> courses,
  ) {
    if (courses.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📈 Syllabus Progress Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress by Course & Subject',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 20),
                Builder(
                  builder: (context) {
                    final Map<String, List<Subject>> groupedSubjects = {};
                    for (var course in courses) {
                      for (var sub in course.subjects) {
                        final key = sub.name.trim();
                        groupedSubjects.putIfAbsent(key, () => []).add(sub);
                      }
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: groupedSubjects.entries.map((entry) {
                        final subName = entry.key;
                        final list = entry.value;
                        double totalProg = 0.0;
                        for (var sub in list) {
                          totalProg += service.getSubjectProgress(sub);
                        }
                        double subProg = list.isNotEmpty ? totalProg / list.length : 0.0;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    subName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
                                  ),
                                  Text(
                                    '${(subProg * 100).toStringAsFixed(0)}% Done',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentIndigo,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: subProg,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                                color: AppColors.accentIndigo,
                                backgroundColor: AppColors.borderLight,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, FirebaseService service) {
    final isDarkMode = service.isDarkMode;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            '94%',
            'Attendance',
            Icons.calendar_today,
            AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            '82%',
            'Last Score',
            Icons.grade_outlined,
            AppColors.accentGold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'Paid',
            'Fee Status',
            Icons.check_circle_outline,
            AppColors.successGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon, Color color) {
    final isDarkMode = Provider.of<FirebaseService>(context, listen: false).isDarkMode;
    return Card(
      color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDarkMode ? Colors.white : AppColors.primaryNavy),
                ),
                Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTodayDppWidget(BuildContext context, FirebaseService service) {
    return FutureBuilder<DppCard?>(
      future: service.getTodaysDpp(),
      builder: (context, snapshot) {
        final dpp = snapshot.data;
        if (dpp == null) return const SizedBox.shrink();

        final isDarkMode = service.isDarkMode;

        return Card(
          color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.accentGold.withOpacity(0.5), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment, color: AppColors.accentGold, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'TODAY\'S ASSIGNED DPP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentGold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dpp.subject.toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  dpp.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white70 : AppColors.primaryNavy,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Published on: ${dpp.date}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    TextButton(
                      onPressed: () => onTabChange(2), // Redirect to Study Hub (Index 2)
                      child: const Row(
                        children: [
                          Text('Solve Sheet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildAnnouncementsTicker(BuildContext context, FirebaseService service) {
    return StreamBuilder<List<String>>(
      stream: service.getAnnouncementsStream(),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (list.isEmpty) return const SizedBox.shrink();
        return LiveAnnouncementsTicker(
          announcements: list,
          isDarkMode: service.isDarkMode,
        );
      },
    );
  }
}

class LiveAnnouncementsTicker extends StatefulWidget {
  final List<String> announcements;
  final bool isDarkMode;
  const LiveAnnouncementsTicker({super.key, required this.announcements, required this.isDarkMode});

  @override
  State<LiveAnnouncementsTicker> createState() => _LiveAnnouncementsTickerState();
}

class _LiveAnnouncementsTickerState extends State<LiveAnnouncementsTicker> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (widget.announcements.length <= 1) return;
      setState(() {
        _currentPage = (_currentPage + 1) % widget.announcements.length;
      });
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF1E293B).withOpacity(0.4)
            : const Color(0xFFEFF6FF), // soft blue
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode
              ? const Color(0xFF334155).withOpacity(0.5)
              : AppColors.primaryBlue.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_outlined, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'LATEST',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 20,
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: widget.announcements.length,
                onPageChanged: (page) {
                  _currentPage = page;
                },
                itemBuilder: (context, idx) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.announcements[idx],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode ? Colors.white.withOpacity(0.9) : AppColors.primaryNavy,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
