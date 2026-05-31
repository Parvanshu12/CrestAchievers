class Course {
  final String id;
  final String title;
  final String tagline;
  final double price;
  final String coverImageUrl;
  final List<Subject> subjects;

  Course({
    required this.id,
    required this.title,
    required this.tagline,
    required this.price,
    required this.coverImageUrl,
    required this.subjects,
  });

  factory Course.fromMap(Map<String, dynamic> map, String documentId) {
    return Course(
      id: documentId,
      title: map['title'] ?? '',
      tagline: map['tagline'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      coverImageUrl: map['coverImageUrl'] ?? 'https://picsum.photos/400/250',
      subjects: (map['subjects'] as List<dynamic>?)
              ?.map((s) => Subject.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'tagline': tagline,
      'price': price,
      'coverImageUrl': coverImageUrl,
      'subjects': subjects.map((s) => s.toMap()).toList(),
    };
  }
}

class Subject {
  final String name;
  final List<Chapter> chapters;

  Subject({
    required this.name,
    required this.chapters,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      name: map['name'] ?? '',
      chapters: (map['chapters'] as List<dynamic>?)
              ?.map((c) => Chapter.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'chapters': chapters.map((c) => c.toMap()).toList(),
    };
  }
}

class Chapter {
  final String id;
  final String title;
  final List<Lecture> lectures;
  final List<Note> notes;

  Chapter({
    required this.id,
    required this.title,
    required this.lectures,
    required this.notes,
  });

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      lectures: (map['lectures'] as List<dynamic>?)
              ?.map((l) => Lecture.fromMap(l as Map<String, dynamic>))
              .toList() ??
          [],
      notes: (map['notes'] as List<dynamic>?)
              ?.map((n) => Note.fromMap(n as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'lectures': lectures.map((l) => l.toMap()).toList(),
      'notes': notes.map((n) => n.toMap()).toList(),
    };
  }
}

class Lecture {
  final String title;
  final String videoUrl;
  final String duration;

  Lecture({
    required this.title,
    required this.videoUrl,
    required this.duration,
  });

  factory Lecture.fromMap(Map<String, dynamic> map) {
    return Lecture(
      title: map['title'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      duration: map['duration'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'videoUrl': videoUrl,
      'duration': duration,
    };
  }
}

class Note {
  final String title;
  final String pdfUrl;

  Note({
    required this.title,
    required this.pdfUrl,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      title: map['title'] ?? '',
      pdfUrl: map['pdfUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'pdfUrl': pdfUrl,
    };
  }
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String studentClass; // '11th', '12th', 'Dropper', etc.
  final String photoUrl; // Dynamic profile avatar URL
  final List<String> purchasedCourseIds;
  final String role; // 'student' or 'teacher'
  final List<String> assignedCourseIds; // Teacher assigned course IDs
  final List<String> assignedSubjects; // Teacher assigned subjects

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.studentClass,
    required this.photoUrl,
    required this.purchasedCourseIds,
    required this.role,
    this.assignedCourseIds = const [],
    this.assignedSubjects = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String userId) {
    // Treat master phone developer (8888888888) as teacher automatically
    final String parsedEmail = map['email'] ?? '';
    final String defaultRole = (parsedEmail.contains('8888888888') || userId == 'crest_dev_master') ? 'teacher' : 'student';
    
    return UserModel(
      uid: userId,
      email: parsedEmail,
      name: map['name'] ?? '',
      studentClass: map['studentClass'] ?? '12th PCM',
      photoUrl: map['photoUrl'] ?? 'https://api.dicebear.com/7.x/bottts/png?seed=${userId.hashCode}',
      purchasedCourseIds: List<String>.from(map['purchasedCourseIds'] ?? []),
      role: map['role'] ?? defaultRole,
      assignedCourseIds: List<String>.from(map['assignedCourseIds'] ?? []),
      assignedSubjects: List<String>.from(map['assignedSubjects'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'studentClass': studentClass,
      'photoUrl': photoUrl,
      'purchasedCourseIds': purchasedCourseIds,
      'role': role,
      'assignedCourseIds': assignedCourseIds,
      'assignedSubjects': assignedSubjects,
    };
  }
}

// ─── Branch ────────────────────────────────────────────────
class Branch {
  final String id;
  final String name;
  final String address;
  final String headTeacher;
  final String phone;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.headTeacher,
    required this.phone,
  });

  factory Branch.fromMap(Map<String, dynamic> map, String docId) => Branch(
        id: docId,
        name: map['name'] ?? '',
        address: map['address'] ?? '',
        headTeacher: map['headTeacher'] ?? '',
        phone: map['phone'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'headTeacher': headTeacher,
        'phone': phone,
      };
}

// ─── AttendanceRecord ──────────────────────────────────────
class AttendanceRecord {
  final String id;
  final String studentUid;
  final String date; // 'yyyy-MM-dd'
  final bool present;
  final String subject;
  final String batch;
  final String markedBy;

  AttendanceRecord({
    required this.id,
    required this.studentUid,
    required this.date,
    required this.present,
    required this.subject,
    required this.batch,
    required this.markedBy,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String docId) =>
      AttendanceRecord(
        id: docId,
        studentUid: map['studentUid'] ?? '',
        date: map['date'] ?? '',
        present: map['present'] ?? false,
        subject: map['subject'] ?? '',
        batch: map['batch'] ?? 'General',
        markedBy: map['markedBy'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'studentUid': studentUid,
        'date': date,
        'present': present,
        'subject': subject,
        'batch': batch,
        'markedBy': markedBy,
      };
}

// ─── TestResult ────────────────────────────────────────────
class TestResult {
  final String id;
  final String studentUid;
  final String testName;
  final String subject;
  final double marksObtained;
  final double totalMarks;
  final String date; // 'yyyy-MM-dd'
  final String batch;

  TestResult({
    required this.id,
    required this.studentUid,
    required this.testName,
    required this.subject,
    required this.marksObtained,
    required this.totalMarks,
    required this.date,
    required this.batch,
  });

  double get percentage => totalMarks > 0 ? (marksObtained / totalMarks) * 100 : 0;

  factory TestResult.fromMap(Map<String, dynamic> map, String docId) =>
      TestResult(
        id: docId,
        studentUid: map['studentUid'] ?? '',
        testName: map['testName'] ?? '',
        subject: map['subject'] ?? '',
        marksObtained: (map['marksObtained'] ?? 0).toDouble(),
        totalMarks: (map['totalMarks'] ?? 100).toDouble(),
        date: map['date'] ?? '',
        batch: map['batch'] ?? 'General',
      );

  Map<String, dynamic> toMap() => {
        'studentUid': studentUid,
        'testName': testName,
        'subject': subject,
        'marksObtained': marksObtained,
        'totalMarks': totalMarks,
        'date': date,
        'batch': batch,
      };
}

// ─── FeeRecord ─────────────────────────────────────────────
class FeeRecord {
  final String id;
  final String studentUid;
  final int month; // 1–12
  final int year;
  final String status; // 'paid' | 'unpaid' | 'partial'
  final double amount;
  final String dueDate; // 'yyyy-MM-dd'
  final String paidDate; // '' if not yet paid

  FeeRecord({
    required this.id,
    required this.studentUid,
    required this.month,
    required this.year,
    required this.status,
    required this.amount,
    required this.dueDate,
    required this.paidDate,
  });

  factory FeeRecord.fromMap(Map<String, dynamic> map, String docId) =>
      FeeRecord(
        id: docId,
        studentUid: map['studentUid'] ?? '',
        month: (map['month'] ?? 1) as int,
        year: (map['year'] ?? DateTime.now().year) as int,
        status: map['status'] ?? 'unpaid',
        amount: (map['amount'] ?? 0.0).toDouble(),
        dueDate: map['dueDate'] ?? '',
        paidDate: map['paidDate'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'studentUid': studentUid,
        'month': month,
        'year': year,
        'status': status,
        'amount': amount,
        'dueDate': dueDate,
        'paidDate': paidDate,
      };
}

// ─── DppCard ───────────────────────────────────────────────
class DppCard {
  final String id;
  final String subject;
  final String date; // 'yyyy-MM-dd'
  final String questionText;
  final String? imageUrl;
  final String postedBy;
  final String batch;
  final String? pdfUrl;

  DppCard({
    required this.id,
    required this.subject,
    required this.date,
    required this.questionText,
    this.imageUrl,
    required this.postedBy,
    required this.batch,
    this.pdfUrl,
  });

  factory DppCard.fromMap(Map<String, dynamic> map, String docId) => DppCard(
        id: docId,
        subject: map['subject'] ?? '',
        date: map['date'] ?? '',
        questionText: map['questionText'] ?? '',
        imageUrl: map['imageUrl'],
        postedBy: map['postedBy'] ?? '',
        batch: map['batch'] ?? 'All',
        pdfUrl: map['pdfUrl'],
      );

  Map<String, dynamic> toMap() => {
        'subject': subject,
        'date': date,
        'questionText': questionText,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'postedBy': postedBy,
        'batch': batch,
        if (pdfUrl != null) 'pdfUrl': pdfUrl,
      };
}

// ─── DoubtReply ────────────────────────────────────────────
class DoubtReply {
  final String replierName;
  final String text;
  final String timestamp;
  final bool isTeacher;
  final String? voiceUrl;
  final String? voiceDuration;
  final String? canvasUrl;

  DoubtReply({
    required this.replierName,
    required this.text,
    required this.timestamp,
    required this.isTeacher,
    this.voiceUrl,
    this.voiceDuration,
    this.canvasUrl,
  });

  factory DoubtReply.fromMap(Map<String, dynamic> map) => DoubtReply(
        replierName: map['replierName'] ?? '',
        text: map['text'] ?? '',
        timestamp: map['timestamp'] ?? '',
        isTeacher: map['isTeacher'] ?? false,
        voiceUrl: map['voiceUrl'] as String?,
        voiceDuration: map['voiceDuration'] as String?,
        canvasUrl: map['canvasUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'replierName': replierName,
        'text': text,
        'timestamp': timestamp,
        'isTeacher': isTeacher,
        if (voiceUrl != null) 'voiceUrl': voiceUrl,
        if (voiceDuration != null) 'voiceDuration': voiceDuration,
        if (canvasUrl != null) 'canvasUrl': canvasUrl,
      };
}

// ─── DoubtPost ─────────────────────────────────────────────
class DoubtPost {
  final String id;
  final String studentUid;
  final String studentName;
  final String subject;
  final String questionText;
  final List<DoubtReply> replies;
  final String timestamp;
  final bool isResolved;
  final String batch;

  DoubtPost({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.subject,
    required this.questionText,
    required this.replies,
    required this.timestamp,
    required this.isResolved,
    required this.batch,
  });

  factory DoubtPost.fromMap(Map<String, dynamic> map, String docId) =>
      DoubtPost(
        id: docId,
        studentUid: map['studentUid'] ?? '',
        studentName: map['studentName'] ?? 'Anonymous',
        subject: map['subject'] ?? '',
        questionText: map['questionText'] ?? '',
        replies: (map['replies'] as List<dynamic>?)
                ?.map((r) => DoubtReply.fromMap(r as Map<String, dynamic>))
                .toList() ??
            [],
        timestamp: map['timestamp'] ?? '',
        isResolved: map['isResolved'] ?? false,
        batch: map['batch'] ?? 'All',
      );

  Map<String, dynamic> toMap() => {
        'studentUid': studentUid,
        'studentName': studentName,
        'subject': subject,
        'questionText': questionText,
        'replies': replies.map((r) => r.toMap()).toList(),
        'timestamp': timestamp,
        'isResolved': isResolved,
        'batch': batch,
      };
}

// ─── TimetableSlot ─────────────────────────────────────────
class TimetableSlot {
  final String id;
  final String batch;
  final int dayIndex; // 0=Mon, 1=Tue, ... 5=Sat
  final String startTime; // 'HH:mm'
  final String endTime;
  final String subject;
  final String teacherName;
  final String room;

  TimetableSlot({
    required this.id,
    required this.batch,
    required this.dayIndex,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacherName,
    required this.room,
  });

  factory TimetableSlot.fromMap(Map<String, dynamic> map, String docId) =>
      TimetableSlot(
        id: docId,
        batch: map['batch'] ?? 'General',
        dayIndex: (map['dayIndex'] ?? 0) as int,
        startTime: map['startTime'] ?? '08:00',
        endTime: map['endTime'] ?? '09:00',
        subject: map['subject'] ?? '',
        teacherName: map['teacherName'] ?? '',
        room: map['room'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'batch': batch,
        'dayIndex': dayIndex,
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'teacherName': teacherName,
        'room': room,
      };
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final int timestampMillis;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestampMillis,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestampMillis: map['timestampMillis'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestampMillis': timestampMillis,
    };
  }
}
