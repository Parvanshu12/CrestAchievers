import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // High-Speed discrete OTP controls
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  
  bool _isSignUp = false;
  bool _isPhoneAuth = false; // Toggle between Email & Phone Auth
  bool _otpSent = false;     // OTP status tracker
  final bool _showPhoneAuthOption = false; // Set to true to re-enable mobile OTP auth visually
  String _selectedClass = '12th PCM';

  final List<String> _classOptions = [
    '11th PCM',
    '12th PCM',
    'JEE Dropper',
    'NEET Aspirant',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    for (var ctrl in _otpControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _sendOTP(FirebaseService service) {
    if (_phoneController.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    String phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) {
      phone = '+91$phone'; // Default to Indian Code
    }

    service.verifyPhoneNumber(
      phoneNumber: phone,
      onCodeSent: (verId) {
        setState(() {
          _otpSent = true;
        });
        final bool isSimulated = !service.isFirebaseInitialized || service.isPhoneAuthForceSimulated;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSimulated 
                ? 'Verification code sent to $phone. Use 123456 for simulator!'
                : 'Verification code sent to $phone.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      },
      onError: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.errorRed,
          ),
        );
      },
    );
  }

  void _submitForm(FirebaseService service) async {
    if (!_formKey.currentState!.validate()) return;

    bool success = false;
    
    if (_isPhoneAuth) {
      if (!_otpSent) {
        _sendOTP(service);
        return;
      }
      // Only send name and class if they are registering as a new student
      success = await service.signInWithOTP(
        _otpController.text.trim(),
        _isSignUp ? _nameController.text.trim() : '',
        _isSignUp ? _selectedClass : '',
      );
    } else {
      if (_isSignUp) {
        success = await service.signUp(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          _selectedClass,
        );
      } else {
        success = await service.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSignUp || _isPhoneAuth ? 'Welcome to Crest Achievers!' : 'Successfully signed in!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else if (service.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.errorMessage!),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Spheres
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentIndigo.withOpacity(0.06),
              ),
            ),
          ),

          // Central Workspace
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: isDesktop
                      ? Row(
                          children: [
                            // Brand Sidebar (Desktop only)
                            Expanded(
                              flex: 5,
                              child: Container(
                                height: 620,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.primaryBlue, AppColors.accentIndigo],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(40.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          '🌟 CREST ACHIEVERS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Reach the Peak of Academic Success',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Access private video classes, DPP review papers, and PDF revision guides in light mode format.',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 16,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Credentials Form panel
                            Expanded(
                              flex: 6,
                              child: SizedBox(
                                height: 620,
                                child: _buildFormPanel(context, service, isDesktop),
                              ),
                            ),
                          ],
                        )
                      : _buildFormPanel(context, service, isDesktop),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context, FirebaseService service, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 20,
        vertical: 32,
      ),
      color: Colors.white,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo / Name
            if (!isDesktop) ...[
              Text(
                'Crest Achievers',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.primaryBlue,
                    ),
              ),
              const SizedBox(height: 8),
            ],

            // Screen Headline
            Text(
              _isPhoneAuth 
                  ? (_otpSent 
                      ? 'Enter OTP Code' 
                      : (_isSignUp ? 'Sign Up via Mobile' : 'Sign In via Mobile')) 
                  : (_isSignUp ? 'Create your Account' : 'Welcome Back'),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _isPhoneAuth 
                  ? 'Sign in securely using dynamic mobile SMS OTP verification.' 
                  : (_isSignUp ? 'Enroll to explore classes.' : 'Login to unlock your enrolled coaching syllabus.'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Tab Toggle for Email vs Mobile Auth (only when not inside OTP verification stage)
            if (_showPhoneAuthOption && !_otpSent) ...[
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Email Auth')),
                      selected: !_isPhoneAuth,
                      onSelected: (selected) {
                        setState(() {
                          _isPhoneAuth = false;
                          _formKey.currentState?.reset();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Mobile Auth')),
                      selected: _isPhoneAuth,
                      onSelected: (selected) {
                        setState(() {
                          _isPhoneAuth = true;
                          _formKey.currentState?.reset();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Form Fields based on Authentication Type selected
            if (_isPhoneAuth) ...[
              // --- PHONE AUTH FIELDS ---
              if (!_otpSent) ...[
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    hintText: 'Enter 10-digit number',
                  ),
                  validator: (val) => val == null || val.trim().length != 10
                      ? 'Please enter a valid 10-digit number'
                      : null,
                ),
              ] else ...[
                // OTP SENT STATE
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Discrete 6-Digit verification code',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 42,
                          height: 48,
                          child: TextFormField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocusNodes[index],
                            autofocus: index == 0,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: "",
                              contentPadding: EdgeInsets.zero,
                              fillColor: service.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              // Sync state
                              final code = _otpControllers.map((c) => c.text).join();
                              _otpController.text = code;
                              
                              if (value.isNotEmpty && index < 5) {
                                _otpFocusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _otpFocusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    // Invisible validator text field to backing up Form validators!
                    TextFormField(
                      controller: _otpController,
                      style: const TextStyle(fontSize: 0.1),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      validator: (val) => val == null || val.trim().length != 6
                          ? 'Please fill all 6 discrete OTP boxes'
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Onboard Profile details during OTP (ONLY shown if they chosen SIGN UP option)
                if (_isSignUp) ...[
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Your Full Name',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                      hintText: 'Enter your name',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter your name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Target Category / Class',
                      prefixIcon: Icon(Icons.school_outlined, size: 20),
                    ),
                    items: _classOptions.map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(val),
                      );
                    }).toList(),
                    onChanged: (newVal) {
                      if (newVal != null) {
                        setState(() {
                          _selectedClass = newVal;
                        });
                      }
                    },
                  ),
                ],
              ],
              const SizedBox(height: 24),
            ] else ...[
              // --- EMAIL AUTH FIELDS ---
              if (_isSignUp) ...[
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    LengthLimitingTextInputFormatter(50),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                    hintText: 'Enter your name',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                  hintText: 'student@example.com',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                  hintText: '••••••••',
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter a password';
                  if (val.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_isSignUp) ...[
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Target Category / Class',
                    prefixIcon: Icon(Icons.school_outlined, size: 20),
                  ),
                  items: _classOptions.map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(val),
                    );
                  }).toList(),
                  onChanged: (newVal) {
                    if (newVal != null) {
                      setState(() {
                        _selectedClass = newVal;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],

            // Primary Button
            service.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () => _submitForm(service),
                    child: Text(
                      _isPhoneAuth 
                          ? (_otpSent 
                              ? (_isSignUp ? 'Verify OTP & Onboard' : 'Verify OTP & Sign In') 
                              : 'Request OTP SMS') 
                          : (_isSignUp ? 'Create Account' : 'Sign In')
                    ),
                  ),

            const SizedBox(height: 16),

            // Toggle buttons / Back
            if (_otpSent && _isPhoneAuth)
              TextButton(
                onPressed: () {
                  setState(() {
                    _otpSent = false;
                    _otpController.clear();
                  });
                },
                child: const Text('Back to phone number entry', style: TextStyle(color: AppColors.textMuted)),
              ),

            if (!_otpSent)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp ? 'Already registered?' : 'First time student?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      _isSignUp ? 'Sign In' : 'Sign Up Free',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
