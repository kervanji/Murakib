import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const timeout = Duration(seconds: 15); // Increased timeout

  FirebaseService._internal() {
    // Enable Firestore offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static FirebaseService get instance => _instance;

  // Students Collection
  Future<void> addStudent(Map<String, dynamic> studentData) async {
    debugPrint('\n=== Adding Student to Firestore ===');
    debugPrint('Student Data: $studentData');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      debugPrint('Checking if student username exists...');
      final existingStudents = await queryCollection(
        collection: 'students',
        field: 'username',
        value: studentData['username'],
      ).timeout(timeout, onTimeout: () {
        throw TimeoutException('Student existence check timed out');
      });

      if (existingStudents.isNotEmpty) {
        throw Exception(
            'Student with username ${studentData['username']} already exists');
      }

      debugPrint('Creating new student document...');
      await _firestore.collection('students').add({
        ...studentData,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(timeout, onTimeout: () {
        throw TimeoutException('Adding student operation timed out');
      });

      debugPrint('Student added successfully!');
    } catch (e) {
      _logError('Adding Student', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    debugPrint('\n=== Getting Students from Firestore ===');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final snapshot = await _firestore
          .collection('students')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Getting students operation timed out');
      });

      debugPrint('Retrieved ${snapshot.docs.length} students');
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      _logError('Getting Students', e);
      rethrow;
    }
  }

  Future<void> deleteStudent(String username) async {
    debugPrint('\n=== Deleting Student from Firestore ===');
    debugPrint('Username: $username');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('username', isEqualTo: username)
          .get()
          .timeout(timeout);

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Student not found');
      }

      await _firestore
          .collection('students')
          .doc(querySnapshot.docs.first.id)
          .delete()
          .timeout(timeout);

      debugPrint('Student deleted successfully!');
    } catch (e) {
      _logError('Deleting Student', e);
      rethrow;
    }
  }

  // Teachers Collection
  Future<void> addTeacher(Map<String, dynamic> teacherData) async {
    debugPrint('\n=== Adding Teacher to Firestore ===');
    debugPrint('Teacher Data: $teacherData');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      debugPrint('Checking if teacher username exists...');
      final existingTeachers = await queryCollection(
        collection: 'teachers',
        field: 'username',
        value: teacherData['username'],
      ).timeout(timeout, onTimeout: () {
        throw TimeoutException('Teacher existence check timed out');
      });

      if (existingTeachers.isNotEmpty) {
        throw Exception(
            'Teacher with username ${teacherData['username']} already exists');
      }

      debugPrint('Creating new teacher document...');
      await _firestore.collection('teachers').add({
        ...teacherData,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(timeout, onTimeout: () {
        throw TimeoutException('Adding teacher operation timed out');
      });

      debugPrint('Teacher added successfully!');
    } catch (e) {
      _logError('Adding Teacher', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTeachers() async {
    debugPrint('\n=== Getting Teachers from Firestore ===');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final snapshot = await _firestore
          .collection('teachers')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Getting teachers operation timed out');
      });

      debugPrint('Retrieved ${snapshot.docs.length} teachers');
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      _logError('Getting Teachers', e);
      rethrow;
    }
  }

  Future<void> deleteTeacher(String username) async {
    debugPrint('\n=== Deleting Teacher from Firestore ===');
    debugPrint('Username: $username');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final querySnapshot = await _firestore
          .collection('teachers')
          .where('username', isEqualTo: username)
          .get()
          .timeout(timeout);

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Teacher not found');
      }

      await _firestore
          .collection('teachers')
          .doc(querySnapshot.docs.first.id)
          .delete()
          .timeout(timeout);

      debugPrint('Teacher deleted successfully!');
    } catch (e) {
      _logError('Deleting Teacher', e);
      rethrow;
    }
  }

  // Principals Collection
  Future<void> addPrincipal(Map<String, dynamic> principalData) async {
    debugPrint('\n=== Adding Principal to Firestore ===');
    debugPrint('Principal Data: $principalData');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      debugPrint('Checking if principal username exists...');
      final existingPrincipals = await queryCollection(
        collection: 'principals',
        field: 'username',
        value: principalData['username'],
      ).timeout(timeout, onTimeout: () {
        throw TimeoutException('Principal existence check timed out');
      });

      if (existingPrincipals.isNotEmpty) {
        throw Exception(
            'Principal with username ${principalData['username']} already exists');
      }

      debugPrint('Creating new principal document...');
      await _firestore.collection('principals').add({
        ...principalData,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(timeout, onTimeout: () {
        throw TimeoutException('Adding principal operation timed out');
      });

      debugPrint('Principal added successfully!');
    } catch (e) {
      _logError('Adding Principal', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPrincipals() async {
    debugPrint('\n=== Getting Principals from Firestore ===');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final snapshot = await _firestore
          .collection('principals')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Getting principals operation timed out');
      });

      debugPrint('Retrieved ${snapshot.docs.length} principals');
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      _logError('Getting Principals', e);
      rethrow;
    }
  }

  Future<void> deletePrincipal(String username) async {
    debugPrint('\n=== Deleting Principal from Firestore ===');
    debugPrint('Username: $username');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final querySnapshot = await _firestore
          .collection('principals')
          .where('username', isEqualTo: username)
          .get()
          .timeout(timeout);

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Principal not found');
      }

      await _firestore
          .collection('principals')
          .doc(querySnapshot.docs.first.id)
          .delete()
          .timeout(timeout);

      debugPrint('Principal deleted successfully!');
    } catch (e) {
      _logError('Deleting Principal', e);
      rethrow;
    }
  }

  // Attendance Collection
  Future<void> addAttendance(Map<String, dynamic> attendanceData) async {
    debugPrint('\n=== Adding Attendance to Firestore ===');
    debugPrint('Attendance Data: $attendanceData');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      debugPrint('Creating new attendance document...');
      await _firestore.collection('attendance').add({
        ...attendanceData,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(timeout, onTimeout: () {
        throw TimeoutException('Adding attendance operation timed out');
      });

      debugPrint('Attendance added successfully!');
    } catch (e) {
      _logError('Adding Attendance', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAttendance() async {
    debugPrint('\n=== Getting Attendance from Firestore ===');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final snapshot = await _firestore
          .collection('attendance')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Getting attendance operation timed out');
      });

      debugPrint('Retrieved ${snapshot.docs.length} attendance');
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      _logError('Getting Attendance', e);
      rethrow;
    }
  }

  // Exams Collection
  Future<void> addExam(Map<String, dynamic> examData) async {
    debugPrint('\n=== Adding Exam to Firestore ===');
    debugPrint('Exam Data: $examData');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      debugPrint('Creating new exam document...');
      await _firestore.collection('exams').add({
        ...examData,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(timeout, onTimeout: () {
        throw TimeoutException('Adding exam operation timed out');
      });

      debugPrint('Exam added successfully!');
    } catch (e) {
      _logError('Adding Exam', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExams() async {
    debugPrint('\n=== Getting Exams from Firestore ===');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final snapshot = await _firestore
          .collection('exams')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Getting exams operation timed out');
      });

      debugPrint('Retrieved ${snapshot.docs.length} exams');
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      _logError('Getting Exams', e);
      rethrow;
    }
  }

  // Lessons Collection
  Future<void> addLesson(Map<String, dynamic> lessonData) async {
    debugPrint('\n=== Adding Lesson to Firestore ===');
    debugPrint('Lesson Data: $lessonData');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      debugPrint('Creating new lesson document...');
      await _firestore.collection('lessons').add({
        ...lessonData,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(timeout, onTimeout: () {
        throw TimeoutException('Adding lesson operation timed out');
      });

      debugPrint('Lesson added successfully!');
    } catch (e) {
      _logError('Adding Lesson', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLessons() async {
    debugPrint('\n=== Getting Lessons from Firestore ===');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final snapshot = await _firestore
          .collection('lessons')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Getting lessons operation timed out');
      });

      debugPrint('Retrieved ${snapshot.docs.length} lessons');
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      _logError('Getting Lessons', e);
      rethrow;
    }
  }

  // Grades and Classes Collection
  Future<void> addGradeAndClass(Map<String, dynamic> gradeClassData) async {
    debugPrint('\n=== Adding Grade and Class to Firestore ===');
    debugPrint('Grade and Class Data: $gradeClassData');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      debugPrint('Creating new grade and class document...');
      await _firestore.collection('grades_classes').add({
        ...gradeClassData,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(timeout, onTimeout: () {
        throw TimeoutException('Adding grade and class operation timed out');
      });

      debugPrint('Grade and class added successfully!');
    } catch (e) {
      _logError('Adding Grade and Class', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGradesAndClasses() async {
    debugPrint('\n=== Getting Grades and Classes from Firestore ===');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final snapshot = await _firestore
          .collection('grades_classes')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout, onTimeout: () {
        throw TimeoutException(
            'Getting grades and classes operation timed out');
      });

      debugPrint('Retrieved ${snapshot.docs.length} grades and classes');
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      _logError('Getting Grades and Classes', e);
      rethrow;
    }
  }

  // Schools Collection
  Future<void> addSchool(String schoolName) async {
    debugPrint('\n=== Adding School to Firestore ===');
    debugPrint('School Name: $schoolName');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      debugPrint('Checking if school already exists...');
      final existingSchool = await _firestore
          .collection('schools')
          .where('name', isEqualTo: schoolName)
          .get()
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('School existence check timed out');
      });

      if (existingSchool.docs.isNotEmpty) {
        debugPrint('School already exists!');
        throw Exception('School with name $schoolName already exists');
      }

      debugPrint('Creating new school document...');
      await _firestore.collection('schools').add({
        'name': schoolName,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(timeout, onTimeout: () {
        throw TimeoutException('Adding school operation timed out');
      });

      debugPrint('School added successfully!');
    } catch (e) {
      _logError('Adding School', e);
      rethrow;
    }
  }

  Future<List<String>> getSchoolNames() async {
    debugPrint('\n=== Getting School Names from Firestore ===');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final snapshot = await _firestore
          .collection('schools')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Getting schools operation timed out');
      });

      debugPrint('Retrieved ${snapshot.docs.length} schools');
      return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    } catch (e) {
      _logError('Getting School Names', e);
      rethrow;
    }
  }

  // Generic methods for all collections
  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    debugPrint('\n=== Updating Document in Firestore ===');
    debugPrint('Collection: $collection, DocId: $docId');
    debugPrint('Update Data: $data');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .update(data)
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Document update operation timed out');
      });
      debugPrint('Document updated successfully!');
    } catch (e) {
      _logError('Updating Document', e);
      rethrow;
    }
  }

  Future<void> deleteDocument(String collection, String docId) async {
    debugPrint('\n=== Deleting Document from Firestore ===');
    debugPrint('Collection: $collection, DocId: $docId');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .delete()
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Document deletion operation timed out');
      });
      debugPrint('Document deleted successfully!');
    } catch (e) {
      _logError('Deleting Document', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getDocumentById(
      String collection, String docId) async {
    debugPrint('\n=== Getting Document by ID from Firestore ===');
    debugPrint('Collection: $collection, DocId: $docId');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final doc = await _firestore
          .collection(collection)
          .doc(docId)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Getting document operation timed out');
      });

      if (doc.exists) {
        debugPrint('Document found');
        return {...doc.data()!, 'id': doc.id};
      }
      debugPrint('Document not found');
      return null;
    } catch (e) {
      _logError('Getting Document by ID', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryCollection({
    required String collection,
    required String field,
    required dynamic value,
  }) async {
    debugPrint('\n=== Querying Collection in Firestore ===');
    debugPrint('Collection: $collection, Field: $field, Value: $value');

    if (!await _checkConnection()) {
      throw Exception(
          'No internet connection. Please check your connection and try again.');
    }

    try {
      final snapshot = await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Collection query operation timed out');
      });

      debugPrint('Query returned ${snapshot.docs.length} documents');
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      _logError('Querying Collection', e);
      rethrow;
    }
  }

  Future<bool> _checkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No internet connection detected');
        return false;
      }

      // Try a simple Firestore operation to verify connection
      try {
        await _firestore
            .collection('connection_test')
            .doc('test')
            .get()
            .timeout(const Duration(seconds: 5));
        debugPrint('Successfully connected to Firestore');
        return true;
      } on TimeoutException {
        debugPrint('Firestore connection timeout');
        return false;
      } catch (e) {
        // Even if this fails, we might still have connectivity
        debugPrint('Firestore test failed but might still have connection');
        return true;
      }
    } catch (e) {
      debugPrint('Error checking connection: $e');
      // If connectivity check fails, assume we might have connection
      return true;
    }
  }

  void _logError(String operation, dynamic error) {
    debugPrint('\n!!! Error during $operation !!!');
    debugPrint('Error details: $error');
    if (error is FirebaseException) {
      debugPrint('Firebase error code: ${error.code}');
      debugPrint('Firebase error message: ${error.message}');
    }
  }
}
