import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../models/course_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  UserModel? _activeChatPartner;
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  List<UserModel> _students = [];
  bool _loadingDirectory = true;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory() async {
    final service = Provider.of<FirebaseService>(context, listen: false);
    final list = await service.fetchStudentDirectory();
    if (mounted) {
      setState(() {
        _students = list;
        _loadingDirectory = false;
      });
    }
  }

  void _sendMessage(FirebaseService service) {
    if (_messageController.text.trim().isEmpty || _activeChatPartner == null) return;
    service.sendChatMessage(_activeChatPartner!.uid, _messageController.text);
    _messageController.clear();
    // Scroll to bottom after message sent
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Container(
      color: AppColors.bgSoftWhite,
      child: _activeChatPartner != null
          ? _buildChatRoomView(context, service)
          : _buildDirectoryView(context, isDesktop),
    );
  }

  Widget _buildDirectoryView(BuildContext context, bool isDesktop) {
    final filteredStudents = _students.where((std) {
      final nameMatch = std.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final classMatch = std.studentClass.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatch || classMatch;
    }).toList();

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Text(
            '👥 Crest Achievers Circle',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 6),
          const Text(
            'Connect, discuss, and study with other verified students. Privacy is absolute—only names and courses are visible.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or category (e.g. JEE or NEET)...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 24),

          // Student List Grid
          Expanded(
            child: _loadingDirectory
                ? const Center(child: CircularProgressIndicator())
                : (filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ? 'No students found matching search' : 'No other students online yet',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isDesktop ? 350 : 600,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 96,
                        ),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
                                child: ClipOval(
                                  child: Image.network(
                                    student.photoUrl,
                                    fit: BoxFit.cover,
                                    width: 48,
                                    height: 48,
                                    errorBuilder: (c, e, s) => const Icon(Icons.person, color: AppColors.primaryBlue),
                                  ),
                                ),
                              ),
                              title: Text(
                                student.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                student.studentClass,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                              trailing: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.primaryBlue),
                              onTap: () {
                                setState(() {
                                  _activeChatPartner = student;
                                });
                              },
                            ),
                          ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97));
                        },
                      )),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomView(BuildContext context, FirebaseService service) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  onPressed: () {
                    setState(() {
                      _activeChatPartner = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
                  child: ClipOval(
                    child: Image.network(
                      _activeChatPartner!.photoUrl,
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40,
                      errorBuilder: (c, e, s) => const Icon(Icons.person, color: AppColors.primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeChatPartner!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                      ),
                      Text(
                        _activeChatPartner!.studentClass,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Lock Badge to reassure privacy
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 10, color: AppColors.successGreen),
                      SizedBox(width: 4),
                      Text('SECURE', style: TextStyle(color: AppColors.successGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Live Chat Messages Stream list
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: service.getChatMessagesStream(_activeChatPartner!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data ?? [];
              
              if (messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
                          child: ClipOval(
                            child: Image.network(
                              _activeChatPartner!.photoUrl,
                              fit: BoxFit.cover,
                              width: 72,
                              height: 72,
                              errorBuilder: (c, e, s) => const Icon(Icons.person, color: AppColors.primaryBlue, size: 36),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a study chat with ${_activeChatPartner!.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Discuss formulas, ask mock doubt questions, or coordinate mock study timelines.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == service.currentUser!.uid;
                  return _buildMessageBubble(msg, isMe);
                },
              );
            },
          ),
        ),

        // Bottom Input Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a secure study message...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(service),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.primaryBlue,
                radius: 22,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: () => _sendMessage(service),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().slideX(begin: 0.05, end: 0);
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primaryBlue : Colors.white,
            border: isMe ? null : Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16),
            ),
            boxShadow: isMe ? null : [AppColors.softShadow],
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              color: isMe ? Colors.white : AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
