import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';

class FeeScreen extends StatefulWidget {
  final String studentUid;
  const FeeScreen({super.key, required this.studentUid});

  @override
  State<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<FeeScreen> {
  List<FeeRecord> _records = [];
  bool _isLoading = true;

  // Teacher/Admin state
  String _selectedBatch = 'JEE 2026';
  List<UserModel> _batchStudents = [];
  Map<String, FeeRecord> _feeDrafts = {}; // studentUid -> current Month FeeRecord
  String _targetMonth = 'May';
  int _targetYear = 2026;
  double _defaultAmount = 5000;
  bool _isAdminMode = false;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  int _monthNameToInt(String name) {
    final idx = _monthNames.indexOf(name);
    return idx != -1 ? idx + 1 : 1;
  }

  @override
  void initState() {
    super.initState();
    _fetchFees();
  }

  Future<void> _fetchFees() async {
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
      final list = await service.getStudentFeeHistory(uid);
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

    // Fetch existing records for this month & year
    final monthInt = _monthNameToInt(_targetMonth);
    final allFees = await service.getAllFeeRecords();
    final matchingFees = allFees.where((f) => f.month == monthInt && f.year == _targetYear).toList();

    final drafts = <String, FeeRecord>{};
    for (var u in filtered) {
      final record = matchingFees.firstWhere(
        (f) => f.studentUid == u.uid,
        orElse: () => FeeRecord(
          id: 'fee_${u.uid}_${monthInt}_$_targetYear',
          studentUid: u.uid,
          month: monthInt,
          year: _targetYear,
          status: 'UNPAID',
          amount: _defaultAmount,
          dueDate: '2026-05-10',
          paidDate: '',
        ),
      );
      drafts[u.uid] = record;
    }

    setState(() {
      _batchStudents = filtered;
      _feeDrafts = drafts;
      _isLoading = false;
    });
  }

  Future<void> _updateStudentFee(String studentUid, String newStatus) async {
    final service = Provider.of<FirebaseService>(context, listen: false);
    final draft = _feeDrafts[studentUid]!;
    
    final updated = FeeRecord(
      id: draft.id,
      studentUid: draft.studentUid,
      month: draft.month,
      year: draft.year,
      status: newStatus,
      amount: draft.amount,
      dueDate: draft.dueDate,
      paidDate: newStatus == 'PAID' ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : '',
    );

    setState(() => _isLoading = true);
    await service.updateFeeRecord(updated);
    await _loadBatchStudents();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fee record updated to $newStatus!'),
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
          isTeacher ? 'Manage Student Fees' : 'Fee Ledger & Invoices',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isTeacher)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isAdminMode = !_isAdminMode;
                });
                _fetchFees();
              },
              icon: Icon(_isAdminMode ? Icons.remove_red_eye : Icons.edit),
              label: Text(_isAdminMode ? 'View Mode' : 'Enter Ledger'),
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
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No fee ledger statements posted yet.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            )
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Highlights
          _buildHighlightLedgerBanner(service),
          const SizedBox(height: 24),

          // Ledger Table
          Text(
            'Statement of Academic Dues',
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
              final isPaid = r.status == 'PAID';
              final statusColor = isPaid 
                  ? AppColors.successGreen 
                  : (r.status == 'PARTIAL' ? AppColors.warningOrange : AppColors.errorRed);

              return Card(
                color: service.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_monthNames[r.month - 1]} ${r.year} Course Fee',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text('Due Date: ${r.dueDate}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              r.status,
                              style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 11),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount: ₹${r.amount.toInt()}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          if (isPaid)
                            OutlinedButton.icon(
                              onPressed: () {
                                _generateInvoicePdf(context, r, service);
                              },
                              icon: const Icon(Icons.download, size: 12),
                              label: const Text('Download Receipt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                          else
                            const Text(
                              'Pending offline verification',
                              style: TextStyle(
                                fontSize: 11, 
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                      if (isPaid) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Paid on: ${r.paidDate}',
                            style: const TextStyle(
                              fontSize: 9, 
                              fontWeight: FontWeight.w500,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildHighlightLedgerBanner(FirebaseService service) {
    final pendingCount = _records.where((r) => r.status == 'UNPAID').length;
    final pendingAmt = pendingCount * _defaultAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: service.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: service.isDarkMode ? const Color(0xFF374151) : AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet, color: AppColors.accentGold, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Outstanding Dues', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${pendingAmt.toInt()}',
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold,
                      color: service.isDarkMode ? Colors.white : AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pendingCount > 0 ? AppColors.errorRed.withOpacity(0.12) : AppColors.successGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              pendingCount > 0 ? '$pendingCount Months Pending' : 'Good Standing',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 10,
                color: pendingCount > 0 ? AppColors.errorRed : AppColors.successGreen,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAdminView(FirebaseService service) {
    return Column(
      children: [
        // Settings / Selector
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
                      value: _targetMonth,
                      decoration: const InputDecoration(labelText: 'Month'),
                      items: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _targetMonth = val);
                          _loadBatchStudents();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Students list with pay status toggler
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
                    final draft = _feeDrafts[student.uid]!;
                    final isPaid = draft.status == 'PAID';

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
                                      '₹${draft.amount.toInt()} Dues',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('PAID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  selected: isPaid,
                                  selectedColor: AppColors.successGreen.withOpacity(0.2),
                                  side: BorderSide(color: isPaid ? AppColors.successGreen : Colors.transparent),
                                  onSelected: (selected) {
                                    if (selected) {
                                      _updateStudentFee(student.uid, 'PAID');
                                    }
                                  },
                                ),
                                const SizedBox(width: 6),
                                ChoiceChip(
                                  label: const Text('UNPAID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  selected: !isPaid,
                                  selectedColor: AppColors.errorRed.withOpacity(0.2),
                                  side: BorderSide(color: !isPaid ? AppColors.errorRed : Colors.transparent),
                                  onSelected: (selected) {
                                    if (selected) {
                                      _updateStudentFee(student.uid, 'UNPAID');
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
      ],
    );
  }

  void _generateInvoicePdf(BuildContext context, FeeRecord record, FirebaseService service) {
    final branchId = service.studentBranchId;
    final branchStr = branchId == 'sector_56' ? 'Sector 56 Branch, Gurugram' : 'Sector 14 Branch, Gurugram';
    final branchGst = branchId == 'sector_56' ? 'GSTIN: 06AAAAA1111A1Z1' : 'GSTIN: 06BBBBB2222B2Z2';
    final studentName = service.currentUser?.name ?? 'Student';
    final invoiceId = 'INV-${record.year}-${record.month}-${record.studentUid.substring(0, 4).toUpperCase()}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text('Tax Invoice Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Column(
                    children: [
                      Text('CREST ACHIEVERS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
                      Text('HYBRID STUDY CENTERS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(branchStr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                Text(branchGst, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                const SizedBox(height: 8),
                const Divider(color: Colors.black87),
                const SizedBox(height: 8),
                
                _buildInvoiceMetaRow('Invoice No:', invoiceId),
                _buildInvoiceMetaRow('Date:', record.paidDate),
                _buildInvoiceMetaRow('Student Name:', studentName),
                _buildInvoiceMetaRow('Class Category:', service.currentUser?.studentClass ?? '12th PCM'),
                const SizedBox(height: 8),
                const Divider(color: Colors.black87),
                const SizedBox(height: 8),
                
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Item Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                    Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tuition Fees (${_monthNames[record.month - 1]} ${record.year})', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                    Text('₹${(record.amount * 0.82).toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CGST @ 9%', style: TextStyle(fontSize: 10, color: Colors.black87)),
                    Text('₹${(record.amount * 0.09).toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SGST @ 9%', style: TextStyle(fontSize: 10, color: Colors.black87)),
                    Text('₹${(record.amount * 0.09).toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.black38),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL PAID (Incl. GST)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
                    Text('₹${record.amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text('*** Thank you for your payment ***', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 9, color: Colors.black54)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Tax Invoice Receipt downloaded to storage!'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            icon: const Icon(Icons.file_download),
            label: const Text('Download PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceMetaRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.bold))),
          Expanded(child: Text(val, style: const TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
