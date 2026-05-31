import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';

class TimetableScreen extends StatefulWidget {
  final String batch;
  const TimetableScreen({super.key, required this.batch});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _dayTabController;
  final _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  String _selectedBatch = 'JEE 2026';
  List<TimetableSlot> _slots = [];
  bool _isLoading = true;

  // Form states for creating a slot
  String _formSubject = 'Physics';
  String _formTeacher = 'Dr. Amit Kumar';
  String _formRoom = 'Room A';
  TimeOfDay _formStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _formEnd = const TimeOfDay(hour: 9, minute: 30);

  @override
  void initState() {
    super.initState();
    _dayTabController = TabController(length: 6, vsync: this);
    _selectedBatch = widget.batch.isNotEmpty ? widget.batch : 'JEE 2026';
    _fetchTimetable();
  }

  @override
  void dispose() {
    _dayTabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTimetable() async {
    setState(() => _isLoading = true);
    final service = Provider.of<FirebaseService>(context, listen: false);
    final list = await service.getTimetable(_selectedBatch);
    setState(() {
      _slots = list;
      _isLoading = false;
    });
  }

  Future<void> _addNewSlot() async {
    final service = Provider.of<FirebaseService>(context, listen: false);
    final activeDayIndex = _dayTabController.index;

    final startStr = '${_formStart.hour.toString().padLeft(2, '0')}:${_formStart.minute.toString().padLeft(2, '0')}';
    final endStr = '${_formEnd.hour.toString().padLeft(2, '0')}:${_formEnd.minute.toString().padLeft(2, '0')}';

    final slot = TimetableSlot(
      id: 'slot_${DateTime.now().millisecondsSinceEpoch}',
      batch: _selectedBatch,
      dayIndex: activeDayIndex,
      startTime: startStr,
      endTime: endStr,
      subject: _formSubject,
      teacherName: _formTeacher,
      room: _formRoom,
    );

    setState(() => _isLoading = true);
    await service.upsertTimetableSlot(slot);
    await _fetchTimetable();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timetable slot added successfully!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final currentUser = service.currentUser;
    final isTeacher = currentUser?.role == 'teacher';
    final isMasterUser = currentUser?.uid == 'crest_dev_master';

    final Map<String, String> batchToCourseId = {
      'JEE 2026': 'jee_achievers_2026',
      'NEET 2026': 'neet_elite_2026',
      'Class 12 Boards': 'class_12_pcm_2026',
      'Class 11 Foundation': 'class_11_pcm_2026',
    };

    // Filtered batches for display
    final List<String> filteredBatches = (isTeacher && !isMasterUser)
        ? batchToCourseId.entries
            .where((entry) => currentUser?.assignedCourseIds.contains(entry.value) == true)
            .map((entry) => entry.key)
            .toList()
        : ['JEE 2026', 'NEET 2026', 'Class 12 Boards', 'Class 11 Foundation', 'All'];

    // Ensure _selectedBatch is valid
    if (filteredBatches.isNotEmpty) {
      if (!filteredBatches.contains(_selectedBatch)) {
        _selectedBatch = filteredBatches.first;
      }
    }

    if (isTeacher && !isMasterUser && filteredBatches.isEmpty) {
      return Scaffold(
        backgroundColor: service.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Weekly Study Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'No Batches Assigned',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You must be assigned to batches and subjects by the Master Admin before managing weekly schedules.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: service.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Weekly Study Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _dayTabController,
          isScrollable: true,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryNavy,
          tabs: _days.map((d) => Tab(text: d.substring(0, 3).toUpperCase())).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Batch Filter Top Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Academic Batch:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: service.isDarkMode ? Colors.white70 : AppColors.primaryNavy,
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          value: _selectedBatch,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10), border: InputBorder.none),
                          items: filteredBatches
                              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedBatch = val);
                              _fetchTimetable();
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Timetable Slots List
                Expanded(
                  child: TabBarView(
                    controller: _dayTabController,
                    children: List.generate(6, (dayIdx) => _buildDaySlots(service, dayIdx)),
                  ),
                ),
              ],
            ),
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              onPressed: () => _showAddSlotDialog(context, service),
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDaySlots(FirebaseService service, int dayIndex) {
    final list = _slots.where((s) => s.dayIndex == dayIndex).toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_view_day_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text('No classes scheduled for this day.', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final slot = list[index];
        final subColor = _getSubjectColor(slot.subject);

        return Card(
          color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Time panel
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.startTime,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: subColor),
                    ),
                    const Text('to', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      slot.endTime,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 50, color: AppColors.borderLight),
                const SizedBox(width: 16),

                // Class Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            slot.subject,
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: service.isDarkMode ? Colors.white : AppColors.primaryNavy,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: subColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              slot.room,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            slot.teacherName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.class_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Batch: ${slot.batch}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddSlotDialog(BuildContext context, FirebaseService service) {
    final currentUser = service.currentUser;
    final isMasterUser = currentUser?.uid == 'crest_dev_master';

    final filteredSubjects = isMasterUser
        ? ['Physics', 'Chemistry', 'Mathematics', 'Biology']
        : ['Physics', 'Chemistry', 'Mathematics', 'Biology']
            .where((sub) => currentUser?.assignedSubjects.contains(sub) == true)
            .toList();

    if (filteredSubjects.isNotEmpty) {
      if (!filteredSubjects.contains(_formSubject)) {
        _formSubject = filteredSubjects.first;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Weekly Class Slot', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _formSubject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: filteredSubjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _formSubject = val);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _formTeacher,
                  decoration: const InputDecoration(labelText: 'Teacher'),
                  items: ['Dr. Amit Kumar', 'Mrs. Priya Sharma', 'Mr. Rakesh Singh']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _formTeacher = val);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _formRoom,
                  decoration: const InputDecoration(labelText: 'Class Room'),
                  items: ['Room A', 'Room B', 'Room C', 'Hall 1']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _formRoom = val);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text('Start Time: ${_formStart.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final chosen = await showTimePicker(context: context, initialTime: _formStart);
                    if (chosen != null) setState(() => _formStart = chosen);
                  },
                ),
                ListTile(
                  title: Text('End Time: ${_formEnd.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final chosen = await showTimePicker(context: context, initialTime: _formEnd);
                    if (chosen != null) setState(() => _formEnd = chosen);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addNewSlot,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              child: const Text('Add to Schedule', style: TextStyle(color: Colors.white)),
            ),
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
