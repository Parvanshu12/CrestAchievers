import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firebase_service.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';

class StudentIdScreen extends StatefulWidget {
  final UserModel? student;
  const StudentIdScreen({super.key, this.student});

  @override
  State<StudentIdScreen> createState() => _StudentIdScreenState();
}

class _StudentIdScreenState extends State<StudentIdScreen> {
  double _rotationAngle = 0; // 3D flip angle track

  void _shareIdCard(UserModel user, FirebaseService service) {
    final branchId = service.getBranchIdForStudent(user.uid);
    final text = 'Crest Achievers Virtual ID Card\n\n'
        'Name: ${user.name}\n'
        'Student ID: ${user.uid.substring(0, 8).toUpperCase()}\n'
        'Standard: ${user.studentClass}\n'
        'Target: ${user.studentClass}\n'
        'Branch: ${branchId == 'sector_56' ? 'Sector 56 Branch' : 'Sector 14 Branch'}\n\n'
        'Crest Achievers hybrid coaching center.';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final activeStudent = widget.student ?? service.currentUser;

    if (activeStudent == null) {
      return const Scaffold(
        body: Center(child: Text('Student profile not found.')),
      );
    }

    final uidUpper = activeStudent.uid.substring(0, 8).toUpperCase();
    final branchId = service.getBranchIdForStudent(activeStudent.uid);
    final branchStr = branchId == 'sector_56' ? 'Sector 56 Branch, Gurugram' : 'Sector 14 Branch, Gurugram';

    return Scaffold(
      backgroundColor: service.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Digital Student ID', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Virtual flippable 3D ID Card
              GestureDetector(
                onTap: () {
                  setState(() {
                    _rotationAngle = _rotationAngle == 0 ? 3.14159 : 0;
                  });
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _rotationAngle),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  builder: (context, val, child) {
                    final isBack = val >= 3.14159 / 2;
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // perspective mapping
                        ..rotateY(val),
                      alignment: Alignment.center,
                      child: isBack
                          ? Transform(
                              transform: Matrix4.identity()..rotateY(3.14159),
                              alignment: Alignment.center,
                              child: _buildIdCardBackSide(service, activeStudent, uidUpper, branchStr),
                            )
                          : _buildIdCardFrontSide(service, activeStudent, uidUpper, branchStr),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              // Animated Micro-hint indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flip_camera_android, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'TAP CARD TO FLIP IN 3D',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted.withOpacity(0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: 240,
                child: ElevatedButton.icon(
                  onPressed: () => _shareIdCard(activeStudent, service),
                  icon: const Icon(Icons.share),
                  label: const Text('Share Digital ID', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdCardFrontSide(FirebaseService service, UserModel activeStudent, String uidUpper, String branchStr) {
    return Card(
      elevation: 12,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: service.isDarkMode
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [AppColors.primaryNavy, const Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white.withOpacity(0.05),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: AppColors.accentGold, size: 24),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CREST ACHIEVERS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'HYBRID LEARNING CENTER',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                    ),
                  )
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Student Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.accentGold.withOpacity(0.2),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.accentGold.withOpacity(0.1),
                      child: Text(
                        activeStudent.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    activeStudent.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'STUDENT ID: $uidUpper',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white60,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 18),

                  // Info grid
                  _buildInfoRow('STANDARD', activeStudent.studentClass),
                  const SizedBox(height: 10),
                  _buildInfoRow('TARGET BATCH', activeStudent.studentClass),
                  const SizedBox(height: 10),
                  _buildInfoRow('CENTER BRANCH', branchStr),
                  const SizedBox(height: 20),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: 'crest_student_${activeStudent.uid}',
                      version: QrVersions.auto,
                      size: 90.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdCardBackSide(FirebaseService service, UserModel activeStudent, String uidUpper, String branchStr) {
    return Card(
      elevation: 12,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: service.isDarkMode
                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Back Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white.withOpacity(0.03),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.accentGold, size: 20),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CREST ACHIEVERS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'OFFICIAL INSTITUTIONAL RECORD',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Back Body
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'EMERGENCY INSTRUCTIONS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Detail fields
                  _buildInfoRow('PARENT CONTACT', '+91 98765 43210'),
                  const SizedBox(height: 10),
                  _buildInfoRow('BLOOD GROUP', 'O + Positive'),
                  const SizedBox(height: 10),
                  _buildInfoRow('BATCH INDEX', 'CREST-JEE-2026-A'),
                  const SizedBox(height: 10),
                  _buildInfoRow('OFFLINE ID', activeStudent.uid.substring(0, 12).toUpperCase()),
                  const SizedBox(height: 10),
                  _buildInfoRow('ADMISSION DATE', '12 April 2026'),
                  
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 24),

                  // Simulated Barcode
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(42, (idx) {
                        // Alternate thin and thick bars to look like a real barcode
                        final isThick = idx % 3 == 0 || idx % 7 == 0;
                        final isSpacer = idx % 5 == 0;
                        return Container(
                          width: isSpacer ? 2 : (isThick ? 3.5 : 1.5),
                          color: isSpacer ? Colors.transparent : Colors.black87,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '* $uidUpper *',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white60),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}
