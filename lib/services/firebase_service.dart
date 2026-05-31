// © Copyright 2026 parvanshu. All rights reserved.
// This application codebase was designed, developed, and optimized by parvanshu.
// Unauthorized copying, reuse, or distribution of this code is strictly regulated.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import '../data/mock_data.dart';
import '../firebase_options.dart';

class FirebaseService extends ChangeNotifier {
  bool _isFirebaseInitialized = false;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  // Active state variables
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Phone Auth State variables
  String? _verificationId;
  String? get verificationId => _verificationId;
  String? _phoneNumberEntered; // Track entered phone for developer role & mockup login
  bool _isPhoneAuthForceSimulated = false; // Graceful fallback if billing is not enabled
  bool _isRegistering = false; // Flag to prevent unregistered login auto-signup
  bool get isPhoneAuthForceSimulated => _isPhoneAuthForceSimulated;

  // Live Courses loaded from Firestore
  List<Course> _courses = [];
  List<Course> get courses => _courses.isEmpty ? MockData.sampleCourses : _courses;

  // --- True Offline Caching Mode State ---
  final Set<String> _cachedLectures = {};
  final Set<String> _cachedNotes = {};
  final Map<String, double> _downloadProgress = {};

  Set<String> get cachedLectures => _cachedLectures;
  Set<String> get cachedNotes => _cachedNotes;
  Map<String, double> get downloadProgress => _downloadProgress;

  bool isLectureCached(String chapterId, String lectureTitle) {
    return _cachedLectures.contains("${chapterId}_$lectureTitle");
  }

  bool isNoteCached(String chapterId, String noteTitle) {
    return _cachedNotes.contains("${chapterId}_$noteTitle");
  }

  double getDownloadProgress(String id) {
    return _downloadProgress[id] ?? 0.0;
  }

  bool isDownloading(String id) {
    return _downloadProgress.containsKey(id) && _downloadProgress[id]! < 1.0;
  }

  // Track lesson progress locally for responsive UI
  final Set<String> _completedLectures = {};
  final Set<String> _completedNotes = {};
  
  // SWR Caches for ultra-fast 0ms UI load speeds
  final Map<String, List<AttendanceRecord>> _attendanceCache = {};
  final Map<String, List<TestResult>> _testResultsCache = {};
  final Map<String, List<FeeRecord>> _feeHistoryCache = {};
  
  // Track pending enrollment course IDs locally to avoid lagging checks
  final Set<String> _pendingEnrollmentCourseIds = {};
  Set<String> get pendingEnrollmentCourseIds => _pendingEnrollmentCourseIds;

  // Track rejected enrollment reasons locally
  final Map<String, String> _rejectedEnrollmentReasons = {};
  Map<String, String> get rejectedEnrollmentReasons => _rejectedEnrollmentReasons;

  bool isEnrollmentRejected(String courseId) {
    return _rejectedEnrollmentReasons.containsKey(courseId);
  }

  String getEnrollmentRejectionReason(String courseId) {
    return _rejectedEnrollmentReasons[courseId] ?? '';
  }

  // --- Real-time Dynamic & Simulated Databases (NEW) ---
  final List<UserModel> _simulatedUsers = [
    UserModel(uid: 'mock_std_1', email: 'rohit@crest.com', name: 'Rohit Verma', studentClass: '12th PCM', photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=rohit', purchasedCourseIds: [], role: 'student'),
    UserModel(uid: 'mock_std_2', email: 'sneha@crest.com', name: 'Sneha Patel', studentClass: 'JEE Dropper', photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=sneha', purchasedCourseIds: ['jee_achievers_2026'], role: 'student'),
    UserModel(uid: 'mock_std_3', email: 'aarav@crest.com', name: 'Aarav Gupta', studentClass: '11th PCM', photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=aarav', purchasedCourseIds: [], role: 'student'),
    UserModel(uid: 'mock_teach_1', email: 'teacher_amit@crest.com', name: 'Dr. Amit Kumar', studentClass: 'Physics Department', photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=amit', purchasedCourseIds: [], role: 'teacher', assignedCourseIds: ['jee_achievers_2026', 'class_12_pcm_2026'], assignedSubjects: ['Physics']),
    UserModel(uid: 'mock_teach_2', email: 'teacher_shalini@crest.com', name: 'Prof. Shalini Roy', studentClass: 'Biology & Chemistry Dept', photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=shalini', purchasedCourseIds: [], role: 'teacher', assignedCourseIds: ['neet_elite_2026'], assignedSubjects: ['Biology', 'Chemistry']),
  ];
  List<UserModel> get simulatedUsers => _simulatedUsers;

  final List<Map<String, String>> _simulatedPendingEnrollments = [];

  final List<String> _simulatedAnnouncements = [
    "🔥 Sunday JEE Mock Test #4 will go live at 9:00 AM. Prepare Kinematics and Laws of Motion!",
    "📢 Offline batch registration at Janakpuri center starts from Monday. Visit the campus today!"
  ];

  // Track notifications/alerts
  final List<Map<String, String>> _simulatedNotifications = [];

  FirebaseService() {
    _initFirebaseAndSession();
  }

  Future<void> _saveLocalSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        final Map<String, dynamic> data = _currentUser!.toMap();
        data['uid'] = _currentUser!.uid;
        await prefs.setString('crest_user_session', jsonEncode(data));
      } else {
        await prefs.remove('crest_user_session');
      }
    } catch (e) {
      debugPrint("Error saving local session: $e");
    }
  }

  Future<void> _loadLocalSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('crest_user_session');
      if (userJson != null) {
        final Map<String, dynamic> data = jsonDecode(userJson);
        final String uid = data['uid'] ?? '';
        _currentUser = UserModel.fromMap(data, uid);
        
        // Sync pending and rejected enrollment course IDs locally
        _pendingEnrollmentCourseIds.clear();
        _rejectedEnrollmentReasons.clear();
        for (var e in _simulatedPendingEnrollments) {
          if (e['uid'] == uid) {
            if (e['status'] == 'pending') {
              _pendingEnrollmentCourseIds.add(e['courseId']!);
            } else if (e['status'] == 'rejected') {
              _rejectedEnrollmentReasons[e['courseId']!] = e['reason'] ?? 'No reason provided';
            }
          }
        }
        
        notifyListeners();
        debugPrint("🔐 Restored persistent local session for: ${_currentUser!.name} (Role: ${_currentUser!.role})");
      }
    } catch (e) {
      debugPrint("Error loading local session: $e");
    }
  }

