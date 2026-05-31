// © Copyright 2026 parvanshu. All rights reserved.
// This application codebase was designed, developed, and optimized by parvanshu.
// Unauthorized copying, reuse, or distribution of this code is strictly regulated.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';

class DoubtForumScreen extends StatefulWidget {
  final String studentUid;
  const DoubtForumScreen({super.key, required this.studentUid});

  @override
  State<DoubtForumScreen> createState() => _DoubtForumScreenState();
}

class _DoubtForumScreenState extends State<DoubtForumScreen> {
  final TextEditingController _doubtController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  String _selectedSubject = 'Physics';
  bool _isPosting = false;

  @override
  void dispose() {
    _doubtController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitDoubt() async {
    if (_doubtController.text.trim().isEmpty) return;
    
    setState(() => _isPosting = true);
    final service = Provider.of<FirebaseService>(context, listen: false);
    final user = service.currentUser;

    final doubt = DoubtPost(
      id: 'doubt_${DateTime.now().millisecondsSinceEpoch}',
      studentUid: user?.uid ?? 'anonymous',
      studentName: user?.name ?? 'Student',
      subject: _selectedSubject,
      questionText: _doubtController.text.trim(),
      replies: [],
      timestamp: DateTime.now().toIso8601String(),
      isResolved: false,
      batch: user?.studentClass ?? 'JEE 2026',
    );

    await service.postDoubt(doubt);
    
    _doubtController.clear();
    setState(() => _isPosting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doubt posted to community board!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);

    return Scaffold(
      backgroundColor: service.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Doubt Resolution Board', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Posting Input
          _buildPostFormCard(service),
          const Divider(height: 1),

          // Stream list
          Expanded(
            child: StreamBuilder<List<DoubtPost>>(
              stream: service.getDoubtsStream(),
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('No active doubts found on the board.', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final d = list[index];
                    return _buildDoubtCard(context, service, d);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPostFormCard(FirebaseService service) {
    return Container(
      color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Select Subject',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: ['Physics', 'Chemistry', 'Mathematics', 'Biology']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSubject = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  height: 48,
                  child: Text(
                    'Class: ${service.currentUser?.studentClass ?? "JEE 2026"}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold, fontSize: 13),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _doubtController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Type your doubt here... e.g. How to solve question 4 from DPP regarding torque?',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _submitDoubt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPosting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Icon(Icons.send),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDoubtCard(BuildContext context, FirebaseService service, DoubtPost d) {
    final formattedDate = DateFormat('dd MMM, hh:mm a').format(DateTime.parse(d.timestamp));
    final isTeacher = service.currentUser?.role == 'teacher';
    final subColor = _getSubjectColor(d.subject);

    return Card(
      color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: subColor.withOpacity(0.12),
                      child: Text(
                        d.studentName.substring(0, 1).toUpperCase(),
                        style: TextStyle(color: subColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.studentName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: subColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        d.subject,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: subColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: d.isResolved 
                            ? AppColors.successGreen.withOpacity(0.12) 
                            : AppColors.warningOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        d.isResolved ? 'RESOLVED' : 'PENDING',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 10, 
                          color: d.isResolved ? AppColors.successGreen : AppColors.warningOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question Description
            Text(
              d.questionText,
              style: TextStyle(
                fontSize: 14, 
                height: 1.4,
                color: service.isDarkMode ? Colors.white70 : AppColors.primaryNavy,
              ),
            ),

            // Replies Segment
            if (d.replies.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(thickness: 0.5),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: d.replies.length,
                itemBuilder: (context, rIdx) {
                  final reply = d.replies[rIdx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: reply.isTeacher 
                            ? AppColors.accentGold.withOpacity(0.06) 
                            : (service.isDarkMode ? const Color(0xFF374151).withOpacity(0.5) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                reply.replierName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 11,
                                  color: reply.isTeacher ? AppColors.accentGold : AppColors.textDark,
                                ),
                              ),
                              if (reply.isTeacher)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGold,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('FACULTY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(reply.text, style: const TextStyle(fontSize: 12, height: 1.3)),
                        ],
                      ),
                    ),
                  );
                },
              )
            ],

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    maxChildSize: 0.95,
                    minChildSize: 0.5,
                    builder: (context, scrollController) => DoubtWorkspaceSheet(
                      doubtId: d.id,
                      scrollController: scrollController,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.psychology, color: AppColors.accentGold, size: 16),
              label: const Text('Explanations Workspace (Voice & Drawings)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.accentGold.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),

            // Action: Answer / Reply
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: isTeacher ? 'Type official faculty resolution...' : 'Add a helpful comment or reply...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.reply, color: AppColors.primaryNavy),
                  onPressed: () async {
                    if (_replyController.text.trim().isEmpty) return;
                    
                    final r = DoubtReply(
                       replierName: service.currentUser?.name ?? 'Anonymous Responder',
                       text: _replyController.text.trim(),
                       isTeacher: isTeacher,
                       timestamp: DateTime.now().toIso8601String(),
                    );

                    await service.replyToDoubt(d.id, r);
                    _replyController.clear();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isTeacher ? 'Faculty answer posted!' : 'Comment added!'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    }
                  },
                )
              ],
            )
          ],
        ),
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
}

// ────────────────────────────────────────────────────────────────────────────
// Doubt Resolution Workspace Drawer Sheet
// ────────────────────────────────────────────────────────────────────────────
class DoubtWorkspaceSheet extends StatefulWidget {
  final String doubtId;
  final ScrollController scrollController;
  const DoubtWorkspaceSheet({super.key, required this.doubtId, required this.scrollController});

  @override
  State<DoubtWorkspaceSheet> createState() => _DoubtWorkspaceSheetState();
}

class _DoubtWorkspaceSheetState extends State<DoubtWorkspaceSheet> {
  final TextEditingController _textController = TextEditingController();
  
  // Audio Recording states (Simulated)
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  List<double> _recordWaves = [];

  // Active Playback tracking
  String? _playingReplyIndex;
  double _playbackProgress = 0.0;
  Timer? _playbackTimer;

  @override
  void dispose() {
    _textController.dispose();
    _recordTimer?.cancel();
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
      _recordWaves = List.generate(24, (_) => 5.0 + math.Random().nextDouble() * 20.0);
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordSeconds++;
        _recordWaves = List.generate(24, (_) => 5.0 + math.Random().nextDouble() * 25.0);
      });
    });
  }

