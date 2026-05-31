import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';

class MarksScreen extends StatefulWidget {
  final String studentUid;
  const MarksScreen({super.key, required this.studentUid});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TestResult> _records = [];
  bool _isLoading = true;

  // Teacher/Admin state
  String _selectedBatch = 'JEE 2026';
  String _selectedSubject = 'Physics';
  String _testName = 'Kinematics Mock Test 1';
  int _totalMarks = 100;
  Map<String, double> _marksDraft = {}; // studentUid -> marks obtained
  List<UserModel> _batchStudents = [];
  bool _isAdminMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTestResults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTestResults() async {
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
      final list = await service.getStudentTestResults(uid);
      setState(() {
        _records = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBatchStudents() async {
    setState(() => _isLoading = true);
    final service = Provider.of<FirebaseService>(context, listen: false);
    final allUsers = service.simulatedUsers;
    final filtered = allUsers.where((u) => u.role == 'student' && u.studentClass == _selectedBatch).toList();

    // Setup draft
    final draft = <String, double>{};
    final allTestResults = await service.getAllTestResults();
    final matchingResults = allTestResults.where((r) => r.testName == _testName && r.subject == _selectedSubject).toList();

    for (var u in filtered) {
      final record = matchingResults.firstWhere(
        (r) => r.studentUid == u.uid,
        orElse: () => TestResult(id: '', studentUid: u.uid, testName: _testName, subject: _selectedSubject, marksObtained: 0.0, totalMarks: _totalMarks.toDouble(), date: DateFormat('yyyy-MM-dd').format(DateTime.now()), batch: _selectedBatch),
      );
      draft[u.uid] = record.marksObtained;
    }

    setState(() {
      _batchStudents = filtered;
      _marksDraft = draft;
      _isLoading = false;
    });
  }

  Future<void> _saveTestResults() async {
    final service = Provider.of<FirebaseService>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setState(() => _isLoading = true);
    for (var entry in _marksDraft.entries) {
      final res = TestResult(
        id: 'test_${entry.key}_${_testName.replaceAll(' ', '_')}',
        studentUid: entry.key,
        testName: _testName,
        subject: _selectedSubject,
        marksObtained: entry.value,
        totalMarks: _totalMarks.toDouble(),
        date: dateStr,
        batch: _selectedBatch,
      );
      await service.addTestResult(res);
    }

    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test results submitted and broadcasted!'),
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
          isTeacher ? 'Manage Test Grades' : 'Test & Performance Analytics',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isTeacher)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isAdminMode = !_isAdminMode;
                });
                _fetchTestResults();
              },
              icon: Icon(_isAdminMode ? Icons.remove_red_eye : Icons.edit),
              label: Text(_isAdminMode ? 'View Mode' : 'Enter Marks'),
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
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No mock test results entered yet.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            )
          ],
        ),
      );
    }

    // Compute progress stats
    final averagePct = _records.map((r) => r.marksObtained / r.totalMarks * 100).reduce((a, b) => a + b) / _records.length;
    final highestPct = _records.map((r) => r.marksObtained / r.totalMarks * 100).reduce((a, b) => a > b ? a : b);

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
                  'Average Score',
                  '${averagePct.toStringAsFixed(1)}%',
                  Icons.analytics_outlined,
                  AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  service,
                  'Highest Score',
                  '${highestPct.toStringAsFixed(1)}%',
                  Icons.emoji_events_outlined,
                  AppColors.accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Graph
          Card(
            color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Progression Chart',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text('Percentage obtained across recent mock examinations', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: const FlTitlesData(
                          show: true,
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitlesWidget)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        barGroups: List.generate(_records.length, (idx) {
                          final r = _records[idx];
                          final pct = (r.marksObtained / r.totalMarks * 100);
                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: pct,
                                color: _getSubjectColor(r.subject),
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                              )
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Scores list
          Text(
            'Examination Score Sheet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: service.isDarkMode ? Colors.white70 : AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _records.length,
            itemBuilder: (context, index) {
              final r = _records[index];
              final dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(r.date));
              final pct = (r.marksObtained / r.totalMarks * 100).toStringAsFixed(1);
              final subColor = _getSubjectColor(r.subject);

              return Card(
                color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: subColor.withOpacity(0.12),
                    child: Text(
                      r.subject.substring(0, 1).toUpperCase(),
                      style: TextStyle(color: subColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    r.testName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$dateStr | Batch: ${r.batch}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${r.marksObtained} / ${r.totalMarks}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: double.parse(pct) >= 75 ? AppColors.successGreen : AppColors.errorRed, fontSize: 11),
                      ),
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

  Widget _buildAdminView(FirebaseService service) {
    final currentUser = service.currentUser;
    final isMasterUser = currentUser?.uid == 'crest_dev_master';

    final Map<String, String> batchToCourseId = {
      'JEE 2026': 'jee_achievers_2026',
      'NEET 2026': 'neet_elite_2026',
      'Class 12 Boards': 'class_12_pcm_2026',
      'Class 11 Foundation': 'class_11_pcm_2026',
    };

    // Filtered batches for display
    final List<String> filteredBatches = isMasterUser
        ? ['JEE 2026', 'NEET 2026', 'Class 12 Boards', 'Class 11 Foundation']
        : batchToCourseId.entries
            .where((entry) => currentUser?.assignedCourseIds.contains(entry.value) == true)
            .map((entry) => entry.key)
            .toList();

    // Filtered subjects
    final filteredSubjects = isMasterUser
        ? ['Physics', 'Chemistry', 'Mathematics', 'Biology']
        : ['Physics', 'Chemistry', 'Mathematics', 'Biology']
            .where((sub) => currentUser?.assignedSubjects.contains(sub) == true)
            .toList();

    // Ensure _selectedBatch is valid
    if (filteredBatches.isNotEmpty) {
      if (!filteredBatches.contains(_selectedBatch)) {
        _selectedBatch = filteredBatches.first;
      }
    }

    // Ensure _selectedSubject is valid
    if (filteredSubjects.isNotEmpty) {
      if (!filteredSubjects.contains(_selectedSubject)) {
        _selectedSubject = filteredSubjects.first;
      }
    }

    if (filteredBatches.isEmpty) {
      return Expanded(
        child: Center(
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
                  'You must be assigned to batches and subjects by the Master Admin before uploading mock test marks.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Settings form
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
                      decoration: const InputDecoration(labelText: 'Batch'),
                      items: filteredBatches
                          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedBatch = val;
                          });
                          _loadBatchStudents();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: filteredSubjects
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSubject = val;
                          });
                          _loadBatchStudents();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Test Name Outline'),
                      controller: TextEditingController(text: _testName),
                      onChanged: (val) {
                        _testName = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Max Marks'),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: _totalMarks.toString()),
                      onChanged: (val) {
                        final valInt = int.tryParse(val) ?? 100;
                        setState(() {
                          _totalMarks = valInt;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _loadBatchStudents,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload Target Student List'),
              ),
            ],
          ),
        ),

        // Students score editor list
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
                    final currentVal = _marksDraft[student.uid] ?? 0.0;

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
                            SizedBox(
                              width: 80,
                              child: TextField(
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                controller: TextEditingController(text: currentVal.toString()),
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  suffixText: 'marks',
                                  suffixStyle: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                                onChanged: (val) {
                                  final doubleVal = double.tryParse(val) ?? 0.0;
                                  _marksDraft[student.uid] = doubleVal;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Action submit button
        if (_batchStudents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveTestResults,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Save and Broadcast Results', style: TextStyle(fontWeight: FontWeight.bold)),
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
        side: BorderSide(color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
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

  static Widget _bottomTitlesWidget(double value, TitleMeta meta) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        'T${(value + 1).toInt()}',
        style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
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
