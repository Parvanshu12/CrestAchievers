import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  final String studentUid;
  const AttendanceScreen({super.key, required this.studentUid});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;

  // Teacher/Admin state
  DateTime _adminSelectedDate = DateTime.now();
  String _selectedBatch = 'JEE 2026';
  String _selectedSubject = 'Physics';
  Map<String, bool> _attendanceDraft = {}; // studentUid -> present status
  List<UserModel> _batchStudents = [];
  bool _isAdminMode = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    final service = Provider.of<FirebaseService>(context, listen: false);
    final isTeacher = service.currentUser?.role == 'teacher';
    
    if (isTeacher) {
      setState(() {
        _isAdminMode = true;
      });
      await _loadBatchStudents();
    } else {
      final uid = widget.studentUid.isNotEmpty ? widget.studentUid : service.currentUser?.uid ?? '';
      final list = await service.getStudentAttendance(uid);
      setState(() {
        _records = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBatchStudents() async {
    setState(() => _isLoading = true);
    final service = Provider.of<FirebaseService>(context, listen: false);
    // Fetch all students
    final allUsers = service.simulatedUsers; // using simulated user list
    final filtered = allUsers.where((u) => u.role == 'student' && u.studentClass == _selectedBatch).toList();
    
    // Load attendance for admin selected date
    final dateStr = DateFormat('yyyy-MM-dd').format(_adminSelectedDate);
    final attendanceForDate = await service.getAllAttendanceForDate(dateStr);
    
    final draft = <String, bool>{};
    for (var u in filtered) {
      final record = attendanceForDate.firstWhere(
        (r) => r.studentUid == u.uid && r.subject == _selectedSubject,
        orElse: () => AttendanceRecord(id: '', studentUid: u.uid, date: dateStr, present: true, subject: _selectedSubject, batch: _selectedBatch, markedBy: ''),
      );
      draft[u.uid] = record.present;
    }

    setState(() {
      _batchStudents = filtered;
      _attendanceDraft = draft;
      _isLoading = false;
    });
  }

  Future<void> _saveAttendance() async {
    final service = Provider.of<FirebaseService>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_adminSelectedDate);
    
    setState(() => _isLoading = true);
    for (var entry in _attendanceDraft.entries) {
      await service.markAttendance(
        studentUid: entry.key,
        date: dateStr,
        present: entry.value,
        subject: _selectedSubject,
        batch: _selectedBatch,
      );
    }

    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance updated successfully!'),
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
        title: Text(
          isTeacher ? 'Manage Attendance' : 'Attendance Log',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isTeacher)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isAdminMode = !_isAdminMode;
                });
                _fetchAttendance();
              },
              icon: Icon(_isAdminMode ? Icons.remove_red_eye : Icons.edit),
              label: Text(_isAdminMode ? 'View Mode' : 'Mark Attendance'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentGold,
              ),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isAdminMode
              ? _buildAdminView(service)
              : _buildStudentView(service),
    );
  }

  Widget _buildStudentView(FirebaseService service) {
    // Math to compute metrics
    final total = _records.length;
    final present = _records.where((r) => r.present).length;
    final pct = total > 0 ? (present / total * 100).toStringAsFixed(1) : '100';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat widgets
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  service,
                  'Attendance %',
                  '$pct%',
                  Icons.percent,
                  double.parse(pct) >= 75 ? AppColors.successGreen : AppColors.errorRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  service,
                  'Classes Attended',
                  '$present / $total',
                  Icons.check_circle_outline,
                  AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // GitHub-style contribution activity heatmap grid (NEW)
          _buildActivityHeatmapGrid(service),
          const SizedBox(height: 20),

          // Calendar
          Card(
            color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight,
              ),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primaryNavy,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final ds = DateFormat('yyyy-MM-dd').format(day);
                    final hasRecord = _records.any((r) => r.date == ds);
                    if (hasRecord) {
                      final present = _records.firstWhere((r) => r.date == ds).present;
                      return Container(
                        margin: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: present 
                              ? AppColors.successGreen.withOpacity(0.15) 
                              : AppColors.errorRed.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: present ? AppColors.successGreen : AppColors.errorRed,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: present ? AppColors.successGreen : AppColors.errorRed,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Log List
          Text(
            'Attendance Records Log',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: service.isDarkMode ? Colors.white70 : AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 12),
          if (_records.isEmpty)
            _buildEmptyState(service)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final r = _records[index];
                final dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(r.date));
                return Card(
                  color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: r.present 
                            ? AppColors.successGreen.withOpacity(0.1) 
                            : AppColors.errorRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        r.present ? Icons.check : Icons.close,
                        color: r.present ? AppColors.successGreen : AppColors.errorRed,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      r.subject,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(dateStr),
                    trailing: Text(
                      r.present ? 'PRESENT' : 'ABSENT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: r.present ? AppColors.successGreen : AppColors.errorRed,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAdminView(FirebaseService service) {
    return Column(
      children: [
        // Settings panel
        Container(
          padding: const EdgeInsets.all(16),
          color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedBatch,
                      decoration: const InputDecoration(labelText: 'Batch', border: InputBorder.none),
                      items: ['JEE 2026', 'NEET 2026', 'Class 12 Boards', 'Class 11 Foundation']
                          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedBatch = val);
                          _loadBatchStudents();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(labelText: 'Subject', border: InputBorder.none),
                      items: ['Physics', 'Chemistry', 'Mathematics', 'Biology']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSubject = val);
                          _loadBatchStudents();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                title: Text(
                  'Date: ${DateFormat('dd MMMM yyyy').format(_adminSelectedDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final chosen = await showDatePicker(
                    context: context,
                    initialDate: _adminSelectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 90)),
                    lastDate: DateTime.now(),
                  );
                  if (chosen != null) {
                    setState(() => _adminSelectedDate = chosen);
                    _loadBatchStudents();
                  }
                },
              ),
            ],
          ),
        ),

        // Students list
        Expanded(
          child: _batchStudents.isEmpty
              ? Center(
                  child: Text(
                    'No students registered in $_selectedBatch',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  itemCount: _batchStudents.length,
                  itemBuilder: (context, index) {
                    final student = _batchStudents[index];
                    final isPresent = _attendanceDraft[student.uid] ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                                  child: Text(
                                    student.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      student.email,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('PRESENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  selected: isPresent,
                                  selectedColor: AppColors.successGreen.withOpacity(0.2),
                                  side: BorderSide(color: isPresent ? AppColors.successGreen : Colors.transparent),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _attendanceDraft[student.uid] = true;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('ABSENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  selected: !isPresent,
                                  selectedColor: AppColors.errorRed.withOpacity(0.2),
                                  side: BorderSide(color: !isPresent ? AppColors.errorRed : Colors.transparent),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _attendanceDraft[student.uid] = false;
                                      });
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
                ),
        ),

        // Action Button
        if (_batchStudents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveAttendance,
                icon: const Icon(Icons.done_all),
                label: const Text('Submit Attendance Draft', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          )
      ],
    );
  }

  Widget _buildMetricCard(FirebaseService service, String title, String value, IconData icon, Color color) {
    return Card(
      color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: service.isDarkMode ? Colors.white : AppColors.primaryNavy,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(FirebaseService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              'No attendance record has been posted yet.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHeatmapGrid(FirebaseService service) {
    final isDark = service.isDarkMode;
    final now = DateTime.now();
    final currentYear = now.year;
    
    return Card(
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isDark ? const Color(0xFF374151) : AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yearly Presence Heatmap ($currentYear)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : AppColors.primaryNavy,
                  ),
                ),
                Row(
                  children: [
                    _buildHeatmapIndicatorLegend('Present', AppColors.successGreen),
                    const SizedBox(width: 8),
                    _buildHeatmapIndicatorLegend('Absent', AppColors.errorRed),
                    const SizedBox(width: 8),
                    _buildHeatmapIndicatorLegend('None', isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Horizontal scrollable grid
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(12, (monthIdx) {
                  final monthDate = DateTime(currentYear, monthIdx + 1, 1);
                  final monthName = DateFormat('MMM').format(monthDate);
                  final daysInMonth = DateTime(currentYear, monthIdx + 2, 0).day;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Column(
                      children: [
                        // Month Label
                        Text(
                          monthName,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        
                        // Column of 31 days
                        Column(
                          children: List.generate(31, (dayIdx) {
                            if (dayIdx + 1 > daysInMonth) {
                              return const Padding(
                                padding: EdgeInsets.all(1.5),
                                child: SizedBox(width: 10, height: 10),
                              );
                            }
                            
                            final dayDate = DateTime(currentYear, monthIdx + 1, dayIdx + 1);
                            final ds = DateFormat('yyyy-MM-dd').format(dayDate);
                            final record = _records.where((r) => r.date == ds).firstOrNull;
                            
                            Color squareColor;
                            if (record != null) {
                              squareColor = record.present ? AppColors.successGreen : AppColors.errorRed;
                            } else {
                              // Unmarked day
                              squareColor = isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);
                            }
                            
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: squareColor,
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapIndicatorLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