  void _stopAndSendRecording(FirebaseService service, DoubtPost doubt) async {
    _recordTimer?.cancel();
    final secs = _recordSeconds;
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });

    if (secs < 1) return;

    final durationString = "${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}";
    final isTeacher = service.currentUser?.role == 'teacher';

    final r = DoubtReply(
      replierName: service.currentUser?.name ?? 'Teacher explainer',
      text: '🎙️ Voice note explanation (${durationString})',
      isTeacher: isTeacher,
      timestamp: DateTime.now().toIso8601String(),
      voiceUrl: 'mock_voice_${DateTime.now().millisecondsSinceEpoch}.mp3',
      voiceDuration: durationString,
    );

    await service.replyToDoubt(doubt.id, r);
    _scrollDown();
  }

  void _openSketchpad(BuildContext context, FirebaseService service, DoubtPost doubt) {
    showDialog(
      context: context,
      builder: (context) => InteractiveSketchpadDialog(
        onSave: (points) async {
          final isTeacher = service.currentUser?.role == 'teacher';
          final r = DoubtReply(
            replierName: service.currentUser?.name ?? 'Scholar responder',
            text: '🎨 Sketched diagram overlay',
            isTeacher: isTeacher,
            timestamp: DateTime.now().toIso8601String(),
            canvasUrl: 'mock_sketch_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await service.replyToDoubt(doubt.id, r);
          _scrollDown();
        },
      ),
    );
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _playVoiceNote(String key) {
    _playbackTimer?.cancel();
    if (_playingReplyIndex == key) {
      setState(() {
        _playingReplyIndex = null;
        _playbackProgress = 0.0;
      });
      return;
    }

    setState(() {
      _playingReplyIndex = key;
      _playbackProgress = 0.0;
    });

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        _playbackProgress += 0.05;
        if (_playbackProgress >= 1.0) {
          _playingReplyIndex = null;
          _playbackProgress = 0.0;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    return StreamBuilder<List<DoubtPost>>(
      stream: service.getDoubtsStream(),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        final doubt = list.firstWhere((d) => d.id == widget.doubtId, orElse: () => DoubtPost(id: '', studentUid: '', studentName: '', subject: '', questionText: '', replies: [], timestamp: DateTime.now().toIso8601String(), isResolved: false, batch: ''));
        
        if (doubt.id.isEmpty) {
          return Container(
            color: Colors.white,
            child: const Center(child: Text('Doubt thread closed.')),
          );
        }

        final isTeacher = service.currentUser?.role == 'teacher';

        return Container(
          decoration: BoxDecoration(
            color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drawer Handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Doubt Workspace: ${doubt.studentName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Original Doubt Description Card
              Expanded(
                child: ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: service.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: service.isDarkMode ? Colors.white10 : AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(doubt.subject, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              const SizedBox(width: 8),
                              Text('Student: ${doubt.studentName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(doubt.questionText, style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Replies Timeline
                    ...doubt.replies.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final r = entry.value;
                      final isVoice = r.voiceUrl != null;
                      final isCanvas = r.canvasUrl != null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Align(
                          alignment: r.isTeacher ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: r.isTeacher 
                                  ? AppColors.primaryBlue.withOpacity(0.1) 
                                  : (service.isDarkMode ? const Color(0xFF374151) : Colors.white),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: r.isTeacher 
                                    ? AppColors.primaryBlue.withOpacity(0.2) 
                                    : (service.isDarkMode ? Colors.white10 : AppColors.borderLight),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(r.replierName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: r.isTeacher ? AppColors.primaryBlue : AppColors.accentGold)),
                                    if (r.isTeacher) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('FACULTY', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // If Voice Note
                                if (isVoice) ...[
                                  _buildVoicePlayerWidget(idx.toString(), r.voiceDuration ?? '0:10'),
                                ]
                                // If Canvas annotated diagram
                                else if (isCanvas) ...[
                                  _buildCanvasThumbnailWidget(context, r.replierName),
                                ]
                                // Else plain text
                                else ...[
                                  Text(r.text, style: const TextStyle(fontSize: 13, height: 1.3)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Recording Panel (If Recording Active)
              if (_isRecording)
                Container(
                  color: service.isDarkMode ? const Color(0xFF111827) : const Color(0xFFFFFBEB),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.mic, color: AppColors.errorRed, size: 24).animate(onPlay: (c) => c.repeat()).fadeIn().scale(),
                      const SizedBox(width: 12),
                      Text(
                        'Recording simulated explainer... ${(_recordSeconds ~/ 60)}:${(_recordSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.errorRed),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _recordWaves.map((h) => Container(width: 2.5, height: h, decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(1)))).toList(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: AppColors.textMuted),
                        onPressed: () {
                          _recordTimer?.cancel();
                          setState(() {
                            _isRecording = false;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: AppColors.successGreen, size: 28),
                        onPressed: () => _stopAndSendRecording(service, doubt),
                      ),
                    ],
                  ),
                ),

              // Bottom Input Workspace Bar
              Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 12),
                color: service.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
                child: Row(
                  children: [
                    // Dynamic drawing board tool
                    IconButton(
                      icon: const Icon(Icons.brush, color: AppColors.accentGold),
                      tooltip: 'Annotated sketchpad explainer',
                      onPressed: () => _openSketchpad(context, service, doubt),
                    ),
                    // Voice recorder tool
                    IconButton(
                      icon: const Icon(Icons.mic_none_outlined, color: AppColors.primaryBlue),
                      tooltip: 'Record audio voice explainer',
                      onPressed: _isRecording ? null : _startRecording,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Type text reply...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primaryNavy),
                      onPressed: () async {
                        if (_textController.text.trim().isEmpty) return;
                        final r = DoubtReply(
                          replierName: service.currentUser?.name ?? 'Scholar responder',
                          text: _textController.text.trim(),
                          isTeacher: isTeacher ?? false,
                          timestamp: DateTime.now().toIso8601String(),
                        );
                        await service.replyToDoubt(doubt.id, r);
                        _textController.clear();
                        _scrollDown();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoicePlayerWidget(String key, String duration) {
    final isPlaying = _playingReplyIndex == key;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: AppColors.primaryBlue, size: 36),
            onPressed: () => _playVoiceNote(key),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Voice Explanation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 2),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: isPlaying ? _playbackProgress : 0.0,
                      backgroundColor: Colors.grey.shade300,
                      color: AppColors.primaryBlue,
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(duration, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasThumbnailWidget(BuildContext context, String author) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Annotated Canvas Explainer by $author', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 350,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: CustomPaint(
                          painter: SketchpadMockGraphicPainter(),
                          size: Size.infinite,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Use pinch gestures to zoom and pan the mathematical diagram overlay.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: CustomPaint(
                painter: SketchpadMockGraphicPainter(),
                size: const Size(180, 110),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.zoom_in, size: 12, color: AppColors.primaryBlue),
                SizedBox(width: 4),
                Text('Tap to expand equation canvas', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Draw sketch points
// ────────────────────────────────────────────────────────────────────────────
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  DrawingStroke({required this.points, required this.color, required this.strokeWidth});
}

class InteractiveSketchpadDialog extends StatefulWidget {
  final Function(List<DrawingStroke>) onSave;
  const InteractiveSketchpadDialog({super.key, required this.onSave});

  @override
  State<InteractiveSketchpadDialog> createState() => _InteractiveSketchpadDialogState();
}

class _InteractiveSketchpadDialogState extends State<InteractiveSketchpadDialog> {
  List<DrawingStroke> _strokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.5;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 520,
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.brush, color: AppColors.accentGold),
                    SizedBox(width: 8),
                    Text('Canvas Explanations Editor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 8),
            
            // Color and Brush Controls
            Row(
              children: [
                const Text('Ink Color: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                ...[Colors.red, Colors.blue, Colors.green, Colors.black].map((c) => Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedColor = c),
                    child: CircleAvatar(
                      radius: _selectedColor == c ? 13 : 10,
                      backgroundColor: c,
                      child: _selectedColor == c ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                    ),
                  ),
                )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.undo, color: AppColors.primaryBlue),
                  onPressed: () {
                    if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
                  },
                  tooltip: 'Undo stroke',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.errorRed),
                  onPressed: () => setState(() => _strokes.clear()),
                  tooltip: 'Clear Canvas',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Drawing Area
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: const Color(0xFFFAFBFD),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _currentPoints = [details.localPosition];
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _currentPoints.add(details.localPosition);
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                        _strokes.add(DrawingStroke(
                          points: List.from(_currentPoints),
                          color: _selectedColor,
                          strokeWidth: _strokeWidth,
                        ));
                        _currentPoints.clear();
                      });
                    },
                    child: CustomPaint(
                      painter: RealSketchpadPainter(strokes: _strokes, activePoints: _currentPoints, activeColor: _selectedColor, activeWidth: _strokeWidth),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(_strokes);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
                    child: const Text('Attach Diagram', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Painters
// ────────────────────────────────────────────────────────────────────────────
class RealSketchpadPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> activePoints;
  final Color activeColor;
  final double activeWidth;

  RealSketchpadPainter({required this.strokes, required this.activePoints, required this.activeColor, required this.activeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw past strokes
    for (var stroke in strokes) {
      paint.color = stroke.color;
      paint.strokeWidth = stroke.strokeWidth;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    // Draw active stroke
    if (activePoints.length > 1) {
      paint.color = activeColor;
      paint.strokeWidth = activeWidth;
      for (int i = 0; i < activePoints.length - 1; i++) {
        canvas.drawLine(activePoints[i], activePoints[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SketchpadMockGraphicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pRed = Paint()..color = Colors.red..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final pBlue = Paint()..color = Colors.blue..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final pAxis = Paint()..color = Colors.black45..strokeWidth = 1.5..style = PaintingStyle.stroke;

    // Center Coordinate Axes
    canvas.drawLine(Offset(20, size.height / 2 + 10), Offset(size.width - 20, size.height / 2 + 10), pAxis);
    canvas.drawLine(Offset(size.width / 2, 20), Offset(size.width / 2, size.height - 20), pAxis);

    // Draw a mathematical sine wave curve
    final pathWave = Path();
    pathWave.moveTo(20, size.height / 2 + 10);
    for (double x = 20; x < size.width - 20; x++) {
      final y = size.height / 2 + 10 - 35 * math.sin((x - size.width / 2) * 0.05);
      pathWave.lineTo(x, y);
    }
    canvas.drawPath(pathWave, pBlue);

    // Draw a geometric triangle and angle arcs
    canvas.drawLine(Offset(size.width / 2 - 30, size.height / 2 - 20), Offset(size.width / 2 + 40, size.height / 2 - 20), pRed);
    canvas.drawLine(Offset(size.width / 2 - 30, size.height / 2 - 20), Offset(size.width / 2, 35), pRed);
    canvas.drawLine(Offset(size.width / 2, 35), Offset(size.width / 2 + 40, size.height / 2 - 20), pRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
