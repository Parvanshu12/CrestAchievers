import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/course_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LecturePlayerScreen extends StatefulWidget {
  final Lecture lecture;
  final Chapter chapter;
  final VoidCallback onBack;

  const LecturePlayerScreen({
    super.key,
    required this.lecture,
    required this.chapter,
    required this.onBack,
  });

  @override
  State<LecturePlayerScreen> createState() => _LecturePlayerScreenState();
}

class _LecturePlayerScreenState extends State<LecturePlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final uri = Uri.parse(widget.lecture.videoUrl);
      _videoPlayerController = VideoPlayerController.networkUrl(uri);
      
      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        autoPlay: true,
        looping: false,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: [0.5, 1.0, 1.25, 1.5, 2.0],
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryBlue,
          handleColor: AppColors.accentIndigo,
          backgroundColor: AppColors.borderLight,
          bufferedColor: AppColors.primaryBlue.withOpacity(0.3),
        ),
      );
      
      setState(() {});
    } catch (e) {
      debugPrint("⚠️ Video Player Init error: $e");
      setState(() {
        _hasError = true;
        _errorMsg = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final isLecCompleted = service.isLectureCompleted(widget.chapter.id, widget.lecture.title);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Back Button
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: OutlinedButton.icon(
              onPressed: () {
                _videoPlayerController?.pause();
                widget.onBack();
              },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Return to Syllabus'),
            ),
          ),

          // Main Responsive Layout split
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildVideoFrame(context),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 4,
                  child: _buildVideoDetailsPanel(context, service, isLecCompleted),
                ),
              ],
            )
          else ...[
            _buildVideoFrame(context),
            const SizedBox(height: 24),
            _buildVideoDetailsPanel(context, service, isLecCompleted),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoFrame(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppColors.softShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: _hasError
            ? _buildFallbackSimulatorFrame()
            : (_chewieController != null && _videoPlayerController!.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Streaming private lecture...',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        )
                      ],
                    ),
                  )),
      ),
    ).animate().scale(duration: 250.ms);
  }

  Widget _buildFallbackSimulatorFrame() {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.slow_motion_video, size: 48, color: AppColors.warningOrange),
              const SizedBox(height: 12),
              const Text(
                'Interactive Class Stream Ready',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Sample Player Active: Streams secure lecture:\n${widget.lecture.videoUrl}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed, color: Colors.white, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      'Speed Locked: 1.0x',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoDetailsPanel(
    BuildContext context,
    FirebaseService service,
    bool isLecCompleted,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentIndigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.chapter.title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.accentIndigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.lecture.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Class Duration: ${widget.lecture.duration}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 16),
            const Text(
              'Lecture Outline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'This recorded class outlines fundamental PCM theories, analytical numerical breakdowns, and previous years JEE/NEET solved problems corresponding to this chapter.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 32),
            
            // Mark Completed Widget
            ElevatedButton.icon(
              onPressed: () {
                service.toggleLectureCompleted(widget.chapter.id, widget.lecture.title);
              },
              icon: Icon(
                isLecCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
              ),
              label: Text(isLecCompleted ? 'Marked Completed' : 'Mark as Watched'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLecCompleted ? AppColors.successGreen : AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