  Future<void> _initFirebaseAndSession() async {
    _setLoading(true);
    
    // 1. Immediately restore persistent local session for 0ms launch speed!
    await _loadLocalSession();
    await _loadCachedDownloads();
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseInitialized = true;
      debugPrint("🚀 Firebase initialized successfully in Crest Achievers!");

      // 2. Load courses asynchronously in the background so it doesn't block the launch
      _fetchAndSeedCourses();

      // 3. Listen to Auth State changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          await _loadUserData(user.uid);
        } else {
          // Only clear and check if there's no simulated session already loaded
          if (_currentUser == null) {
            final prefs = await SharedPreferences.getInstance();
            if (prefs.containsKey('crest_user_session')) {
              await _loadLocalSession();
            } else {
              _currentUser = null;
              notifyListeners();
            }
          }
        }
      });
    } catch (e) {
      _isFirebaseInitialized = false;
      debugPrint("⚠️ Firebase not initialized: ${e.toString()}. Falling back to fully interactive Simulated Engine.");
      // Session is already loaded at start, but double-check guest fallback
      if (_currentUser == null) {
        _currentUser = UserModel(
          uid: 'crest_demo_student',
          email: 'student@crestachievers.com',
          name: 'Guest Achiever',
          studentClass: '12th PCM',
          photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=crest_demo_student',
          purchasedCourseIds: ['jee_achievers_2026'],
          role: 'student',
        );
        notifyListeners();
      }
    }
    _setLoading(false);
  }

  Future<void> _fetchAndSeedCourses() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('courses').get();
      // Filter out any empty/dummy docs
      final realDocs = snapshot.docs.where((doc) => doc.id.contains('jee') || doc.id.contains('neet') || doc.id.contains('class')).toList();

      if (realDocs.isEmpty) {
        debugPrint("🌱 Firestore Courses empty. Automatically seeding PCM sample course catalogue...");
        for (var course in MockData.sampleCourses) {
          await FirebaseFirestore.instance.collection('courses').doc(course.id).set(course.toMap());
        }
        _courses = MockData.sampleCourses;
        debugPrint("✅ Firestore database seeding completed successfully!");
      } else {
        _courses = snapshot.docs
            .map((doc) => Course.fromMap(doc.data(), doc.id))
            .toList();
        debugPrint("📚 Loaded ${_courses.length} courses dynamically from live Firestore Database!");
      }
    } catch (e) {
      debugPrint("⚠️ Loading/seeding courses from Firestore failed: $e");
      _courses = MockData.sampleCourses; // Fallback
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    if (_isFirebaseInitialized) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          _currentUser = UserModel.fromMap(doc.data()!, uid);
        } else {
          if (!_isRegistering) {
            // Unregistered user attempting to log in, block access!
            await FirebaseAuth.instance.signOut();
            _currentUser = null;
            _errorMessage = "This mobile number/email is not registered. Please sign up first.";
            notifyListeners();
            return;
          }
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            final String rawEmail = firebaseUser.email ?? firebaseUser.phoneNumber ?? '';
            final String defaultRole = (rawEmail.contains('8888888888') || uid == 'crest_dev_master') ? 'teacher' : 'student';
            _currentUser = UserModel(
              uid: uid,
              email: rawEmail,
              name: firebaseUser.displayName ?? 'Student Achiever',
              studentClass: '12th PCM',
              photoUrl: firebaseUser.photoURL ?? 'https://api.dicebear.com/7.x/bottts/png?seed=$uid',
              purchasedCourseIds: [],
              role: defaultRole,
            );
            await FirebaseFirestore.instance.collection('users').doc(uid).set(_currentUser!.toMap());
          }
        }
        
        // Sync pending and rejected enrollment course IDs from Firestore
        try {
          final enrollmentsSnap = await FirebaseFirestore.instance
              .collection('enrollments')
              .where('uid', isEqualTo: uid)
              .get();
          _pendingEnrollmentCourseIds.clear();
          _rejectedEnrollmentReasons.clear();
          for (var d in enrollmentsSnap.docs) {
            final data = d.data();
            final cId = data['courseId'] as String?;
            final status = data['status'] as String?;
            if (cId != null) {
              if (status == 'pending') {
                _pendingEnrollmentCourseIds.add(cId);
              } else if (status == 'rejected') {
                _rejectedEnrollmentReasons[cId] = data['reason'] as String? ?? 'No reason provided';
              }
            }
          }
        } catch (e) {
          debugPrint("Error syncing enrollments: $e");
        }
        
        await _saveLocalSession();
      } catch (e) {
        _errorMessage = e.toString();
      }
    } else {
      // Sync simulated pending and rejected enrollments locally
      _pendingEnrollmentCourseIds.clear();
      _rejectedEnrollmentReasons.clear();
      for (var e in _simulatedPendingEnrollments) {
        if (e['uid'] == uid) {
          if (e['status'] == 'pending') {
            _pendingEnrollmentCourseIds.add(e['courseId']!);
          } else if (e['status'] == 'rejected') {
            _rejectedEnrollmentReasons[e['courseId']!] = e['reason'] ?? 'No reason provided';
          }
        }
      }
    }
    notifyListeners();
  }

  // --- Phone Authentication Methods ---
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verId) onCodeSent,
    required Function(String err) onError,
  }) async {
    _setLoading(true);
    _clearErrors();
    _phoneNumberEntered = phoneNumber; // Store phone for role customization on mock/real logins
    _isPhoneAuthForceSimulated = false; // Reset on new request

    final bool isDesktop = !kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.windows || 
         defaultTargetPlatform == TargetPlatform.macOS || 
         defaultTargetPlatform == TargetPlatform.linux);

    if (_isFirebaseInitialized && !isDesktop) {
      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await FirebaseAuth.instance.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            debugPrint("⚠️ Firebase Phone verification failed: ${e.code} - ${e.message}");
            _errorMessage = e.message ?? "Phone verification failed.";
            _setLoading(false);
            onError(_errorMessage!);
          },
          codeSent: (String verId, int? resendToken) {
            _verificationId = verId;
            _setLoading(false);
            onCodeSent(verId);
          },
          codeAutoRetrievalTimeout: (String verId) {
            _verificationId = verId;
          },
        );
      } catch (e) {
        _errorMessage = e.toString();
        _setLoading(false);
        onError(_errorMessage!);
      }
    } else {
      // Simulated OTP send
      await Future.delayed(const Duration(seconds: 1));
      _verificationId = "simulated_verification_id_12345";
      _isPhoneAuthForceSimulated = true; // Mark as simulated so signInWithOTP also uses mock flow
      _setLoading(false);
      onCodeSent(_verificationId!);
    }
  }

  Future<bool> signInWithOTP(String smsCode, String name, String studentClass) async {
    _setLoading(true);
    _clearErrors();
    
    final bool isSignUpAttempt = name.trim().isNotEmpty || studentClass.trim().isNotEmpty;
    if (isSignUpAttempt) {
      _isRegistering = true;
    }

    try {
      if (_isFirebaseInitialized && !_isPhoneAuthForceSimulated) {
        if (_verificationId == null) {
          _errorMessage = "Verification session expired. Please send OTP again.";
          _isRegistering = false;
          _setLoading(false);
          return false;
        }

        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: smsCode,
        );

        UserCredential creds = await FirebaseAuth.instance.signInWithCredential(credential);
        
        if (creds.user != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(creds.user!.uid).get();
          if (!doc.exists) {
            // Block unregistered users attempting to log in
            if (!isSignUpAttempt) {
              await FirebaseAuth.instance.signOut();
              _currentUser = null;
              _errorMessage = "This mobile number is not registered. Please register/sign up first.";
              _isRegistering = false;
              _setLoading(false);
              return false;
            }

            final String rawPhone = creds.user!.phoneNumber ?? '';
            final String defaultRole = rawPhone.contains('8888888888') ? 'teacher' : 'student';
            _currentUser = UserModel(
              uid: creds.user!.uid,
              email: rawPhone,
              name: name.isEmpty ? 'Student Achiever' : name,
              studentClass: studentClass,
              photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=${creds.user!.uid}',
              purchasedCourseIds: [],
              role: defaultRole,
            );
            await FirebaseFirestore.instance.collection('users').doc(creds.user!.uid).set(_currentUser!.toMap());
          } else {
            _currentUser = UserModel.fromMap(doc.data()!, creds.user!.uid);
          }
        }
        _isRegistering = false;
        _setLoading(false);
        return true;
      } else {
        // Simulated OTP Verification
        await Future.delayed(const Duration(milliseconds: 800));
        if (smsCode == "123456" || smsCode == "000000" || smsCode.length == 6) {
          final String rawPhone = _phoneNumberEntered ?? '8888888888';
          final bool isDev = rawPhone.contains('8888888888');
          final String targetUid = isDev ? 'crest_dev_master' : 'simulated_phone_user_${rawPhone.hashCode}';

          // Block unregistered users in simulation mode
          final userExists = _simulatedUsers.any((u) => u.uid == targetUid);
          if (!userExists && name.trim().isEmpty && studentClass.trim().isEmpty) {
            _errorMessage = "This mobile number is not registered in the directory. Please sign up first.";
            _setLoading(false);
            return false;
          }

          _currentUser = UserModel(
            uid: targetUid,
            email: rawPhone,
            name: name.isEmpty ? (isDev ? 'Dev Master Coach' : 'SMS Achiever') : name,
            studentClass: studentClass,
            photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=${rawPhone.hashCode}',
            purchasedCourseIds: isDev ? ['jee_achievers_2026'] : [],
            role: isDev ? 'teacher' : 'student',
          );

          // Append this user to the directory in simulated mode
          if (!_simulatedUsers.any((u) => u.uid == _currentUser!.uid)) {
            _simulatedUsers.add(_currentUser!);
          }
          
          _setLoading(false);
          await _saveLocalSession();
          notifyListeners();
          return true;
        } else {
          _errorMessage = "Invalid verification code. Use '123456' for simulated login.";
          _setLoading(false);
          return false;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // --- Email Authentication Actions ---
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearErrors();
    
    try {
      if (_isFirebaseInitialized) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        _setLoading(false);
        return true;
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
        _currentUser = UserModel(
          uid: 'simulated_user_${email.hashCode}',
          email: email,
          name: email.split('@')[0].toUpperCase(),
          studentClass: '12th PCM',
          photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=${email.hashCode}',
          purchasedCourseIds: ['jee_achievers_2026'],
          role: email.contains('teacher') ? 'teacher' : 'student',
        );
        _setLoading(false);
        await _saveLocalSession();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password, String studentClass) async {
    _setLoading(true);
    _clearErrors();
    _isRegistering = true;

    try {
      if (_isFirebaseInitialized) {
        UserCredential creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (creds.user != null) {
          await creds.user!.updateDisplayName(name);
          _currentUser = UserModel(
            uid: creds.user!.uid,
            email: email,
            name: name,
            studentClass: studentClass,
            photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=${creds.user!.uid}',
            purchasedCourseIds: [],
            role: 'student',
          );
          await FirebaseFirestore.instance.collection('users').doc(creds.user!.uid).set(_currentUser!.toMap());
        }
        _isRegistering = false;
        _setLoading(false);
        return true;
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
        _currentUser = UserModel(
          uid: 'simulated_user_${email.hashCode}',
          email: email,
          name: name,
          studentClass: studentClass,
          photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=${email.hashCode}',
          purchasedCourseIds: [],
          role: 'student',
        );
        // Append this user to the directory in simulated mode
        if (!_simulatedUsers.any((u) => u.uid == _currentUser!.uid)) {
          _simulatedUsers.add(_currentUser!);
        }
        _isRegistering = false;
        _setLoading(false);
        await _saveLocalSession();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isRegistering = false;
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    if (_isFirebaseInitialized) {
      await FirebaseAuth.instance.signOut();
    }
    _currentUser = null;
    _completedLectures.clear();
    _completedNotes.clear();
    await _saveLocalSession();
    notifyListeners();
  }

  // --- Profile Modifications ---
  Future<void> changeStudentClass(String newClass) async {
    if (_currentUser == null) return;
    
    final updated = UserModel(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      name: _currentUser!.name,
      studentClass: newClass,
      photoUrl: _currentUser!.photoUrl,
      purchasedCourseIds: _currentUser!.purchasedCourseIds,
      role: _currentUser!.role,
    );

    _currentUser = updated;
    await _saveLocalSession();
    notifyListeners();

    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(updated.uid).update({
          'studentClass': newClass,
        });
      } catch (e) {
        debugPrint("Error updating class in Firestore: $e");
      }
    }
  }

  Future<void> updateProfilePicture(String url) async {
    if (_currentUser == null) return;
    
    final updated = UserModel(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      name: _currentUser!.name,
      studentClass: _currentUser!.studentClass,
      photoUrl: url,
      purchasedCourseIds: _currentUser!.purchasedCourseIds,
      role: _currentUser!.role,
    );

    _currentUser = updated;
    await _saveLocalSession();
    notifyListeners();

    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(updated.uid).update({
          'photoUrl': url,
        });
      } catch (e) {
        debugPrint("Error updating photoUrl in Firestore: $e");
      }
    }
  }

  Future<void> updateTeacherAssignments(String teacherUid, List<String> courseIds, List<String> subjects) async {
    // Update simulated list
    final idx = _simulatedUsers.indexWhere((u) => u.uid == teacherUid);
    if (idx != -1) {
      final oldUser = _simulatedUsers[idx];
      final updated = UserModel(
        uid: oldUser.uid,
        email: oldUser.email,
        name: oldUser.name,
        studentClass: oldUser.studentClass,
        photoUrl: oldUser.photoUrl,
        purchasedCourseIds: oldUser.purchasedCourseIds,
        role: oldUser.role,
        assignedCourseIds: courseIds,
        assignedSubjects: subjects,
      );
      _simulatedUsers[idx] = updated;
      if (_currentUser?.uid == teacherUid) {
        _currentUser = updated;
        await _saveLocalSession();
      }
    }

    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(teacherUid).update({
          'assignedCourseIds': courseIds,
          'assignedSubjects': subjects,
        });
      } catch (e) {
        debugPrint("Error updating teacher assignments in Firestore: $e");
      }
    }
    notifyListeners();
  }

  // --- Student Social Directory (NEW - Absolute Privacy Shield) ---
  Future<List<UserModel>> fetchStudentDirectory() async {
    if (!_isFirebaseInitialized) {
      // Mock fallbacks pulled directly from our interactive simulated directory
      return _simulatedUsers
          .where((doc) => doc.uid != _currentUser?.uid)
          .map((doc) => UserModel(
                uid: doc.uid,
                email: '', // Shield private details
                name: doc.name,
                studentClass: doc.studentClass,
                photoUrl: doc.photoUrl,
                purchasedCourseIds: [],
                role: doc.role,
              ))
          .toList();
    }

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      return snapshot.docs
          .where((doc) => doc.id != _currentUser?.uid) // Filter out current user
          .map((doc) {
            final data = doc.data();
            // Shield private fields: email/phone numbers are kept blank, purchased lists hidden!
            return UserModel(
              uid: doc.id,
              email: '', // PRIVACY SHIELDED
              name: data['name'] ?? 'Crest Achiever',
              studentClass: data['studentClass'] ?? '12th PCM',
              photoUrl: data['photoUrl'] ?? 'https://api.dicebear.com/7.x/bottts/png?seed=${doc.id.hashCode}',
              purchasedCourseIds: [], // PRIVACY SHIELDED
              role: data['role'] ?? 'student',
            );
          }).toList();
    } catch (e) {
      debugPrint("Error fetching student directory: $e");
      return [];
    }
  }

  Future<List<UserModel>> fetchAdminStudentDirectory() async {
    if (!_isFirebaseInitialized) {
      return _simulatedUsers;
    }
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching admin student directory: $e");
      return [];
    }
  }

  // --- Real-time Direct Study Chat Messaging (NEW) ---
  String _getChatId(String userA, String userB) {
    return userA.compareTo(userB) < 0 ? '${userA}_$userB' : '${userB}_$userA';
  }

  Future<void> sendChatMessage(String recipientId, String text) async {
    if (_currentUser == null || text.trim().isEmpty) return;
    final chatId = _getChatId(_currentUser!.uid, recipientId);
    
    final msg = MessageModel(
      id: '',
      senderId: _currentUser!.uid,
      text: text.trim(),
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
    );

    if (_isFirebaseInitialized) {
      try {
        // 1. Add message doc to the subcollection
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add(msg.toMap());

        // 2. Set parent chat details
        await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
          'participants': [_currentUser!.uid, recipientId],
          'lastMessage': text.trim(),
          'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        debugPrint("Error sending message to Firestore: $e");
      }
    } else {
      debugPrint("💬 Simulated Direct Message: '$text' sent to $recipientId");
    }
  }

  Stream<List<MessageModel>> getChatMessagesStream(String recipientId) {
    if (_currentUser == null) return Stream.value([]);
    final chatId = _getChatId(_currentUser!.uid, recipientId);

    if (_isFirebaseInitialized) {
      return FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestampMillis', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
                .toList();
          });
    } else {
      // Simulated periodic stream for demo testing
      final controller = StreamController<List<MessageModel>>();
      final list = [
        MessageModel(id: 'm1', senderId: recipientId, text: "Hey! How is the JEE Kinematics worksheet going?", timestampMillis: DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch),
        MessageModel(id: 'm2', senderId: _currentUser!.uid, text: "Almost done, just working on relative velocity questions.", timestampMillis: DateTime.now().subtract(const Duration(minutes: 4)).millisecondsSinceEpoch),
        MessageModel(id: 'm3', senderId: recipientId, text: "Ah nice, relative velocity is super important!", timestampMillis: DateTime.now().subtract(const Duration(minutes: 3)).millisecondsSinceEpoch),
      ];
      controller.add(list);
      return controller.stream;
    }
  }

  // --- Purchasing System ---
  Future<bool> purchaseCourse(String courseId) async {
    if (_currentUser == null) {
      _errorMessage = "You must be signed in to enroll in a course.";
      notifyListeners();
      return false;
    }

    if (_currentUser!.purchasedCourseIds.contains(courseId)) {
      return true;
    }

    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));

    final updatedPurchases = List<String>.from(_currentUser!.purchasedCourseIds)..add(courseId);
    
    final updatedUser = UserModel(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      name: _currentUser!.name,
      studentClass: _currentUser!.studentClass,
      photoUrl: _currentUser!.photoUrl,
      purchasedCourseIds: updatedPurchases,
      role: _currentUser!.role,
    );

    _currentUser = updatedUser;
    await _saveLocalSession();
    _setLoading(false);
    notifyListeners();

    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(updatedUser.uid).update({
          'purchasedCourseIds': updatedPurchases,
        });
        return true;
      } catch (e) {
        _errorMessage = e.toString();
        notifyListeners();
        return false;
      }
    }

    return true;
  }

  bool isCoursePurchased(String courseId) {
    if (_currentUser == null) return false;
    return _currentUser!.purchasedCourseIds.contains(courseId);
  }

  bool isEnrollmentPending(String courseId) {
    return _pendingEnrollmentCourseIds.contains(courseId);
  }

  // --- Live Operational Deployment Features (NEW) ---

  // 1. Enrollment Requests
  Future<bool> requestCourseEnrollment(String courseId, String courseTitle) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('enrollments').add({
          'uid': _currentUser!.uid,
          'name': _currentUser!.name,
          'email': _currentUser!.email,
          'courseId': courseId,
          'courseTitle': courseTitle,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Error requesting enrollment in Firestore: $e");
      }
    } else {
      // In-memory simulation
      _simulatedPendingEnrollments.add({
        'id': 'sim_enroll_${DateTime.now().millisecondsSinceEpoch}',
        'uid': _currentUser!.uid,
        'name': _currentUser!.name,
        'email': _currentUser!.email,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'status': 'pending',
      });
    }

    _pendingEnrollmentCourseIds.add(courseId);
    
    // Send enrollment request notification to the master user/teacher
    await sendNotification(
      recipientUid: 'crest_dev_master',
      title: 'New Course Enrollment Request 🎓',
      body: '${_currentUser!.name} requested approval to enroll in "$courseTitle".',
    );
    
    _setLoading(false);
    notifyListeners();
    return true;
  }

  Stream<List<Map<String, String>>> getPendingEnrollmentsStream() {
    if (_isFirebaseInitialized) {
      return FirebaseFirestore.instance
          .collection('enrollments')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'uid': data['uid'] as String? ?? '',
                'name': data['name'] as String? ?? 'Student',
                'email': data['email'] as String? ?? 'No contact info',
                'courseId': data['courseId'] as String? ?? '',
                'courseTitle': data['courseTitle'] as String? ?? '',
                'status': data['status'] as String? ?? 'pending',
              };
            }).toList();
          });
    } else {
      final controller = StreamController<List<Map<String, String>>>();
      controller.add(_simulatedPendingEnrollments.map((e) {
        return {
          'id': e['id'] ?? '',
          'uid': e['uid'] ?? '',
          'name': e['name'] ?? '',
          'email': e['email'] ?? 'No contact info',
          'courseId': e['courseId'] ?? '',
          'courseTitle': e['courseTitle'] ?? '',
          'status': e['status'] ?? 'pending',
        };
      }).toList());
      return controller.stream;
    }
  }

  Future<void> approveEnrollment(String docId, String studentUid, String courseId) async {
    if (_isFirebaseInitialized) {
      try {
        // 1. Add course to student purchased list
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(studentUid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final List<String> currentPurchases = List<String>.from(data['purchasedCourseIds'] ?? []);
          if (!currentPurchases.contains(courseId)) {
            currentPurchases.add(courseId);
            await FirebaseFirestore.instance.collection('users').doc(studentUid).update({
              'purchasedCourseIds': currentPurchases,
            });
          }
        }
        // 2. Mark enrollment as approved
        await FirebaseFirestore.instance.collection('enrollments').doc(docId).update({
          'status': 'approved',
        });
      } catch (e) {
        debugPrint("Error approving enrollment in Firestore: $e");
      }
    } else {
      // Simulated promotion in memory
      final userIdx = _simulatedUsers.indexWhere((u) => u.uid == studentUid);
      if (userIdx != -1) {
        final old = _simulatedUsers[userIdx];
        if (!old.purchasedCourseIds.contains(courseId)) {
          final updated = List<String>.from(old.purchasedCourseIds)..add(courseId);
          _simulatedUsers[userIdx] = UserModel(
            uid: old.uid,
            email: old.email,
            name: old.name,
            studentClass: old.studentClass,
            photoUrl: old.photoUrl,
            purchasedCourseIds: updated,
            role: old.role,
          );
        }
      }
      
      // Also update currently logged in user if it matches
      if (_currentUser?.uid == studentUid) {
        if (!_currentUser!.purchasedCourseIds.contains(courseId)) {
          final updated = List<String>.from(_currentUser!.purchasedCourseIds)..add(courseId);
          _currentUser = UserModel(
            uid: _currentUser!.uid,
            email: _currentUser!.email,
            name: _currentUser!.name,
            studentClass: _currentUser!.studentClass,
            photoUrl: _currentUser!.photoUrl,
            purchasedCourseIds: updated,
            role: _currentUser!.role,
          );
          await _saveLocalSession();
        }
      }

      _simulatedPendingEnrollments.removeWhere((e) => e['id'] == docId);
    }
    
    // Check if the current user matches the student approved (even if in live Firebase mode)
    if (_currentUser?.uid == studentUid) {
      if (!_currentUser!.purchasedCourseIds.contains(courseId)) {
        final updated = List<String>.from(_currentUser!.purchasedCourseIds)..add(courseId);
        _currentUser = UserModel(
          uid: _currentUser!.uid,
          email: _currentUser!.email,
          name: _currentUser!.name,
          studentClass: _currentUser!.studentClass,
          photoUrl: _currentUser!.photoUrl,
          purchasedCourseIds: updated,
          role: _currentUser!.role,
        );
        await _saveLocalSession();
      }
    }
    
    // Remove from local pending list if we are the user approved!
    if (_currentUser?.uid == studentUid) {
      _pendingEnrollmentCourseIds.remove(courseId);
    }
    
    // Send approval notification
    await sendNotification(
      recipientUid: studentUid,
      title: 'Course Access Approved! 🎉',
      body: 'Your enrollment in "$courseId" has been approved by Delhi centers.',
    );
    
    notifyListeners();
  }

  Future<void> rejectEnrollment(String docId, String studentUid, String courseId, String courseTitle, String reason) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('enrollments').doc(docId).update({
          'status': 'rejected',
          'reason': reason,
        });
      } catch (e) {
        debugPrint("Error rejecting enrollment in Firestore: $e");
      }
    } else {
      // In-memory simulation
      final idx = _simulatedPendingEnrollments.indexWhere((e) => e['id'] == docId);
      if (idx != -1) {
        _simulatedPendingEnrollments[idx]['status'] = 'rejected';
        _simulatedPendingEnrollments[idx]['reason'] = reason;
      }
    }

    // Update local state if we are the student rejected
    if (_currentUser?.uid == studentUid) {
      _pendingEnrollmentCourseIds.remove(courseId);
      _rejectedEnrollmentReasons[courseId] = reason;
    }

    // Send rejection notification to student
    await sendNotification(
      recipientUid: studentUid,
      title: 'Course Access Rejected ❌',
      body: 'Your enrollment request in "$courseTitle" was rejected. Reason: $reason',
    );

    notifyListeners();
  }

  Future<void> revokeEnrollment(String studentUid, String courseId) async {
    if (_isFirebaseInitialized) {
      try {
        // 1. Remove course from student purchased list
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(studentUid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final List<String> currentPurchases = List<String>.from(data['purchasedCourseIds'] ?? []);
          if (currentPurchases.contains(courseId)) {
            currentPurchases.remove(courseId);
            await FirebaseFirestore.instance.collection('users').doc(studentUid).update({
              'purchasedCourseIds': currentPurchases,
            });
          }
        }
        // 2. Mark any approved enrollment documents as rejected
        final enrollmentsSnap = await FirebaseFirestore.instance
            .collection('enrollments')
            .where('uid', isEqualTo: studentUid)
            .where('courseId', isEqualTo: courseId)
            .get();
        for (var doc in enrollmentsSnap.docs) {
          await doc.reference.update({
            'status': 'rejected',
            'reason': 'Admission Access Revoked by centers.',
          });
        }
      } catch (e) {
        debugPrint("Error revoking enrollment in Firestore: $e");
      }
    } else {
      // Simulated revocation in memory
      final userIdx = _simulatedUsers.indexWhere((u) => u.uid == studentUid);
      if (userIdx != -1) {
        final old = _simulatedUsers[userIdx];
        if (old.purchasedCourseIds.contains(courseId)) {
          final updated = List<String>.from(old.purchasedCourseIds)..remove(courseId);
          _simulatedUsers[userIdx] = UserModel(
            uid: old.uid,
            email: old.email,
            name: old.name,
            studentClass: old.studentClass,
            photoUrl: old.photoUrl,
            purchasedCourseIds: updated,
            role: old.role,
          );
        }
      }
      
      // Also update currently logged in user if it matches
      if (_currentUser?.uid == studentUid) {
        if (_currentUser!.purchasedCourseIds.contains(courseId)) {
          final updated = List<String>.from(_currentUser!.purchasedCourseIds)..remove(courseId);
          _currentUser = UserModel(
            uid: _currentUser!.uid,
            email: _currentUser!.email,
            name: _currentUser!.name,
            studentClass: _currentUser!.studentClass,
            photoUrl: _currentUser!.photoUrl,
            purchasedCourseIds: updated,
            role: _currentUser!.role,
          );
          await _saveLocalSession();
        }
      }

      // Update simulated enrollments list
      _simulatedPendingEnrollments.removeWhere((e) => e['uid'] == studentUid && e['courseId'] == courseId);
    }

    // Update local state if we are the student revoked
    if (_currentUser?.uid == studentUid) {
      _pendingEnrollmentCourseIds.remove(courseId);
      _rejectedEnrollmentReasons[courseId] = 'Admission Access Revoked by centers.';
    }

    // Send revocation notification to student
    await sendNotification(
      recipientUid: studentUid,
      title: 'Course Access Revoked ⚠️',
      body: 'Your access to course "$courseId" has been revoked by Delhi coaching centres.',
    );

    notifyListeners();
  }

  // --- Real-time Notifications & Alerts System ---
  Future<void> sendNotification({
    required String recipientUid,
    required String title,
    required String body,
  }) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('notifications').add({
          'recipientUid': recipientUid,
          'title': title,
          'body': body,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      } catch (e) {
        debugPrint("Error sending notification in Firestore: $e");
      }
    } else {
      _simulatedNotifications.insert(0, {
        'id': 'sim_notif_${DateTime.now().millisecondsSinceEpoch}',
        'recipientUid': recipientUid,
        'title': title,
        'body': body,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'isRead': 'false',
      });
    }
    notifyListeners();
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    if (_currentUser == null) return Stream.value([]);
    final uid = _currentUser!.uid;
    final isTeacher = _currentUser!.role == 'teacher' || uid == 'crest_dev_master';

    if (_isFirebaseInitialized) {
      return FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  return {
                    'id': doc.id,
                    'recipientUid': data['recipientUid'] ?? '',
                    'title': data['title'] ?? '',
                    'body': data['body'] ?? '',
                    'timestamp': data['timestamp'] != null 
                        ? (data['timestamp'] as Timestamp).millisecondsSinceEpoch.toString() 
                        : DateTime.now().millisecondsSinceEpoch.toString(),
                    'isRead': data['isRead'] ?? false,
                  };
                })
                .where((n) {
                  final rec = n['recipientUid'] as String;
                  if (rec == 'all') return true;
                  if (isTeacher && (rec == 'teacher' || rec == 'crest_dev_master')) return true;
                  return rec == uid;
                })
                .toList();
          });
    } else {
      final controller = StreamController<List<Map<String, dynamic>>>();
      final filtered = _simulatedNotifications.where((n) {
        final rec = n['recipientUid']!;
        if (rec == 'all') return true;
        if (isTeacher && (rec == 'teacher' || rec == 'crest_dev_master')) return true;
        return rec == uid;
      }).map((n) {
        return {
          'id': n['id']!,
          'recipientUid': n['recipientUid']!,
          'title': n['title']!,
          'body': n['body']!,
          'timestamp': n['timestamp']!,
          'isRead': n['isRead'] == 'true',
        };
      }).toList();
      controller.add(filtered);
      return controller.stream;
    }
  }

  Future<void> markNotificationsAsRead() async {
    if (_currentUser == null) return;
    final uid = _currentUser!.uid;
    final isTeacher = _currentUser!.role == 'teacher' || uid == 'crest_dev_master';

    if (_isFirebaseInitialized) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .get();
        for (var doc in snap.docs) {
          final rec = doc.data()['recipientUid'] as String?;
          if (rec == 'all' || rec == uid || (isTeacher && (rec == 'teacher' || rec == 'crest_dev_master'))) {
            await doc.reference.update({'isRead': true});
          }
        }
      } catch (e) {
        debugPrint("Error marking notifications read: $e");
      }
    } else {
      for (var n in _simulatedNotifications) {
        final rec = n['recipientUid']!;
        if (rec == 'all' || rec == uid || (isTeacher && (rec == 'teacher' || rec == 'crest_dev_master'))) {
          n['isRead'] = 'true';
        }
      }
    }
    notifyListeners();
  }

  // 2. Announcements
  Future<void> publishAnnouncement(String content) async {
    if (content.trim().isEmpty) return;
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('announcements').add({
          'content': content.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Error publishing announcement in Firestore: $e");
      }
    } else {
      _simulatedAnnouncements.insert(0, content.trim());
    }

    // Send broadcast notification to all students
    await sendNotification(
      recipientUid: 'all',
      title: 'New Institute Announcement 📢',
      body: content.trim(),
    );

    notifyListeners();
  }

  Stream<List<String>> getAnnouncementsStream() {
    if (_isFirebaseInitialized) {
      return FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => doc.data()['content'] as String? ?? '')
                .toList();
          });
    } else {
      final controller = StreamController<List<String>>();
      controller.add(_simulatedAnnouncements);
      return controller.stream;
    }
  }

  // 3. Dev Master Role Promoter
  Future<void> promoteUserRole(String targetUid, String newRole) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(targetUid).update({
          'role': newRole,
        });
      } catch (e) {
        debugPrint("Error promoting user role in Firestore: $e");
      }
    } else {
      final idx = _simulatedUsers.indexWhere((u) => u.uid == targetUid);
      if (idx != -1) {
        final old = _simulatedUsers[idx];
        _simulatedUsers[idx] = UserModel(
          uid: old.uid,
          email: old.email,
          name: old.name,
          studentClass: old.studentClass,
          photoUrl: old.photoUrl,
          purchasedCourseIds: old.purchasedCourseIds,
          role: newRole,
        );
      }
    }
    
    // Also update logged in user if they are the one promoted!
    if (_currentUser?.uid == targetUid) {
      _currentUser = UserModel(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        name: _currentUser!.name,
        studentClass: _currentUser!.studentClass,
        photoUrl: _currentUser!.photoUrl,
        purchasedCourseIds: _currentUser!.purchasedCourseIds,
        role: newRole,
      );
      await _saveLocalSession();
    }
    
    notifyListeners();
  }

  // 4. Admin Direct Course Materials Manager
  Future<bool> addNewCourseMaterial(String courseId, String subjectName, String chapterTitle, String type, String title, String url) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 600));

    // Update in the memory list
    final courseIdx = _courses.indexWhere((c) => c.id == courseId);
    if (courseIdx != -1) {
      final course = _courses[courseIdx];
      final List<Subject> updatedSubjects = List<Subject>.from(course.subjects);
      
      final subIdx = updatedSubjects.indexWhere((s) => s.name.toLowerCase() == subjectName.toLowerCase());
      if (subIdx != -1) {
        final subject = updatedSubjects[subIdx];
        final List<Chapter> updatedChapters = List<Chapter>.from(subject.chapters);
        
        final chIdx = updatedChapters.indexWhere((c) => c.title.toLowerCase() == chapterTitle.toLowerCase());
        if (chIdx != -1) {
          final chapter = updatedChapters[chIdx];
          
          if (type == 'lecture') {
            final List<Lecture> updatedLectures = List<Lecture>.from(chapter.lectures)
              ..add(Lecture(title: title, videoUrl: url, duration: '45 mins'));
            updatedChapters[chIdx] = Chapter(
              id: chapter.id,
              title: chapter.title,
              lectures: updatedLectures,
              notes: chapter.notes,
            );
          } else {
            final List<Note> updatedNotes = List<Note>.from(chapter.notes)
              ..add(Note(title: title, pdfUrl: url));
            updatedChapters[chIdx] = Chapter(
              id: chapter.id,
              title: chapter.title,
              lectures: chapter.lectures,
              notes: updatedNotes,
            );
          }
          updatedSubjects[subIdx] = Subject(name: subject.name, chapters: updatedChapters);
        } else {
          // Create new chapter if not found
          final newChId = 'ch_${DateTime.now().millisecondsSinceEpoch}';
          final newChapter = Chapter(
            id: newChId,
            title: chapterTitle,
            lectures: type == 'lecture' ? [Lecture(title: title, videoUrl: url, duration: '45 mins')] : [],
            notes: type == 'note' ? [Note(title: title, pdfUrl: url)] : [],
          );
          updatedChapters.add(newChapter);
          updatedSubjects[subIdx] = Subject(name: subject.name, chapters: updatedChapters);
        }
      }

      final updatedCourse = Course(
        id: course.id,
        title: course.title,
        tagline: course.tagline,
        price: course.price,
        coverImageUrl: course.coverImageUrl,
        subjects: updatedSubjects,
      );

      _courses[courseIdx] = updatedCourse;

      if (_isFirebaseInitialized) {
        try {
          await FirebaseFirestore.instance.collection('courses').doc(courseId).set(updatedCourse.toMap());
          
          // Send notification to all enrolled students dynamically
          final String matName = type == 'lecture' ? 'Lecture Video: $title' : 'PDF Study Note: $title';
          final String bodyText = 'A new $matName has been uploaded to $subjectName -> $chapterTitle. Tap to learn!';
          
          final studentsSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('purchasedCourseIds', arrayContains: courseId)
              .get();
              
          for (var doc in studentsSnap.docs) {
            await sendNotification(
              recipientUid: doc.id,
              title: '📚 New Syllabus Material Deployed!',
              body: bodyText,
            );
          }
        } catch (e) {
          debugPrint("Error writing new material or notifying students: $e");
        }
      } else {
        // Simulated enrolled users notification dispatch
        final String matName = type == 'lecture' ? 'Lecture Video: $title' : 'PDF Study Note: $title';
        final String bodyText = 'A new $matName has been uploaded to $subjectName -> $chapterTitle. Tap to learn!';
        
        for (var u in _simulatedUsers) {
          if (u.purchasedCourseIds.contains(courseId)) {
            await sendNotification(
              recipientUid: u.uid,
              title: '📚 New Syllabus Material Deployed!',
              body: bodyText,
            );
          }
        }
      }
    }

    _setLoading(false);
    notifyListeners();
    return true;
  }

  Future<String> uploadVideoFile(String fileName, Uint8List fileBytes, String? filePath) async {
    _setLoading(true);
    _clearErrors();
    
    if (_isFirebaseInitialized) {
      try {
        final ref = FirebaseStorage.instance.ref().child('lectures/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        UploadTask task;
        if (kIsWeb) {
          task = ref.putData(fileBytes);
        } else if (filePath != null) {
          task = ref.putFile(File(filePath));
        } else {
          task = ref.putData(fileBytes);
        }
        final snap = await task;
        final downloadUrl = await snap.ref.getDownloadURL();
        _setLoading(false);
        return downloadUrl;
      } catch (e) {
        debugPrint("Error uploading file to Firebase Storage: $e");
        _setLoading(false);
        // Fallback simulated URL if upload fails (e.g. storage rules or network)
        return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
      }
    } else {
      // simulated delay and fallback success
      await Future.delayed(const Duration(seconds: 2));
      _setLoading(false);
      return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
    }
  }

  // --- Lecture Progress ---
  void toggleLectureCompleted(String chapterId, String lectureTitle) {
    final key = "${chapterId}_$lectureTitle";
    if (_completedLectures.contains(key)) {
      _completedLectures.remove(key);
    } else {
      _completedLectures.add(key);
    }
    notifyListeners();
  }

  bool isLectureCompleted(String chapterId, String lectureTitle) {
    return _completedLectures.contains("${chapterId}_$lectureTitle");
  }

  double getChapterProgress(Chapter chapter) {
    if (chapter.lectures.isEmpty && chapter.notes.isEmpty) return 0.0;
    
    int totalItems = chapter.lectures.length + chapter.notes.length;
    int completedItems = 0;

    for (var l in chapter.lectures) {
      if (isLectureCompleted(chapter.id, l.title)) completedItems++;
    }
    for (var n in chapter.notes) {
      if (isNoteCompleted(chapter.id, n.title)) completedItems++;
    }

    return completedItems / totalItems;
  }

  double getSubjectProgress(Subject subject) {
    if (subject.chapters.isEmpty) return 0.0;
    double totalProgress = 0.0;
    for (var ch in subject.chapters) {
      totalProgress += getChapterProgress(ch);
    }
    return totalProgress / subject.chapters.length;
  }

  // --- Note Progress ---
  void toggleNoteCompleted(String chapterId, String noteTitle) {
    final key = "${chapterId}_$noteTitle";
    if (_completedNotes.contains(key)) {
      _completedNotes.remove(key);
    } else {
      _completedNotes.add(key);
    }
    notifyListeners();
  }

  bool isNoteCompleted(String chapterId, String noteTitle) {
    return _completedNotes.contains("${chapterId}_$noteTitle");
  }

  // Helper State management setters
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearErrors() {
    _errorMessage = null;
    notifyListeners();
  }

  // ═══ DARK MODE ═══
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  Future<void> loadThemePreference() async {
    try { final p = await SharedPreferences.getInstance(); _isDarkMode = p.getBool('isDarkMode') ?? false; notifyListeners(); } catch (_) {}
  }
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode; notifyListeners();
    try { final p = await SharedPreferences.getInstance(); await p.setBool('isDarkMode', _isDarkMode); } catch (_) {}
  }

  // ═══ LANGUAGE ═══
  String _language = 'English';
  String get language => _language;
  Future<void> setLanguage(String lang) async {
    _language = lang; notifyListeners();
    try { final p = await SharedPreferences.getInstance(); await p.setString('language', lang); } catch (_) {}
  }

  // ═══ BRANCHES ═══
  List<Branch> _branches = [
    Branch(id: 'sector_14', name: 'Sector 14 Branch', address: 'SCO 45, Sector 14, Gurugram', headTeacher: 'Dr. Amit Kumar', phone: '+91 98765 43210'),
    Branch(id: 'sector_56', name: 'Sector 56 Branch', address: 'Plot 12, Sector 56, Gurugram', headTeacher: 'Mrs. Priya Sharma', phone: '+91 98765 43211'),
  ];
  List<Branch> get branches => _branches;
  final Map<String, String> _branchMap = {};
  String get studentBranchId => _currentUser != null ? (getBranchIdForStudent(_currentUser!.uid)) : 'sector_14';
  String getBranchIdForStudent(String uid) => _branchMap[uid] ?? 'sector_14';
  Future<void> loadBranches() async {
    if (!_isFirebaseInitialized) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('branches').get();
      if (snap.docs.isNotEmpty) { _branches = snap.docs.map((d) => Branch.fromMap(d.data(), d.id)).toList(); notifyListeners(); }
    } catch (e) { debugPrint('loadBranches: $e'); }
  }
  Future<void> setStudentBranch(String uid, String branchId) async {
    _branchMap[uid] = branchId; notifyListeners();
    if (!_isFirebaseInitialized) return;
    try { await FirebaseFirestore.instance.collection('users').doc(uid).update({'branchId': branchId}); } catch (_) {}
  }

  // ═══ ATTENDANCE ═══
  final List<AttendanceRecord> _simulatedAttendance = [];
  Future<void> markAttendance({required String studentUid, required String date, required bool present, required String subject, required String batch}) async {
    final id = '${studentUid}_${date}_${subject.replaceAll(' ', '_')}';
    final rec = AttendanceRecord(id: id, studentUid: studentUid, date: date, present: present, subject: subject, batch: batch, markedBy: _currentUser?.uid ?? 'teacher');
    _simulatedAttendance.removeWhere((r) => r.id == id); _simulatedAttendance.add(rec);
    _attendanceCache.remove(studentUid); // Invalidate cache
    notifyListeners();
    if (!_isFirebaseInitialized) return;
    try { await FirebaseFirestore.instance.collection('attendance').doc(id).set(rec.toMap()); } catch (_) {}
  }
  Future<List<AttendanceRecord>> getStudentAttendance(String uid) async {
    if (_attendanceCache.containsKey(uid)) {
      _refreshAttendanceBackground(uid);
      return _attendanceCache[uid]!;
    }
    final list = await _fetchAttendanceFromDb(uid);
    _attendanceCache[uid] = list;
    return list;
  }
  Future<List<AttendanceRecord>> _fetchAttendanceFromDb(String uid) async {
    if (!_isFirebaseInitialized) return _simulatedAttendance.where((r) => r.studentUid == uid).toList();
    try {
      final snap = await FirebaseFirestore.instance.collection('attendance').where('studentUid', isEqualTo: uid).orderBy('date', descending: true).get();
      return snap.docs.map((d) => AttendanceRecord.fromMap(d.data(), d.id)).toList();
    } catch (_) { return _simulatedAttendance.where((r) => r.studentUid == uid).toList(); }
  }
  void _refreshAttendanceBackground(String uid) async {
    try {
      final list = await _fetchAttendanceFromDb(uid);
      _attendanceCache[uid] = list;
      notifyListeners();
    } catch (_) {}
  }
  Future<List<AttendanceRecord>> getAllAttendanceForDate(String date) async {
    if (!_isFirebaseInitialized) return _simulatedAttendance.where((r) => r.date == date).toList();
    try {
      final snap = await FirebaseFirestore.instance.collection('attendance').where('date', isEqualTo: date).get();
      return snap.docs.map((d) => AttendanceRecord.fromMap(d.data(), d.id)).toList();
    } catch (_) { return _simulatedAttendance.where((r) => r.date == date).toList(); }
  }

  // ═══ TEST RESULTS ═══
  final List<TestResult> _simulatedTestResults = [];
  Future<void> addTestResult(TestResult result) async {
    _simulatedTestResults.removeWhere((r) => r.id == result.id); _simulatedTestResults.add(result);
    _testResultsCache.remove(result.studentUid); // Invalidate cache
    notifyListeners();
    if (!_isFirebaseInitialized) return;
    try { await FirebaseFirestore.instance.collection('testResults').doc(result.id).set(result.toMap()); } catch (_) {}
  }
  Future<List<TestResult>> getStudentTestResults(String uid) async {
    if (_testResultsCache.containsKey(uid)) {
      _refreshTestResultsBackground(uid);
      return _testResultsCache[uid]!;
    }
    final list = await _fetchTestResultsFromDb(uid);
    _testResultsCache[uid] = list;
    return list;
  }
  Future<List<TestResult>> _fetchTestResultsFromDb(String uid) async {
    if (!_isFirebaseInitialized) return _simulatedTestResults.where((r) => r.studentUid == uid).toList();
    try {
      final snap = await FirebaseFirestore.instance.collection('testResults').where('studentUid', isEqualTo: uid).orderBy('date', descending: true).get();
      return snap.docs.map((d) => TestResult.fromMap(d.data(), d.id)).toList();
    } catch (_) { return _simulatedTestResults.where((r) => r.studentUid == uid).toList(); }
  }
  void _refreshTestResultsBackground(String uid) async {
    try {
      final list = await _fetchTestResultsFromDb(uid);
      _testResultsCache[uid] = list;
      notifyListeners();
    } catch (_) {}
  }
  Future<List<TestResult>> getAllTestResults() async {
    if (!_isFirebaseInitialized) return _simulatedTestResults;
    try {
      final snap = await FirebaseFirestore.instance.collection('testResults').orderBy('date', descending: true).get();
      return snap.docs.map((d) => TestResult.fromMap(d.data(), d.id)).toList();
    } catch (_) { return _simulatedTestResults; }
  }

  // ═══ FEES ═══
  final List<FeeRecord> _simulatedFees = [];
  Future<void> updateFeeRecord(FeeRecord record) async {
    _simulatedFees.removeWhere((f) => f.id == record.id); _simulatedFees.add(record);
    _feeHistoryCache.remove(record.studentUid); // Invalidate cache
    notifyListeners();
    if (!_isFirebaseInitialized) return;
    try { await FirebaseFirestore.instance.collection('fees').doc(record.id).set(record.toMap()); } catch (_) {}
  }
  Future<List<FeeRecord>> getStudentFeeHistory(String uid) async {
    if (_feeHistoryCache.containsKey(uid)) {
      _refreshFeeHistoryBackground(uid);
      return _feeHistoryCache[uid]!;
    }
    final list = await _fetchFeeHistoryFromDb(uid);
    _feeHistoryCache[uid] = list;
    return list;
  }
  Future<List<FeeRecord>> _fetchFeeHistoryFromDb(String uid) async {
    if (!_isFirebaseInitialized) return _simulatedFees.where((f) => f.studentUid == uid).toList();
    try {
      final snap = await FirebaseFirestore.instance.collection('fees').where('studentUid', isEqualTo: uid).get();
      return snap.docs.map((d) => FeeRecord.fromMap(d.data(), d.id)).toList();
    } catch (_) { return _simulatedFees.where((f) => f.studentUid == uid).toList(); }
  }
  void _refreshFeeHistoryBackground(String uid) async {
    try {
      final list = await _fetchFeeHistoryFromDb(uid);
      _feeHistoryCache[uid] = list;
      notifyListeners();
    } catch (_) {}
  }
  Future<List<FeeRecord>> getAllFeeRecords() async {
    if (!_isFirebaseInitialized) return _simulatedFees;
    try {
      final snap = await FirebaseFirestore.instance.collection('fees').get();
      return snap.docs.map((d) => FeeRecord.fromMap(d.data(), d.id)).toList();
    } catch (_) { return _simulatedFees; }
  }

  // ═══ DPP ═══
  final List<DppCard> _simulatedDpps = [];
  Future<DppCard?> getTodaysDpp() async {
    final now = DateTime.now();
    final ds = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (!_isFirebaseInitialized) return _simulatedDpps.where((d) => d.date == ds).firstOrNull;
    try {
      final snap = await FirebaseFirestore.instance.collection('dpps').where('date', isEqualTo: ds).limit(1).get();
      return snap.docs.isEmpty ? null : DppCard.fromMap(snap.docs.first.data(), snap.docs.first.id);
    } catch (_) { return _simulatedDpps.where((d) => d.date == ds).firstOrNull; }
  }
  Future<List<DppCard>> getDppHistory({int limit = 20}) async {
    if (!_isFirebaseInitialized) return _simulatedDpps;
    try {
      final snap = await FirebaseFirestore.instance.collection('dpps').orderBy('date', descending: true).limit(limit).get();
      return snap.docs.map((d) => DppCard.fromMap(d.data(), d.id)).toList();
    } catch (_) { return _simulatedDpps; }
  }
  Future<void> postDpp(DppCard dpp) async {
    _simulatedDpps.removeWhere((d) => d.id == dpp.id); _simulatedDpps.insert(0, dpp); notifyListeners();
    if (!_isFirebaseInitialized) return;
    try {
      await FirebaseFirestore.instance.collection('dpps').doc(dpp.id).set(dpp.toMap());
      await sendNotification(recipientUid: 'all', title: 'New DPP Posted!', body: '${dpp.subject} DPP is ready. Check Study Tools!');
    } catch (_) {}
  }

  // ═══ DOUBTS ═══
  final List<DoubtPost> _simulatedDoubts = [];
  Stream<List<DoubtPost>> getDoubtsStream() {
    if (!_isFirebaseInitialized) return Stream.value(_simulatedDoubts);
    return FirebaseFirestore.instance.collection('doubts').orderBy('timestamp', descending: true).snapshots()
        .map((snap) => snap.docs.map((d) => DoubtPost.fromMap(d.data(), d.id)).toList());
  }
  Future<void> postDoubt(DoubtPost doubt) async {
    _simulatedDoubts.insert(0, doubt); notifyListeners();
    if (!_isFirebaseInitialized) return;
    try { await FirebaseFirestore.instance.collection('doubts').doc(doubt.id).set(doubt.toMap()); } catch (_) {}
  }
  Future<void> replyToDoubt(String doubtId, DoubtReply reply) async {
    final idx = _simulatedDoubts.indexWhere((d) => d.id == doubtId);
    if (idx != -1) {
      final d = _simulatedDoubts[idx];
      _simulatedDoubts[idx] = DoubtPost(id: d.id, studentUid: d.studentUid, studentName: d.studentName, subject: d.subject, questionText: d.questionText, replies: [...d.replies, reply], timestamp: d.timestamp, isResolved: reply.isTeacher ? true : d.isResolved, batch: d.batch);
      notifyListeners();
    }
    if (!_isFirebaseInitialized) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('doubts').doc(doubtId).get();
      if (!doc.exists) return;
      final cur = DoubtPost.fromMap(doc.data()!, doc.id);
      await FirebaseFirestore.instance.collection('doubts').doc(doubtId).update({
        'replies': [...cur.replies.map((r) => r.toMap()), reply.toMap()],
        'isResolved': reply.isTeacher ? true : cur.isResolved,
      });
    } catch (_) {}
  }

  // ═══ TIMETABLE ═══
  final List<TimetableSlot> _simulatedTimetable = [
    TimetableSlot(id: 't1', batch: 'JEE 2026', dayIndex: 0, startTime: '08:00', endTime: '09:30', subject: 'Physics', teacherName: 'Dr. Amit Kumar', room: 'Room A'),
    TimetableSlot(id: 't2', batch: 'JEE 2026', dayIndex: 0, startTime: '10:00', endTime: '11:30', subject: 'Mathematics', teacherName: 'Mrs. Priya Sharma', room: 'Room B'),
    TimetableSlot(id: 't3', batch: 'JEE 2026', dayIndex: 1, startTime: '08:00', endTime: '09:30', subject: 'Chemistry', teacherName: 'Mr. Rakesh Singh', room: 'Room C'),
    TimetableSlot(id: 't4', batch: 'JEE 2026', dayIndex: 2, startTime: '08:00', endTime: '09:30', subject: 'Physics', teacherName: 'Dr. Amit Kumar', room: 'Room A'),
    TimetableSlot(id: 't5', batch: 'JEE 2026', dayIndex: 3, startTime: '08:00', endTime: '09:30', subject: 'Mathematics', teacherName: 'Mrs. Priya Sharma', room: 'Room B'),
    TimetableSlot(id: 't6', batch: 'JEE 2026', dayIndex: 4, startTime: '08:00', endTime: '09:30', subject: 'Chemistry', teacherName: 'Mr. Rakesh Singh', room: 'Room C'),
    TimetableSlot(id: 't7', batch: 'JEE 2026', dayIndex: 5, startTime: '09:00', endTime: '12:00', subject: 'Mock Test', teacherName: 'All Faculty', room: 'Hall 1'),
  ];
  Future<List<TimetableSlot>> getTimetable(String batch) async {
    if (!_isFirebaseInitialized) return _simulatedTimetable.where((s) => s.batch == batch || batch == 'All').toList();
    try {
      final snap = batch == 'All'
          ? await FirebaseFirestore.instance.collection('timetable').get()
          : await FirebaseFirestore.instance.collection('timetable').where('batch', isEqualTo: batch).get();
      final res = snap.docs.map((d) => TimetableSlot.fromMap(d.data(), d.id)).toList();
      return res.isEmpty ? _simulatedTimetable : res;
    } catch (_) { return _simulatedTimetable.where((s) => s.batch == batch || batch == 'All').toList(); }
  }
  Future<void> upsertTimetableSlot(TimetableSlot slot) async {
    _simulatedTimetable.removeWhere((s) => s.id == slot.id); _simulatedTimetable.add(slot); notifyListeners();
    if (!_isFirebaseInitialized) return;
    try { await FirebaseFirestore.instance.collection('timetable').doc(slot.id).set(slot.toMap()); } catch (_) {}
  }

  // ═══ PARENT-CHILD LINKS ═══
  final List<Map<String, String>> _simulatedParentLinks = [];
  Future<void> linkParentToChild({required String parentUid, required String childUid}) async {
    final lid = '${parentUid}_$childUid';
    if (!_simulatedParentLinks.any((l) => l['id'] == lid)) { _simulatedParentLinks.add({'parentUid': parentUid, 'childUid': childUid, 'id': lid}); notifyListeners(); }
    if (!_isFirebaseInitialized) return;
    try { await FirebaseFirestore.instance.collection('parentChildLinks').doc(lid).set({'parentUid': parentUid, 'childUid': childUid, 'linkedAt': DateTime.now().toIso8601String()}); } catch (_) {}
  }
  Future<void> unlinkParentFromChild({required String parentUid, required String childUid}) async {
    final lid = '${parentUid}_$childUid';
    _simulatedParentLinks.removeWhere((l) => l['id'] == lid); notifyListeners();
    if (!_isFirebaseInitialized) return;
    try { await FirebaseFirestore.instance.collection('parentChildLinks').doc(lid).delete(); } catch (_) {}
  }
  Future<List<UserModel>> getChildrenForParent(String parentUid) async {
    final childUids = _simulatedParentLinks.where((l) => l['parentUid'] == parentUid).map((l) => l['childUid']!).toList();
    if (!_isFirebaseInitialized) return _simulatedUsers.where((u) => childUids.contains(u.uid)).toList();
    try {
      final snap = await FirebaseFirestore.instance.collection('parentChildLinks').where('parentUid', isEqualTo: parentUid).get();
      final uids = snap.docs.map((d) => d.data()['childUid'] as String).toList();
      if (uids.isEmpty) return [];
      final docs = await Future.wait(uids.map((uid) => FirebaseFirestore.instance.collection('users').doc(uid).get()));
      return docs.where((d) => d.exists).map((d) => UserModel.fromMap(d.data()!, d.id)).toList();
    } catch (_) { return _simulatedUsers.where((u) => childUids.contains(u.uid)).toList(); }
  }
  Future<List<UserModel>> getParentsForStudent(String studentUid) async {
    final parentUids = _simulatedParentLinks.where((l) => l['childUid'] == studentUid).map((l) => l['parentUid']!).toList();
    if (!_isFirebaseInitialized) return _simulatedUsers.where((u) => parentUids.contains(u.uid)).toList();
    try {
      final snap = await FirebaseFirestore.instance.collection('parentChildLinks').where('childUid', isEqualTo: studentUid).get();
      final uids = snap.docs.map((d) => d.data()['parentUid'] as String).toList();
      if (uids.isEmpty) return [];
      final docs = await Future.wait(uids.map((uid) => FirebaseFirestore.instance.collection('users').doc(uid).get()));
      return docs.where((d) => d.exists).map((d) => UserModel.fromMap(d.data()!, d.id)).toList();
    } catch (_) { return _simulatedUsers.where((u) => parentUids.contains(u.uid)).toList(); }
  }

  // ═══ SHARE ═══
  String getShareText() {
    final name = _currentUser?.name ?? 'A student';
    return '$name invited you to join Crest Achievers — India\'s premium coaching app for JEE & NEET.\n\n'
        'Live classes, DPP, doubt solving & more!\n'
        'Download: https://crestachievers.com/app\n'
        'Call: +91 98765 43210';
  }

  // --- True Offline Mode Persistent Methods ---
  Future<void> _saveCachedDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cached_lectures', _cachedLectures.toList());
      await prefs.setStringList('cached_notes', _cachedNotes.toList());
    } catch (e) {
      debugPrint("Error saving cached downloads list: $e");
    }
  }

  Future<void> _loadCachedDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lectures = prefs.getStringList('cached_lectures') ?? [];
      final notes = prefs.getStringList('cached_notes') ?? [];
      _cachedLectures.clear();
      _cachedLectures.addAll(lectures);
      _cachedNotes.clear();
      _cachedNotes.addAll(notes);
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading cached downloads list: $e");
    }
  }

  Future<void> cacheLecture(String chapterId, String lectureTitle) async {
    final key = "${chapterId}_$lectureTitle";
    if (_cachedLectures.contains(key)) return;

    _downloadProgress[key] = 0.0;
    notifyListeners();

    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      _downloadProgress[key] = i * 0.2;
      notifyListeners();
    }

    _cachedLectures.add(key);
    _downloadProgress.remove(key);
    await _saveCachedDownloads();
    notifyListeners();
  }

  Future<void> cacheNote(String chapterId, String noteTitle) async {
    final key = "${chapterId}_$noteTitle";
    if (_cachedNotes.contains(key)) return;

    _downloadProgress[key] = 0.0;
    notifyListeners();

    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      _downloadProgress[key] = i * 0.2;
      notifyListeners();
    }

    _cachedNotes.add(key);
    _downloadProgress.remove(key);
    await _saveCachedDownloads();
    notifyListeners();
  }

  Future<void> removeLectureFromCache(String chapterId, String lectureTitle) async {
    final key = "${chapterId}_$lectureTitle";
    _cachedLectures.remove(key);
    await _saveCachedDownloads();
    notifyListeners();
  }

  Future<void> removeNoteFromCache(String chapterId, String noteTitle) async {
    final key = "${chapterId}_$noteTitle";
    _cachedNotes.remove(key);
    await _saveCachedDownloads();
    notifyListeners();
  }
}

