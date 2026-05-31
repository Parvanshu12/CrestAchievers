import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../models/course_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/notification_permission_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'student_id_screen.dart';
import 'parent_portal_screen.dart';

class AccountScreen extends StatefulWidget {
  final Function(Course) onCourseSelect;

  const AccountScreen({
    super.key,
    required this.onCourseSelect,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<UserModel> _students = [];
  bool _loadingStudents = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    final service = Provider.of<FirebaseService>(context, listen: false);
    setState(() {
      _loadingStudents = true;
    });
    final list = await service.fetchStudentDirectory();
    if (mounted) {
      setState(() {
        _students = list;
        _loadingStudents = false;
      });
    }
  }

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

    final List<String> classOptions = [
      '11th PCM',
      '12th PCM',
      'JEE Dropper',
      'NEET Aspirant',
    ];

    final bool isDeveloper = user != null &&
        (user.email.contains('8888888888') || user.uid == 'crest_dev_master');

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👤 Student Account Profile',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 24),

          // Responsive Split View (Left: Profile Info & Preferences, Right: Bought Courses list & Promoter Panel)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _buildProfileCard(context, user, service, classOptions),
                      const SizedBox(height: 24),
                      _buildGeneralInfoCard(context, service),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      _buildPurchasedCoursesList(context, service, purchasedCourses),
                      if (isDeveloper) ...[
                        const SizedBox(height: 24),
                        _buildDeveloperPromoterCard(context, service),
                      ],
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _buildProfileCard(context, user, service, classOptions),
            const SizedBox(height: 24),
            _buildPurchasedCoursesList(context, service, purchasedCourses),
            if (isDeveloper) ...[
              const SizedBox(height: 24),
              _buildDeveloperPromoterCard(context, service),
            ],
            const SizedBox(height: 24),
            _buildGeneralInfoCard(context, service),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    UserModel? user,
    FirebaseService service,
    List<String> classOptions,
  ) {
    final name = user?.name ?? 'Guest Achiever';
    final email = user?.email ?? 'student@crestachievers.com';
    final studentClass = user?.studentClass ?? '12th PCM';
    final photoUrl = user?.photoUrl ?? 'https://api.dicebear.com/7.x/bottts/png?seed=guest';
    final role = user?.role ?? 'student';

    // Preset Avatar Options
    final List<String> avatarPresets = [
      'https://api.dicebear.com/7.x/bottts/png?seed=tech',
      'https://api.dicebear.com/7.x/pixel-art/png?seed=creative',
      'https://api.dicebear.com/7.x/avataaars/png?seed=astro',
      'https://api.dicebear.com/7.x/adventurer/png?seed=stud',
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
            backgroundImage: NetworkImage(photoUrl),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'C',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Presets row selection
          const Text('Select Study Avatar Preset:', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: avatarPresets.map((preset) {
              final isSel = photoUrl == preset;
              return InkWell(
                onTap: () => service.updateProfilePicture(preset),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel ? AppColors.primaryBlue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.bgSoftWhite,
                      backgroundImage: NetworkImage(preset),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
          ),
          Text(
            email,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (role == 'teacher' ? AppColors.accentIndigo : AppColors.primaryBlue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: role == 'teacher' ? AppColors.accentIndigo : AppColors.primaryBlue,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 20),

          // Standard class dropdown selector
          DropdownButtonFormField<String>(
            value: classOptions.contains(studentClass) ? studentClass : classOptions.first,
            decoration: const InputDecoration(
              labelText: 'Update Category / Class',
              prefixIcon: Icon(Icons.school_outlined, size: 18),
            ),
            items: classOptions.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val),
              );
            }).toList(),
            onChanged: (newVal) {
              if (newVal != null) {
                service.changeStudentClass(newVal);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Target class updated to $newVal!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 32),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => service.signOut(),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign Out Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.errorRed),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildPurchasedCoursesList(
    BuildContext context,
    FirebaseService service,
    List<Course> courses,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💳 My Purchased Coaching Courses',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Click on any purchased course below to instantly view syllabus contents and resume studying.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          if (courses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    const Icon(Icons.credit_card_off_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    const Text('No purchased courses found.', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Courses you buy in the Shop will appear here.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                
                // Calculate course progress
                int totalChapters = 0;
                double progressSum = 0.0;
                for (var sub in course.subjects) {
                  for (var ch in sub.chapters) {
                    totalChapters++;
                    progressSum += service.getChapterProgress(ch);
                  }
                }
                double overallProgress = totalChapters > 0 ? progressSum / totalChapters : 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        course.coverImageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 56,
                          height: 56,
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          child: const Icon(Icons.school, color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    title: Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Syllabus progress: ${(overallProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: overallProgress,
                          color: AppColors.primaryBlue,
                          backgroundColor: AppColors.borderLight,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                    onTap: () => widget.onCourseSelect(course),
                  ),
                );
              },
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  // --- Developer Promoter Console Card (NEW) ---
  Widget _buildDeveloperPromoterCard(BuildContext context, FirebaseService service) {
    final filteredStudents = _students.where((std) {
      return std.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined, color: AppColors.accentIndigo, size: 24),
              const SizedBox(width: 8),
              const Text(
                '🛠️ Developer: Promote User Roles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Exclusively unlocked for Developer Master (8888888888). Search and convert any registered student into a teacher instantly.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search student by name to promote...',
              prefixIcon: Icon(Icons.search, size: 18),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
          
          _loadingStudents
              ? const Center(child: CircularProgressIndicator())
              : (filteredStudents.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No students found', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final std = filteredStudents[index];
                        final isTeacher = std.role == 'teacher';
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: AppColors.bgSoftWhite,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
                                  backgroundImage: NetworkImage(std.photoUrl),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        std.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                      ),
                                      Text(
                                        std.studentClass,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      isTeacher ? 'TEACHER' : 'STUDENT',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isTeacher ? AppColors.accentIndigo : AppColors.primaryBlue,
                                      ),
                                    ),
                                    Switch(
                                      value: isTeacher,
                                      activeColor: AppColors.accentIndigo,
                                      onChanged: (val) async {
                                        final newRole = val ? 'teacher' : 'student';
                                        await service.promoteUserRole(std.uid, newRole);
                                        await _loadDirectory(); // Reload local list
                                        
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${std.name} promoted to ${newRole.toUpperCase()}!'),
                                              backgroundColor: AppColors.successGreen,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
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

  Widget _buildGeneralInfoCard(BuildContext context, FirebaseService service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ App Settings & Customizations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
          ),
          const SizedBox(height: 20),

          // Dark Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.dark_mode_outlined, size: 18, color: AppColors.textMuted),
                  SizedBox(width: 12),
                  Text('Dark Mode Theme', style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                ],
              ),
              Switch(
                value: service.isDarkMode,
                onChanged: (val) async {
                  await service.toggleDarkMode();
                },
                activeColor: AppColors.accentGold,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Language Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.language_outlined, size: 18, color: AppColors.textMuted),
                  SizedBox(width: 12),
                  Text('App Language', style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                ],
              ),
              DropdownButton<String>(
                value: service.language,
                dropdownColor: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                items: ['English', 'Hindi'].map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    service.setLanguage(val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Language switched to $val!'), duration: const Duration(seconds: 1)),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 16),

          // Action Buttons: ID, Parent Link, Share
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => StudentIdScreen(student: service.currentUser)),
                );
              },
              icon: const Icon(Icons.badge_outlined, size: 16),
              label: const Text('View My Digital ID Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ParentPortalScreen()),
                );
              },
              icon: const Icon(Icons.family_restroom_outlined, size: 16),
              label: const Text('Parent Portal & Family Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryNavy,
                side: const BorderSide(color: AppColors.primaryNavy),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton.icon(
              onPressed: () {
                Share.share(service.getShareText());
              },
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Share App Referral Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentGold,
              ),
            ),
          ),

          const Divider(color: AppColors.borderLight, height: 32),
          const Text(
            '🔔 Push Notification Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Browser & App Alerts', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final status = await requestWebNotificationPermission();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(status == 'granted' 
                            ? 'App-level notification permission granted successfully!'
                            : 'App-level notification permission requested: $status'),
                        backgroundColor: status == 'granted' 
                            ? AppColors.successGreen 
                            : AppColors.warningOrange,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagRow(IconData icon, String label, String value, Color statusColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
