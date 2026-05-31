import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';

class ParentPortalScreen extends StatefulWidget {
  const ParentPortalScreen({super.key});

  @override
  State<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends State<ParentPortalScreen> {
  final TextEditingController _targetController = TextEditingController();
  List<UserModel> _linkedProfiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLinkedProfiles();
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _fetchLinkedProfiles() async {
    setState(() => _isLoading = true);
    final service = Provider.of<FirebaseService>(context, listen: false);
    final user = service.currentUser;
    if (user == null) return;

    if (user.role == 'parent') {
      final list = await service.getChildrenForParent(user.uid);
      setState(() {
        _linkedProfiles = list;
        _isLoading = false;
      });
    } else {
      final list = await service.getParentsForStudent(user.uid);
      setState(() {
        _linkedProfiles = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _linkProfile() async {
    final searchVal = _targetController.text.trim();
    if (searchVal.isEmpty) return;

    setState(() => _isLoading = true);
    final service = Provider.of<FirebaseService>(context, listen: false);
    final user = service.currentUser!;

    // Find student or parent by email/UID in simulated users first
    final target = service.simulatedUsers.firstWhere(
      (u) => u.email.toLowerCase() == searchVal.toLowerCase() || u.uid == searchVal,
      orElse: () => UserModel(uid: '', name: '', email: '', studentClass: '', photoUrl: '', purchasedCourseIds: [], role: ''),
    );

    if (target.uid.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target profile not found. Please double check the email or User ID.')),
      );
      return;
    }

    if (user.role == 'parent') {
      if (target.role != 'student') {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only link parent accounts to student profiles.')),
        );
        return;
      }
      await service.linkParentToChild(parentUid: user.uid, childUid: target.uid);
    } else {
      if (target.role != 'parent') {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Students can only link parent accounts.')),
        );
        return;
      }
      await service.linkParentToChild(parentUid: target.uid, childUid: user.uid);
    }

    _targetController.clear();
    await _fetchLinkedProfiles();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profiles successfully linked!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _unlinkProfile(String targetUid) async {
    setState(() => _isLoading = true);
    final service = Provider.of<FirebaseService>(context, listen: false);
    final user = service.currentUser!;

    if (user.role == 'parent') {
      await service.unlinkParentFromChild(parentUid: user.uid, childUid: targetUid);
    } else {
      await service.unlinkParentFromChild(parentUid: targetUid, childUid: user.uid);
    }

    await _fetchLinkedProfiles();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link revoked successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final user = service.currentUser;
    final isParent = user?.role == 'parent';

    return Scaffold(
      backgroundColor: service.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isParent ? 'Manage Linked Children' : 'Linked Parent Accounts', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Explanation Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.family_restroom, color: AppColors.accentGold, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isParent ? 'Multi-Child Link Matrix' : 'Multi-Parent Accountability',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isParent 
                                    ? 'Crest Achievers supports linking multiple children to one parent, and multiple parent accounts (e.g. Mother and Father) to a child.'
                                    : 'Share your progress. You can link multiple parent profiles so they both can monitor your grades, attendance, and fee status.',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Link Form
                  Text(
                    isParent ? 'Link a Child Student Profile' : 'Link a Parent Profile',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: service.isDarkMode ? Colors.white70 : AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _targetController,
                          decoration: InputDecoration(
                            hintText: isParent ? 'Enter child\'s email address...' : 'Enter parent\'s email address...',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _linkProfile,
                          icon: const Icon(Icons.add_link),
                          label: const Text('Link', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Current Links
                  Text(
                    'Active Linked Accounts Matrix',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: service.isDarkMode ? Colors.white70 : AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_linkedProfiles.isEmpty)
                    _buildEmptyState(service, isParent)
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _linkedProfiles.length,
                      itemBuilder: (context, index) {
                        final profile = _linkedProfiles[index];
                        final subText = isParent ? profile.studentClass : profile.email;

                        return Card(
                          color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.accentGold.withOpacity(0.12),
                              child: Text(
                                profile.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(subText),
                            trailing: IconButton(
                              icon: const Icon(Icons.link_off, color: AppColors.errorRed),
                              tooltip: 'Revoke Association',
                              onPressed: () => _unlinkProfile(profile.uid),
                            ),
                          ),
                        );
                      },
                    )
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(FirebaseService service, bool isParent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.link_off_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            isParent ? 'No active linked student profiles.' : 'No active linked parent profiles.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          )
        ],
      ),
    );
  }
}
