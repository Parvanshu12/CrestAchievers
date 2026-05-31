// © Copyright 2026 parvanshu. All rights reserved.
// This application codebase was designed, developed, and optimized by parvanshu.
// Unauthorized copying, reuse, or distribution of this code is strictly regulated.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OfflineManagerScreen extends StatefulWidget {
  const OfflineManagerScreen({super.key});

  @override
  State<OfflineManagerScreen> createState() => _OfflineManagerScreenState();
}

class _OfflineManagerScreenState extends State<OfflineManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    // Parse cached items
    final cachedLectures = service.cachedLectures.toList();
    final cachedNotes = service.cachedNotes.toList();

    // Sum cache sizes (simulated)
    final double cachedSizeMB = (cachedLectures.length * 48.0) + (cachedNotes.length * 2.4);

    return Scaffold(
      backgroundColor: service.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Offline Cache Manager', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caching Statistics Banner
            _buildStatsBanner(service, cachedLectures.length + cachedNotes.length, cachedSizeMB),
            const SizedBox(height: 28),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primaryBlue,
              dividerColor: AppColors.borderLight,
              tabs: const [
                Tab(text: 'LECTURE VIDEOS'),
                Tab(text: 'STUDY SHEETS & DPPS'),
              ],
            ),
            const SizedBox(height: 20),

            // Tab View
            SizedBox(
              height: 450,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLecturesList(context, service, cachedLectures),
                  _buildNotesList(context, service, cachedNotes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBanner(FirebaseService service, int totalCount, double totalSizeMB) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientCardDecoration(
        colors: [AppColors.primaryBlue, AppColors.accentIndigo],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOCAL COMPANION STORE',
                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  '${totalSizeMB.toStringAsFixed(1)} MB Cached',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCount offline items ready for 24/7 access',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: totalSizeMB / 500.0, // out of 500 MB simulated quota
                  strokeWidth: 8,
                  color: AppColors.accentGold,
                  backgroundColor: Colors.white.withOpacity(0.15),
                ),
              ),
              const Icon(Icons.offline_pin, color: Colors.white, size: 28),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98));
  }

  Widget _buildLecturesList(BuildContext context, FirebaseService service, List<String> list) {
    if (list.isEmpty) {
      return _buildEmptyState(
        Icons.video_library_outlined,
        'No cached lectures yet',
        'Download class recordings inside batch syllabus pages to watch them completely offline.',
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final key = list[index];
        final parts = key.split('_');
        final chapterId = parts.isNotEmpty ? parts[0] : '';
        final title = parts.length > 1 ? parts.sublist(1).join('_') : 'Physics Lecture';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              child: Icon(Icons.play_arrow),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Cached MP4 Video • 48 MB • Offline Ready', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Playing "$title" 100% Offline!'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.offline_bolt_outlined, size: 14),
                  label: const Text('Play', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                  onPressed: () async {
                    await service.removeLectureFromCache(chapterId, title);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from cache!')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesList(BuildContext context, FirebaseService service, List<String> list) {
    if (list.isEmpty) {
      return _buildEmptyState(
        Icons.library_books_outlined,
        'No cached notes yet',
        'Download revision formula sheets and DPP worksheets to review offline at home.',
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final key = list[index];
        final parts = key.split('_');
        final chapterId = parts.isNotEmpty ? parts[0] : '';
        final title = parts.length > 1 ? parts.sublist(1).join('_') : 'DPP Sheet';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.accentIndigo,
              foregroundColor: Colors.white,
              child: Icon(Icons.picture_as_pdf),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Cached PDF Document • 2.4 MB • Offline Ready', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening PDF "$title" 100% Offline!'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.offline_bolt_outlined, size: 14),
                  label: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                  onPressed: () async {
                    await service.removeNoteFromCache(chapterId, title);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from cache!')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String description) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
          ),
        ),
      ],
    );
  }
}
