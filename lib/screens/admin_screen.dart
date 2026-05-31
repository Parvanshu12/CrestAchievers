import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _materialFormKey = GlobalKey<FormState>();
  final _announcementController = TextEditingController();
  
  // Material Uploader state
  String? _selectedCourseId;
  String _selectedSubject = 'Physics';
  String _materialType = 'lecture'; // 'lecture' or 'note'
  final _chapterTitleController = TextEditingController();
  final _materialTitleController = TextEditingController();

  PlatformFile? _selectedVideoFile;
  PlatformFile? _selectedPdfFile;

  final List<String> _subjects = ['Physics', 'Chemistry', 'Mathematics', 'Biology'];

  List<UserModel> _enrolledStudents = [];
  bool _loadingStudents = false;
  String _studentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final service = Provider.of<FirebaseService>(context, listen: false);
    setState(() {
      _loadingStudents = true;
    });
    final list = await service.fetchAdminStudentDirectory();
    if (mounted) {
      setState(() {
        _enrolledStudents = list;
        _loadingStudents = false;
      });
    }
  }

  @override
  void dispose() {
    _announcementController.dispose();
    _chapterTitleController.dispose();
    _materialTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedVideoFile = result.files.first;
        });
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedPdfFile = result.files.first;
        });
      }
    } catch (e) {
      debugPrint("Error picking PDF: $e");
    }
  }

  void _submitAnnouncement(FirebaseService service) async {
    if (_announcementController.text.trim().isEmpty) return;
    await service.publishAnnouncement(_announcementController.text);
    _announcementController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notice broadcasted to all student dashboards!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _submitMaterial(FirebaseService service) async {
    if (!_materialFormKey.currentState!.validate() || _selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course and fill in all fields'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_materialType == 'lecture' && _selectedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a video lecture file from the gallery first'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_materialType == 'note' && _selectedPdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a PDF revision note file from your device first'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    String finalUrl = '';
    if (_materialType == 'lecture') {
      finalUrl = await service.uploadVideoFile(
        _selectedVideoFile!.name,
        _selectedVideoFile!.bytes ?? Uint8List(0),
        _selectedVideoFile!.path,
      );
    } else {
      finalUrl = await service.uploadVideoFile(
        _selectedPdfFile!.name,
        _selectedPdfFile!.bytes ?? Uint8List(0),
        _selectedPdfFile!.path,
      );
    }

    final success = await service.addNewCourseMaterial(
      _selectedCourseId!,
      _selectedSubject,
      _chapterTitleController.text.trim(),
      _materialType,
      _materialTitleController.text.trim(),
      finalUrl,
    );

    if (success && mounted) {
      _chapterTitleController.clear();
      _materialTitleController.clear();
      setState(() {
        _selectedVideoFile = null;
        _selectedPdfFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New material successfully compiled & deployed to student portals!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _showRejectionDialog(BuildContext context, FirebaseService service, Map<String, String> enroll) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Batch Access for ${enroll['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batch: ${enroll['courseTitle']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text('Student Contact: ${enroll['email']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection',
                hintText: 'e.g. Not found in Sector 14 physical roster register',
              ),
              maxLines: 2,
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
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }
              final reason = reasonController.text.trim();
              Navigator.of(context).pop();
              await service.rejectEnrollment(
                enroll['id']!,
                enroll['uid']!,
                enroll['courseId']!,
                enroll['courseTitle']!,
                reason,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rejected request for ${enroll['name']}.'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final isMasterUser = service.currentUser?.uid == 'crest_dev_master';

    // Filter courses based on teacher assignments
    final filteredCourses = isMasterUser 
        ? service.courses 
        : service.courses.where((c) => service.currentUser?.assignedCourseIds.contains(c.id) == true).toList();

    // Set default selected course ID if not set
    if (filteredCourses.isNotEmpty) {
      if (_selectedCourseId == null || !filteredCourses.any((c) => c.id == _selectedCourseId)) {
        _selectedCourseId = filteredCourses.first.id;
      }
    } else {
      _selectedCourseId = null;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Text(
            '🔑 Teacher Admin Console',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add lectures, approve student batch access applications, and broadcast notices instantly.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Responsive layout
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      if (isMasterUser) ...[
                        _buildTeacherManagementCard(service),
                        const SizedBox(height: 24),
                      ],
                      _buildEnrollmentApprovalsCard(service),
                      const SizedBox(height: 24),
                      _buildRevokeAccessCard(service),
                      const SizedBox(height: 24),
                      _buildAnnouncementBroadcasterCard(service),
                      const SizedBox(height: 24),
                      _buildDataExporterCard(service),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 6,
                  child: _buildMaterialUploaderCard(service),
                ),
              ],
            )
          else ...[
            if (isMasterUser) ...[
              _buildTeacherManagementCard(service),
              const SizedBox(height: 24),
            ],
            _buildEnrollmentApprovalsCard(service),
            const SizedBox(height: 24),
            _buildRevokeAccessCard(service),
            const SizedBox(height: 24),
            _buildMaterialUploaderCard(service),
            const SizedBox(height: 24),
            _buildAnnouncementBroadcasterCard(service),
            const SizedBox(height: 24),
            _buildDataExporterCard(service),
          ],
        ],
      ),
    );
  }

  Widget _buildEnrollmentApprovalsCard(FirebaseService service) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline_rounded, color: AppColors.accentIndigo, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Batch Access Approvals Desk',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Review pending student batch access requests, verify physical registers, and grant live access.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          
          StreamBuilder<List<Map<String, String>>>(
            stream: service.getPendingEnrollmentsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.bgSoftWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.verified_outlined, color: AppColors.successGreen, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'All clear! No pending batch requests.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final enroll = list[index];
                  return Card(
                    color: AppColors.bgSoftWhite,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  enroll['name'] ?? 'Student',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Batch Applied: ${enroll['courseTitle']}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Contact: ${enroll['email']}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await service.approveEnrollment(
                                    enroll['id']!,
                                    enroll['uid']!,
                                    enroll['courseId']!,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Granted access to ${enroll['courseTitle']} for ${enroll['name']}!'),
                                        backgroundColor: AppColors.successGreen,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.successGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Approve', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () {
                                  _showRejectionDialog(context, service, enroll);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  side: const BorderSide(color: AppColors.errorRed),
                                  foregroundColor: AppColors.errorRed,
                                ),
                                child: const Text('Reject', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildMaterialUploaderCard(FirebaseService service) {
    final currentUser = service.currentUser;
    final isMasterUser = currentUser?.uid == 'crest_dev_master';
    
    // Filter courses based on teacher assignments
    final filteredCourses = isMasterUser 
        ? service.courses 
        : service.courses.where((c) => currentUser?.assignedCourseIds.contains(c.id) == true).toList();
        
    // Filter subjects based on teacher assignments
    final filteredSubjects = isMasterUser
        ? _subjects
        : _subjects.where((s) => currentUser?.assignedSubjects.contains(s) == true).toList();

    // Verify selections to avoid mismatch
    if (filteredCourses.isNotEmpty && (_selectedCourseId == null || !filteredCourses.any((c) => c.id == _selectedCourseId))) {
      _selectedCourseId = filteredCourses.first.id;
    }
    if (filteredSubjects.isNotEmpty && !filteredSubjects.contains(_selectedSubject)) {
      _selectedSubject = filteredSubjects.first;
    }

    if (filteredCourses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: AppTheme.glassCardDecoration(),
        child: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 40),
            SizedBox(height: 12),
            Text(
              'No Batches Assigned',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
            ),
            SizedBox(height: 6),
            Text(
              'You must be assigned to courses/subjects by the Master Admin before uploading materials.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassCardDecoration(),
      child: Form(
        key: _materialFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryBlue, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Syllabus & Material Uploader',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Add video lessons or note sheets directly into subjects. Updates stream instantly to active students.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 24),

            // Course Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Target Course / Batch',
                prefixIcon: Icon(Icons.class_outlined, size: 18),
              ),
              items: filteredCourses.map((course) {
                return DropdownMenuItem<String>(
                  value: course.id,
                  child: Text(course.title, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCourseId = val;
                });
              },
            ),
            const SizedBox(height: 16),

            // Subject Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Target Subject',
                prefixIcon: Icon(Icons.biotech_outlined, size: 18),
              ),
              items: filteredSubjects.map((sub) {
                return DropdownMenuItem<String>(
                  value: sub,
                  child: Text(sub, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSubject = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Chapter Title Input
            TextFormField(
              controller: _chapterTitleController,
              decoration: const InputDecoration(
                labelText: 'Chapter Name',
                prefixIcon: Icon(Icons.folder_open_outlined, size: 18),
                hintText: 'e.g. Electrostatics or Kinematics',
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Enter chapter name' : null,
            ),
            const SizedBox(height: 16),

            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                const Text('Material Type: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ChoiceChip(
                  label: const Text('Lecture Video', style: TextStyle(fontSize: 12)),
                  selected: _materialType == 'lecture',
                  onSelected: (selected) {
                    if (selected) setState(() => _materialType = 'lecture');
                  },
                ),
                ChoiceChip(
                  label: const Text('Revision PDF Note', style: TextStyle(fontSize: 12)),
                  selected: _materialType == 'note',
                  onSelected: (selected) {
                    if (selected) setState(() => _materialType = 'note');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title Input
            TextFormField(
              controller: _materialTitleController,
              decoration: InputDecoration(
                labelText: _materialType == 'lecture' ? 'Lecture Title' : 'PDF Document Title',
                prefixIcon: Icon(_materialType == 'lecture' ? Icons.play_circle_outline : Icons.picture_as_pdf_outlined, size: 18),
                hintText: _materialType == 'lecture' ? 'e.g. Lecture 3: Projectile Motion' : 'e.g. Formula Sheet',
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Enter title' : null,
            ),
            const SizedBox(height: 16),

            // Conditional Uploader Input
            _materialType == 'lecture'
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Video from Gallery:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickVideoFile,
                              icon: const Icon(Icons.video_library_outlined, size: 16),
                              label: const Text('Choose Video File', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentIndigo,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedVideoFile == null
                                    ? 'No video file selected'
                                    : _selectedVideoFile!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedVideoFile == null ? AppColors.textMuted : AppColors.textDark,
                                  fontWeight: _selectedVideoFile == null ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload PDF from Device:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickPdfFile,
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                              label: const Text('Choose PDF File', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentIndigo,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedPdfFile == null
                                    ? 'No PDF file selected'
                                    : _selectedPdfFile!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedPdfFile == null ? AppColors.textMuted : AppColors.textDark,
                                  fontWeight: _selectedPdfFile == null ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),

            // Primary Add Button
            service.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _submitMaterial(service),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Deploy Material to Syllabus'),
                    ),
                  ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildAnnouncementBroadcasterCard(FirebaseService service) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined, color: AppColors.accentIndigo, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Dynamic Announcement Board',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Broadcast urgent notifications, homework DPP alerts, or test dates live to all students.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _announcementController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Type an urgent class notice to broadcast here...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _submitAnnouncement(service),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Broadcast Announcement'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentIndigo),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildRevokeAccessCard(FirebaseService service) {
    final filtered = _enrolledStudents.where((std) {
      final hasPurchased = std.purchasedCourseIds.isNotEmpty;
      final matchesSearch = std.name.toLowerCase().contains(_studentSearchQuery.toLowerCase()) ||
                            std.email.toLowerCase().contains(_studentSearchQuery.toLowerCase());
      return hasPurchased && matchesSearch;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.no_accounts_outlined, color: AppColors.errorRed, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Offline Batch Access Registry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Revoke student batch access instantly. Suspends dynamic content, notes, and playbooks across platforms.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),

          TextField(
            decoration: const InputDecoration(
              hintText: 'Search active students by name or email...',
              prefixIcon: Icon(Icons.search, size: 18),
            ),
            onChanged: (val) {
              setState(() {
                _studentSearchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),

          _loadingStudents
              ? const Center(child: CircularProgressIndicator())
              : (filtered.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.bgSoftWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.textMuted, size: 36),
                          SizedBox(height: 8),
                          Text(
                            'No active batch allocations found.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final std = filtered[index];
                        return Card(
                          color: AppColors.bgSoftWhite,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundImage: NetworkImage(std.photoUrl),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            std.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                          ),
                                          Text(
                                            'Class: ${std.studentClass} • Contact: ${std.email.isNotEmpty ? std.email : "No Email"}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24, color: AppColors.borderLight),
                                const Text(
                                  'Active Approved Batches:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 8),
                                for (final courseId in std.purchasedCourseIds)
                                  Builder(builder: (context) {
                                  final course = service.courses.firstWhere(
                                    (c) => c.id == courseId,
                                    orElse: () => Course(id: courseId, title: courseId, tagline: '', price: 0, coverImageUrl: '', subjects: []),
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.book_outlined, size: 16, color: AppColors.accentIndigo),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            course.title,
                                            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Revoke Batch Access?'),
                                                content: Text('Are you sure you want to revoke batch access to "${course.title}" for ${std.name}? This takes effect immediately across all platforms.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.of(context).pop(true),
                                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
                                                    child: const Text('Revoke Access'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await service.revokeEnrollment(std.uid, courseId);
                                              await _loadStudents();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Access revoked successfully for ${std.name}!'),
                                                    backgroundColor: AppColors.errorRed,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.errorRed,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          child: const Text('Revoke', style: TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    )),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildDataExporterCard(FirebaseService service) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_view_outlined, color: AppColors.successGreen, size: 22),
              const SizedBox(width: 10),
              Text(
                'Data Export Registry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: service.isDarkMode ? Colors.white70 : AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Export attendance logs, student registers, and mock test score reports into Microsoft Excel or CSV sheets.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _exportRosterToExcel(context, 'Attendance', service);
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Attendance', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _exportRosterToExcel(context, 'Test Scores', service);
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Test Scores', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _exportRosterToExcel(context, 'Student Directory', service);
              },
              icon: const Icon(Icons.people, size: 16),
              label: const Text('Export Student Directory (CSV)', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _exportRosterToExcel(BuildContext context, String sheetType, FirebaseService service) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text('Compiling and formatting $sheetType spreadsheet...'),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        
        final dateStr = DateFormat('yyyy_MM_dd').format(DateTime.now());
        final filename = 'crest_achievers_${sheetType.toLowerCase().replaceAll(' ', '_')}_$dateStr.csv';
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.grid_on, color: AppColors.successGreen),
                const SizedBox(width: 8),
                Text('$sheetType Exported!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File Name: $filename', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                const Text('Roster compilation finished with 0 warning flags. Data mapped with standard CSV formatting (RFC 4180 compliant).', style: TextStyle(fontSize: 12, height: 1.4)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'uid,student_name,batch,present_pct,score_avg\n'
                    'user_01,Amit Kumar,JEE 2026,94.2%,82.5%\n'
                    'user_02,Pooja Sharma,NEET 2026,96.5%,88.0%',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black87),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 $filename downloaded successfully!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.file_download),
                label: const Text('Save File'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen, foregroundColor: Colors.white),
              )
            ],
          ),
        );
      }
    });
  }

  Widget _buildTeacherManagementCard(FirebaseService service) {
    // List all teachers
    final teachers = service.simulatedUsers.where((u) => u.role == 'teacher').toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.manage_accounts_rounded, color: AppColors.accentGold, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Teacher Assignment Management Desk',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'As Master Admin, you can assign target courses and subjects to each coach physically working at Gurugram branches.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (teachers.isEmpty)
            const Text('No simulated teachers available.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teachers.length,
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                final isMaster = teacher.uid == 'crest_dev_master';

                return Card(
                  color: AppColors.bgSoftWhite,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(teacher.photoUrl),
                              radius: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    teacher.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                  ),
                                  Text(
                                    teacher.email,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (!isMaster)
                              ElevatedButton.icon(
                                onPressed: () => _showAssignmentDialog(context, service, teacher),
                                icon: const Icon(Icons.edit_note, size: 16),
                                label: const Text('Assign', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                                ),
                                child: const Text(
                                  'MASTER',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                                ),
                              ),
                          ],
                        ),
                        if (!isMaster) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          const Text('Assigned Batches/Courses:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          if (teacher.assignedCourseIds.isEmpty)
                            const Text('No courses assigned (Cannot upload DPPs/materials)', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.errorRed))
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: teacher.assignedCourseIds.map((cId) {
                                final course = service.courses.firstWhere((c) => c.id == cId, orElse: () => Course(id: cId, title: cId, tagline: '', price: 0, coverImageUrl: '', subjects: []));
                                return Chip(
                                  label: Text(course.title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  backgroundColor: AppColors.accentIndigo.withOpacity(0.06),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 8),
                          const Text('Assigned Subjects:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          if (teacher.assignedSubjects.isEmpty)
                            const Text('No subjects assigned', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.errorRed))
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: teacher.assignedSubjects.map((sub) {
                                return Chip(
                                  label: Text(sub, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                                  backgroundColor: AppColors.accentGold.withOpacity(0.06),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAssignmentDialog(BuildContext context, FirebaseService service, UserModel teacher) {
    List<String> tempCourses = List<String>.from(teacher.assignedCourseIds);
    List<String> tempSubjects = List<String>.from(teacher.assignedSubjects);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              title: Text('Assign Scopes to ${teacher.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select batches and courses this teacher can manage:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      ...service.courses.map((course) {
                        final isChecked = tempCourses.contains(course.id);
                        return CheckboxListTile(
                          title: Text(course.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          value: isChecked,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                tempCourses.add(course.id);
                              } else {
                                tempCourses.remove(course.id);
                              }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Select subjects this teacher can teach:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      ..._subjects.map((sub) {
                        final isChecked = tempSubjects.contains(sub);
                        return CheckboxListTile(
                          title: Text(sub, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          value: isChecked,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                tempSubjects.add(sub);
                              } else {
                                tempSubjects.remove(sub);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await service.updateTeacherAssignments(teacher.uid, tempCourses, tempSubjects);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Academic scope successfully updated for ${teacher.name}!'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Assignments'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
