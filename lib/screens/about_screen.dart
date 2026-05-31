import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _bookingFormKey = GlobalKey<FormState>();
  final _visitorNameController = TextEditingController();
  final _visitorPhoneController = TextEditingController();
  String _selectedCenter = 'South Delhi Premier Wing';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isBookingSubmitted = false;

  final List<Map<String, dynamic>> _offlineCentres = [
    {
      'title': 'Crest Achievers Elite Campus',
      'branch': 'South Delhi (IIT-JEE & NEET Wing)',
      'address': 'Plot 14, Ring Road, near Metro Pillar 128, South Extension I, New Delhi - 110049',
      'phone': '+91 98765 43210',
      'email': 'southdelhi@crestachievers.com',
      'amenities': [
        'Hybrid Smart Classrooms with Digital Interactive Whiteboards',
        '24/7 Silent Library with Personal Self-Study Cabins',
        'Physical CBT (Computer Based Test) Simulation Lab with 100+ Terminal Terminals',
        'Dedicated 1-on-1 Offline Doubt Counter Desks (Physics, Chemistry, Maths, Biology)',
        'Fully air-conditioned, safety-secured campus under CCTV coverage'
      ],
      'specialty': 'Targeting top rank production for JEE Advanced & NEET UG'
    },
    {
      'title': 'Crest Achievers Scholars Hub',
      'branch': 'West Delhi (Foundations & Board Wing)',
      'address': 'Block B-2, Najafgarh Road, Opp. Metro Station, Janakpuri, New Delhi - 110058',
      'phone': '+91 98765 43211',
      'email': 'westdelhi@crestachievers.com',
      'amenities': [
        'Foundations Specialization Classrooms (Class 9th to 12th)',
        'Bi-weekly Offline Descriptive Mock Boards Test Centers',
        'Parent-Teacher Lounge with monthly Offline Performance Reviews',
        'Immediate After-Class Doubt Clarification desks',
        'Free integrated textbooks & physical study material distribution library'
      ],
      'specialty': 'Focusing on Board exams scoring (PCM/PCB) alongside early JEE/NEET prep'
    }
  ];

  @override
  void dispose() {
    _visitorNameController.dispose();
    _visitorPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitBooking() {
    if (!_bookingFormKey.currentState!.validate()) return;
    setState(() {
      _isBookingSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title
          Text(
            '🏫 Crest Achievers Offline Centres',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 6),
          const Text(
            'Crest Achievers combines premium virtual learning with powerful offline mentoring across our ultra-modern Delhi campuses.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Grid of Offline Centres
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCentreCard(context, _offlineCentres[0])),
                    const SizedBox(width: 24),
                    Expanded(child: _buildCentreCard(context, _offlineCentres[1])),
                  ],
                )
              : Column(
                  children: [
                    _buildCentreCard(context, _offlineCentres[0]),
                    const SizedBox(height: 20),
                    _buildCentreCard(context, _offlineCentres[1]),
                  ],
                ),
          const SizedBox(height: 40),

          // CBT / Hybrid Advantage Section
          _buildAdvantageSection(context, isDesktop),
          const SizedBox(height: 40),

          // Interactive Visit Booking Form
          _buildBookingSection(context, isDesktop),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCentreCard(BuildContext context, Map<String, dynamic> centre) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Specialty Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                centre['specialty'].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Title & Branch
            Text(
              centre['title'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            Text(
              centre['branch'],
              style: const TextStyle(fontSize: 13, color: AppColors.accentIndigo, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 16),

            // Location details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primaryBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    centre['address'],
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone_in_talk_outlined, size: 20, color: AppColors.primaryBlue),
                const SizedBox(width: 10),
                Text(
                  centre['phone'],
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.primaryBlue),
                const SizedBox(width: 10),
                Text(
                  centre['email'],
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Amenities list
            const Text(
              '🎯 Campus Facilities & Features:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              (centre['amenities'] as List<String>).length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.successGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        centre['amenities'][index],
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildAdvantageSection(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accentIndigo.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentIndigo.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.offline_bolt_outlined, color: AppColors.accentIndigo, size: 28),
              SizedBox(width: 10),
              Text(
                '⚡ The Crest Hybrid Advantage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Students enrolled in our online programs get complete free access to attend periodic doubt desks, physical test series, and book private study spaces in our offline centres. Combine the speed of virtual learning with the solidity of physical academic rigor!',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.45),
          ),
          const SizedBox(height: 20),
          isDesktop
              ? Row(
                  children: [
                    Expanded(child: _buildAdvantageItem('Real CBT Simulations', 'Practice JEE & NEET mock tests on physical terminal terminals matching exact exam hall environment.', Icons.computer)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAdvantageItem('Mentorship & Guidance', 'Regular offline counseling & motivation checkups by IITian and Medical expert faculties.', Icons.psychology_outlined)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAdvantageItem('Offline Doubt Cabin', 'Step up to a teacher face-to-face and clarify physics/chemistry doubts on physical sheets.', Icons.draw_outlined)),
                  ],
                )
              : Column(
                  children: [
                    _buildAdvantageItem('Real CBT Simulations', 'Practice JEE & NEET mock tests on physical terminal terminals matching exact exam hall environment.', Icons.computer),
                    const SizedBox(height: 12),
                    _buildAdvantageItem('Mentorship & Guidance', 'Regular offline counseling & motivation checkups by IITian and Medical expert faculties.', Icons.psychology_outlined),
                    const SizedBox(height: 12),
                    _buildAdvantageItem('Offline Doubt Cabin', 'Step up to a teacher face-to-face and clarify physics/chemistry doubts on physical sheets.', Icons.draw_outlined),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildAdvantageItem(String title, String desc, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.accentIndigo.withOpacity(0.08),
          child: Icon(icon, color: AppColors.accentIndigo, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSection(BuildContext context, bool isDesktop) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: _isBookingSubmitted ? _buildBookingSuccess() : _buildBookingForm(isDesktop),
      ),
    );
  }

  Widget _buildBookingSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.successGreen),
        const SizedBox(height: 20),
        const Text(
          'Campus Tour Booking Confirmed!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        Text(
          'Hi ${_visitorNameController.text.trim()}, we have reserved your slots for a free center counseling tour at $_selectedCenter on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.successGreen.withOpacity(0.1)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.successGreen, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Show this screen at the entrance for free fast-track access.',
                  style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            setState(() {
              _isBookingSubmitted = false;
              _visitorNameController.clear();
              _visitorPhoneController.clear();
            });
          },
          child: const Text('Book Another Visit', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ).animate().scale(duration: const Duration(milliseconds: 250));
  }

  Widget _buildBookingForm(bool isDesktop) {
    return Form(
      key: _bookingFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Schedule a Free Center Visit & Offline Counseling',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Visit our campus with your parents for face-to-face mentorship and custom class syllabus planning.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          
          isDesktop
              ? Row(
                  children: [
                    Expanded(child: _buildNameInput()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildPhoneInput()),
                  ],
                )
              : Column(
                  children: [
                    _buildNameInput(),
                    const SizedBox(height: 16),
                    _buildPhoneInput(),
                  ],
                ),
          const SizedBox(height: 16),

          isDesktop
              ? Row(
                  children: [
                    Expanded(child: _buildCenterDropdown()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildDatePickerField()),
                  ],
                )
              : Column(
                  children: [
                    _buildCenterDropdown(),
                    const SizedBox(height: 16),
                    _buildDatePickerField(),
                  ],
                ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitBooking,
              child: const Text('Confirm Counseling Visit Slot'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return TextFormField(
      controller: _visitorNameController,
      decoration: const InputDecoration(
        labelText: 'Student / Parent Name',
        prefixIcon: Icon(Icons.person_outline, size: 20),
        hintText: 'Enter full name',
      ),
      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
    );
  }

  Widget _buildPhoneInput() {
    return TextFormField(
      controller: _visitorPhoneController,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'Contact Mobile Number',
        prefixIcon: Icon(Icons.phone_outlined, size: 20),
        hintText: '10-digit number',
      ),
      validator: (val) => val == null || val.trim().length != 10 ? 'Please enter 10-digit number' : null,
    );
  }

  Widget _buildCenterDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCenter,
      decoration: const InputDecoration(
        labelText: 'Choose Centre Location',
        prefixIcon: Icon(Icons.business_outlined, size: 20),
      ),
      items: const [
        DropdownMenuItem(value: 'South Delhi Premier Wing', child: Text('South Delhi Campus (IIT-JEE/NEET)')),
        DropdownMenuItem(value: 'West Delhi Foundations Hub', child: Text('West Delhi Campus (Foundations/Boards)')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedCenter = val;
          });
        }
      },
    );
  }

  Widget _buildDatePickerField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: IgnorePointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: 'Preferred Visit Date',
            prefixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
            hintText: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          ),
        ),
      ),
    );
  }
}
