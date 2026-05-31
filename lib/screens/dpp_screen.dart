import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';

class DppScreen extends StatefulWidget {
  final String studentUid;
  const DppScreen({super.key, required this.studentUid});

  @override
  State<DppScreen> createState() => _DppScreenState();
}

class _DppScreenState extends State<DppScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _pdfUrlController = TextEditingController();
  String _selectedSubject = 'Physics';
  String _selectedBatch = 'JEE 2026';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    _pdfUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitDpp() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter worksheet details or question!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final service = Provider.of<FirebaseService>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final dpp = DppCard(
      id: 'dpp_${DateTime.now().millisecondsSinceEpoch}',
      subject: _selectedSubject,
      date: dateStr,
      questionText: _questionController.text.trim(),
      pdfUrl: _pdfUrlController.text.trim().isEmpty 
          ? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf' 
          : _pdfUrlController.text.trim(),
      batch: _selectedBatch,
      postedBy: service.currentUser?.uid ?? 'teacher',
    );

    await service.postDpp(dpp);
    
    setState(() {
      _isLoading = false;
      _questionController.clear();
      _pdfUrlController.clear();
    });

    _tabController.animateTo(0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DPP Worksheet posted and broadcasted successfully!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final isTeacher = service.currentUser?.role == 'teacher';

    return Scaffold(
      backgroundColor: service.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Daily Practice Problems (DPP)', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryNavy,
          tabs: [
            const Tab(text: 'Worksheets'),
            Tab(text: isTeacher ? 'Uploader Form' : 'Worksheet History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayAndRecentTab(service),
          isTeacher ? _buildUploaderTab(service) : _buildHistoryTab(service),
        ],
      ),
    );
  }

  Widget _buildTodayAndRecentTab(FirebaseService service) {
    return FutureBuilder<DppCard?>(
      future: service.getTodaysDpp(),
      builder: (context, snapshot) {
        final todayDpp = snapshot.data;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Highlight Banner for Today
                Text(
                  'Today\'s Active Worksheet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: service.isDarkMode ? Colors.white70 : AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 12),
                if (todayDpp == null)
                  _buildNoDppTodayCard(service)
                else
                  _buildDppMainCard(service, todayDpp, isToday: true),
                const SizedBox(height: 28),

                // Recent DPPs Header
                Text(
                  'Recent DPP Worksheets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: service.isDarkMode ? Colors.white70 : AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRecentDppsList(service, todayDpp?.id),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoDppTodayCard(FirebaseService service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColors.accentGold.withOpacity(0.8)),
          const SizedBox(height: 12),
          const Text(
            'All Caught Up!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'No DPP worksheet has been assigned for today yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDppMainCard(FirebaseService service, DppCard dpp, {bool isToday = false}) {
    final formattedDate = DateFormat('dd MMMM yyyy').format(DateTime.parse(dpp.date));
    Color subjectColor = _getSubjectColor(dpp.subject);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isToday 
              ? subjectColor.withOpacity(0.5) 
              : (service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: subjectColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dpp.subject.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: subjectColor),
                    ),
                  ],
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dpp.questionText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: service.isDarkMode ? Colors.white : AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target: ${dpp.batch}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            _postDoubtFromDpp(context, dpp, service);
                          },
                          icon: const Icon(Icons.camera_alt, size: 16),
                          style: IconButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.all(8),
                          ),
                          tooltip: 'Snap photo & post to Doubt Forum',
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Open PDF Viewer Screen
                            final noteObj = Note(title: '${dpp.subject} DPP - ${dpp.date}', pdfUrl: dpp.pdfUrl ?? '');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PdfViewerScreen(
                                  note: noteObj,
                                  chapter: Chapter(id: dpp.id, title: 'DPP Sheets', lectures: [], notes: [noteObj]),
                                  onBack: () => Navigator.of(context).pop(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                          label: const Text('Open DPP Worksheet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: subjectColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDppsList(FirebaseService service, String? todayDppId) {
    return FutureBuilder<List<DppCard>>(
      future: service.getDppHistory(),
      builder: (context, snapshot) {
        final list = (snapshot.data ?? []).where((d) => d.id != todayDppId).toList();
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No other recent worksheets found.',
                style: TextStyle(color: AppColors.textMuted.withOpacity(0.6), fontSize: 13),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final dpp = list[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildDppMainCard(service, dpp),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(FirebaseService service) {
    return _buildHistoryList(service);
  }

  Widget _buildHistoryList(FirebaseService service) {
    return FutureBuilder<List<DppCard>>(
      future: service.getDppHistory(limit: 50),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('No past DPP sheets found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final dpp = list[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildDppMainCard(service, dpp),
            );
          },
        );
      },
    );
  }

  Widget _buildUploaderTab(FirebaseService service) {
    final currentUser = service.currentUser;
    final isMasterUser = currentUser?.uid == 'crest_dev_master';

    final Map<String, String> batchToCourseId = {
      'JEE 2026': 'jee_achievers_2026',
      'NEET 2026': 'neet_elite_2026',
      'Class 12 Boards': 'class_12_pcm_2026',
      'Class 11 Foundation': 'class_11_pcm_2026',
    };

    // Filtered batches
    final filteredBatches = isMasterUser
        ? ['JEE 2026', 'NEET 2026', 'Class 12 Boards', 'Class 11 Foundation']
        : batchToCourseId.entries
            .where((entry) => currentUser?.assignedCourseIds.contains(entry.value) == true)
            .map((entry) => entry.key)
            .toList();

    // Filtered subjects
    final filteredSubjects = isMasterUser
        ? ['Physics', 'Chemistry', 'Mathematics', 'Biology']
        : ['Physics', 'Chemistry', 'Mathematics', 'Biology']
            .where((sub) => currentUser?.assignedSubjects.contains(sub) == true)
            .toList();

    // Ensure _selectedSubject is valid
    if (filteredSubjects.isNotEmpty) {
      if (!filteredSubjects.contains(_selectedSubject)) {
        _selectedSubject = filteredSubjects.first;
      }
    }

    // Ensure _selectedBatch is valid
    if (filteredBatches.isNotEmpty) {
      if (!filteredBatches.contains(_selectedBatch)) {
        _selectedBatch = filteredBatches.first;
      }
    }

    if (filteredBatches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 48),
            SizedBox(height: 16),
            Text(
              'No Assigned Batches',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
            ),
            SizedBox(height: 8),
            Text(
              'You must be assigned to batches and subjects by the Master Admin before uploading daily DPPs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publish New DPP Worksheet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: service.isDarkMode ? Colors.white : AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'DPPs will automatically trigger notifications to all students on publication.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Subject & Batch selectors
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                  items: filteredSubjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSubject = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBatch,
                  decoration: const InputDecoration(labelText: 'Target Batch', border: OutlineInputBorder()),
                  items: filteredBatches
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBatch = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Details textfield
          TextField(
            controller: _questionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Worksheet Description / Daily Target Question Outline',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              hintText: 'e.g., Today\'s worksheet covers Kinematics Projectile Motion. Solve all 10 single-option MCQs...',
            ),
          ),
          const SizedBox(height: 16),

          // PDF Url
          TextField(
            controller: _pdfUrlController,
            decoration: const InputDecoration(
              labelText: 'PDF Document link (Optional - fallback to dummy sheet if empty)',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
              hintText: 'https://example.com/dpp.pdf',
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitDpp,
              icon: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Publish and Broadcast Sheet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'physics':
        return Colors.orange.shade700;
      case 'chemistry':
        return Colors.blue.shade700;
      case 'mathematics':
        return Colors.red.shade700;
      case 'biology':
        return Colors.green.shade700;
      default:
        return AppColors.primaryNavy;
    }
  }

  void _postDoubtFromDpp(BuildContext context, DppCard dpp, FirebaseService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Doubt Snapshot Camera'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.green, size: 80),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ALIGN QUESTION INSIDE BOX',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Capture a tough question from the ${dpp.subject} DPP to instantly post to the Doubt Forum.',
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📸 Question Captured! Posting to doubts forum...'),
                  backgroundColor: AppColors.primaryBlue,
                ),
              );
              
              final post = DoubtPost(
                id: 'doubt_${DateTime.now().millisecondsSinceEpoch}',
                studentUid: service.currentUser?.uid ?? 'student_id',
                studentName: service.currentUser?.name ?? 'Student',
                subject: dpp.subject,
                questionText: 'Doubt from ${dpp.subject} DPP (${dpp.date}): Can someone explain how to solve the Kinematics problem on page 2?',
                replies: [],
                timestamp: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                isResolved: false,
                batch: dpp.batch,
              );
              await service.postDoubt(post);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Question successfully posted to the Doubt Q&A Forum!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            child: const Text('Capture Question'),
          ),
        ],
      ),
    );
  }
}
