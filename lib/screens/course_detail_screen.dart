// © Copyright 2026 parvanshu. All rights reserved.
// This application codebase was designed, developed, and optimized by parvanshu.
// Unauthorized copying, reuse, or distribution of this code is strictly regulated.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final VoidCallback onBack;
  final Function(Lecture, Chapter) onLectureSelect;
  final Function(Note, Chapter) onNoteSelect;

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.onBack,
    required this.onLectureSelect,
    required this.onNoteSelect,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.course.subjects.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _buyCourse(BuildContext context, FirebaseService service) async {
    final success = await service.requestCourseEnrollment(widget.course.id, widget.course.title);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access requested! Roster verification typically takes 2-3 business days.'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
    } else if (service.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.errorMessage!),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final isPurchased = service.isCoursePurchased(widget.course.id);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button & Navigation
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: OutlinedButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Directory'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Main Responsive Split View (Left: Header & Purchase, Right: Syllabus tabs on desktop)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildCourseSummaryCard(context, service, isPurchased),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 6,
                  child: _buildSyllabusPanel(context, service, isPurchased),
                ),
              ],
            )
          else ...[
            _buildCourseSummaryCard(context, service, isPurchased),
            const SizedBox(height: 32),
            _buildSyllabusPanel(context, service, isPurchased),
          ],
        ],
      ),
    );
  }

  Widget _buildCourseSummaryCard(
    BuildContext context,
    FirebaseService service,
    bool isPurchased,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            widget.course.coverImageUrl,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
              height: 220,
              color: AppColors.primaryBlue.withOpacity(0.1),
              child: const Icon(Icons.school, size: 80, color: AppColors.primaryBlue),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course.title,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.course.tagline,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 16),
                _buildSpecRow(Icons.subject, 'Subjects', '${widget.course.subjects.length} Subjects Included'),
                const SizedBox(height: 12),
                _buildSpecRow(Icons.slow_motion_video, 'Lectures', 'Private URL On-demand Streaming'),
                const SizedBox(height: 12),
                _buildSpecRow(Icons.note, 'Material', 'DPPs & revision formula notes'),
                const SizedBox(height: 24),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 20),
                
                // Purchase Status Widget
                if (isPurchased)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_open, color: AppColors.successGreen),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You have full access to this course',
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (service.isEnrollmentRejected(widget.course.id))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cancel_outlined, color: AppColors.errorRed),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Admission Request Rejected',
                                style: TextStyle(
                                  color: AppColors.errorRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reason: ${service.getEnrollmentRejectionReason(widget.course.id)}',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.borderLight),
                        const SizedBox(height: 8),
                        const Text(
                          'Need help? Contact our Delhi coaching office:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '📞 Phone: +91 88888 88888\n📧 Email: help@crestachievers.com',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _buyCourse(context, service),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Re-submit Admission Request'),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (service.isEnrollmentPending(widget.course.id))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: service.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB), // soft amber background
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: service.isDarkMode ? const Color(0xFF334155) : const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.hourglass_empty, color: AppColors.warningOrange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Batch Access Request Pending',
                              style: TextStyle(
                                color: service.isDarkMode ? Colors.amber.shade200 : const Color(0xFF92400E),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your request to access the class recordings and notes of this batch has been sent to the center administrators. Admission approvals typically take 2-3 business days to verify with the offline registers. Thank you for your patience!',
                          style: TextStyle(
                            color: service.isDarkMode ? Colors.amber.shade100 : const Color(0xFFB45309),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Divider(color: service.isDarkMode ? const Color(0xFF334155) : const Color(0xFFFDE68A), height: 1),
                        const SizedBox(height: 20),
                        
                        // Step Progress Tracker
                        Row(
                          children: [
                            _buildStepNode(true, 'Request Submitted', 'Completed'),
                            _buildStepDivider(true),
                            _buildStepNode(false, 'Roster Verification', 'In Progress (2-3 days)'),
                            _buildStepDivider(false),
                            _buildStepNode(false, 'Access Activated', 'Locked'),
                          ],
                        ),
                      ],
                    ),
                  )
                else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Batch Verification',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: service.isDarkMode ? Colors.white70 : AppColors.primaryNavy),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Access to recorded classes and study materials is limited to registered offline students of this batch.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        
                        // Action Button
                        service.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => _buyCourse(context, service),
                                  icon: const Icon(Icons.lock_open, size: 18),
                                  label: const Text('Apply for Batch Access', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.05, end: 0);
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyllabusPanel(
    BuildContext context,
    FirebaseService service,
    bool isPurchased,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Syllabus & Chapters index',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            isPurchased
                ? 'Select a lecture or a PDF note to start learning.'
                : '🔒 Purchase this program to unlock and stream lectures/notes.',
            style: TextStyle(
              fontSize: 12,
              color: isPurchased ? AppColors.textMuted : AppColors.warningOrange,
              fontWeight: isPurchased ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Subject Tab Selector
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primaryBlue,
            dividerColor: AppColors.borderLight,
            tabs: widget.course.subjects.map((sub) => Tab(text: sub.name)).toList(),
          ),
          const SizedBox(height: 20),

          // Subject Syllabus View
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: widget.course.subjects.map((subject) {
                return _buildSubjectChapterList(context, service, subject, isPurchased);
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }

  Widget _buildSubjectChapterList(
    BuildContext context,
    FirebaseService service,
    Subject subject,
    bool isPurchased,
  ) {
    if (subject.chapters.isEmpty) {
      return const Center(child: Text('No chapters available for this subject yet.'));
    }

    return ListView.builder(
      itemCount: subject.chapters.length,
      itemBuilder: (context, index) {
        final chapter = subject.chapters[index];
        final progress = service.getChapterProgress(chapter);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              chapter.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Row(
              children: [
                Text(
                  '${chapter.lectures.length} Lectures • ${chapter.notes.length} PDF Notes',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const Spacer(),
                if (isPurchased) ...[
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% Done',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentIndigo),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 4,
                    child: LinearProgressIndicator(
                      value: progress,
                      color: AppColors.accentIndigo,
                      backgroundColor: AppColors.borderLight,
                    ),
                  ),
                ],
              ],
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // List of Lectures
              if (chapter.lectures.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Icon(Icons.video_library, size: 14, color: AppColors.textMuted),
                      SizedBox(width: 8),
                      Text('Video Lectures', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                ...chapter.lectures.map((lec) {
                  final isLecCompleted = service.isLectureCompleted(chapter.id, lec.title);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isLecCompleted ? Icons.check_circle : Icons.play_circle_outline,
                      color: isLecCompleted ? AppColors.successGreen : (isPurchased ? AppColors.primaryBlue : AppColors.textMuted),
                      size: 20,
                    ),
                    title: Text(lec.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: isPurchased
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(lec.duration, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              const SizedBox(width: 8),
                              _buildDownloadButton(context, service, chapter.id, lec.title, true),
                            ],
                          )
                        : Text(lec.duration, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    onTap: isPurchased
                        ? () => widget.onLectureSelect(lec, chapter)
                        : () => _showLockedDialog(context),
                  );
                }),
              ],
              const Divider(color: AppColors.borderLight, height: 24),
              // List of Notes
              if (chapter.notes.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Icon(Icons.library_books, size: 14, color: AppColors.textMuted),
                      SizedBox(width: 8),
                      Text('PDF notes & DPP sheets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                ...chapter.notes.map((note) {
                  final isNoteCompleted = service.isNoteCompleted(chapter.id, note.title);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isNoteCompleted ? Icons.check_circle : Icons.picture_as_pdf_outlined,
                      color: isNoteCompleted ? AppColors.successGreen : (isPurchased ? AppColors.accentIndigo : AppColors.textMuted),
                      size: 20,
                    ),
                    title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: isPurchased
                        ? _buildDownloadButton(context, service, chapter.id, note.title, false)
                        : null,
                    onTap: isPurchased
                        ? () => widget.onNoteSelect(note, chapter)
                        : () => _showLockedDialog(context),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppColors.warningOrange),
            SizedBox(width: 8),
            Text('Content Locked'),
          ],
        ),
        content: const Text('This class material is locked. Please unlock the course using the "Unlock Entire Course" button on the summary panel to start learning.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(bool isCompleted, String title, String subtitle) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isCompleted ? AppColors.successGreen : const Color(0xFFD1D5DB),
            child: Icon(
              isCompleted ? Icons.check : Icons.radio_button_unchecked,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(bool isActive) {
    return Container(
      width: 24,
      height: 2,
      color: isActive ? AppColors.successGreen : const Color(0xFFD1D5DB),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    FirebaseService service,
    String chapterId,
    String title,
    bool isLecture,
  ) {
    final key = "${chapterId}_$title";
    final isCached = isLecture 
        ? service.isLectureCached(chapterId, title)
        : service.isNoteCached(chapterId, title);
    final isDownloading = service.isDownloading(key);

    if (isDownloading) {
      final prog = service.getDownloadProgress(key);
      return SizedBox(
        width: 32,
        height: 32,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: CircularProgressIndicator(
            value: prog,
            strokeWidth: 2,
            color: AppColors.accentIndigo,
            backgroundColor: AppColors.borderLight,
          ),
        ),
      );
    }

    if (isCached) {
      return IconButton(
        icon: const Icon(Icons.cloud_done, color: AppColors.successGreen, size: 20),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Offline Cache Active'),
              content: Text('"$title" is saved in your secure local database. You can review this material without internet access 24/7.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    if (isLecture) {
                      await service.removeLectureFromCache(chapterId, title);
                    } else {
                      await service.removeNoteFromCache(chapterId, title);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from local cache!')),
                      );
                    }
                  },
                  child: const Text('Delete Cache', style: TextStyle(color: AppColors.errorRed)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        tooltip: 'Cached Offline',
      );
    }

    return IconButton(
      icon: const Icon(Icons.download_for_offline_outlined, color: AppColors.primaryBlue, size: 20),
      onPressed: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading "$title" to offline companion cache...'),
            duration: const Duration(seconds: 1),
          ),
        );
        if (isLecture) {
          await service.cacheLecture(chapterId, title);
        } else {
          await service.cacheNote(chapterId, title);
        }
      },
      tooltip: 'Download Offline',
    );
  }
}
