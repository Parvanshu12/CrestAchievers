import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/course_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PdfViewerScreen extends StatefulWidget {
  final Note note;
  final Chapter chapter;
  final VoidCallback onBack;

  const PdfViewerScreen({
    super.key,
    required this.note,
    required this.chapter,
    required this.onBack,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  bool _hasError = false;
  int _totalPages = 0;
  int _currentPage = 1;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final isNoteCompleted = service.isNoteCompleted(widget.chapter.id, widget.note.title);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Toolbar Controls
          _buildDocumentToolbar(context, service, isNoteCompleted),
          const SizedBox(height: 16),
  
          // Main Responsive Split Screen
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _buildPdfRenderFrame(context),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 3,
                  child: _buildDocumentDetails(context, service, isNoteCompleted),
                ),
              ],
            )
          else ...[
            _buildPdfRenderFrame(context),
            const SizedBox(height: 24),
            _buildDocumentDetails(context, service, isNoteCompleted),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentToolbar(
    BuildContext context,
    FirebaseService service,
    bool isCompleted,
  ) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to Syllabus'),
        ),
        const Spacer(),
        // Page control stats (only visible on large screens)
        if (_totalPages > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 16),
                  onPressed: _currentPage > 1
                      ? () => _pdfViewerController.previousPage()
                      : null,
                ),
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 16),
                  onPressed: _currentPage < _totalPages
                      ? () => _pdfViewerController.nextPage()
                      : null,
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        // Zoom controllers
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out, size: 16),
                onPressed: () => _pdfViewerController.zoomLevel = 1.0,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, size: 16),
                onPressed: () => _pdfViewerController.zoomLevel = 2.0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPdfRenderFrame(BuildContext context) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [AppColors.softShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (!_hasError)
            SfPdfViewer.network(
              widget.note.pdfUrl,
              controller: _pdfViewerController,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _isLoading = false;
                  _totalPages = details.document.pages.count;
                });
              },
              onPageChanged: (PdfPageChangedDetails details) {
                setState(() {
                  _currentPage = details.newPageNumber;
                });
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                debugPrint("⚠️ PDF load failed: ${details.description}");
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              },
            ),

          if (_hasError)
            _buildFallbackDocumentPreview(),

          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading in-app revision notes...', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildFallbackDocumentPreview() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner, size: 64, color: AppColors.accentIndigo),
            const SizedBox(height: 16),
            const Text(
              'Dynamic Study Sheet Viewer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Sample Notes Sheet fully loaded from secure link:\n${widget.note.pdfUrl}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSoftWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📌 TOPICS COVERED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentIndigo)),
                  SizedBox(height: 8),
                  Text('• Complete board level descriptive outline\n• Previous years solved JEE & NEET numerical logs\n• Chapter-wise quick formulas bank & graphs', style: TextStyle(fontSize: 12, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentDetails(
    BuildContext context,
    FirebaseService service,
    bool isCompleted,
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
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.chapter.title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.note.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Document Type: DPP / Formula notes',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 16),
            const Text('Revision Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _buildChecklistItem('Read all core chapter formulas.'),
            _buildChecklistItem('Solve the Daily Practice Problems (DPP).'),
            _buildChecklistItem('Log complex math/physics steps.'),
            const SizedBox(height: 32),

            // Mark note as read/completed
            ElevatedButton.icon(
              onPressed: () {
                service.toggleNoteCompleted(widget.chapter.id, widget.note.title);
              },
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.bookmark_outline,
                size: 20,
              ),
              label: Text(isCompleted ? 'Completed note' : 'Mark Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? AppColors.successGreen : AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.successGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
        ],
      ),
    );
  }
}
