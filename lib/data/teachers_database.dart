import 'package:murakib_vip/services/firebase_service.dart';

class TeachersDatabase {
  static final TeachersDatabase _instance = TeachersDatabase._internal();
  final FirebaseService _firebase = FirebaseService.instance;

  TeachersDatabase._internal();
  static TeachersDatabase get instance => _instance;

  // Method to add a teacher
  Future<void> addTeacher({
    required String username,
    required String password,
    required String phone,
    required String subject,
    required List<String> grades,
    required List<String> classes,
    required String school,
  }) async {
    try {
      // Check if username exists
      final existingTeachers = await _firebase.queryCollection(
        collection: 'teachers',
        field: 'username',
        value: username,
      );

      if (existingTeachers.isNotEmpty) {
        throw Exception('Username already exists');
      }

      // Add teacher to Firebase
      await _firebase.addTeacher({
        'username': username,
        'password': password,
        'phone': phone,
        'subject': subject,
        'grades': grades,
        'classes': classes,
        'school': school,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding teacher: $e');
      rethrow;
    }
  }

  // Method to get all teachers
  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    return await _firebase.getTeachers();
  }

  // Method to get teachers by school
  Future<List<Map<String, dynamic>>> getTeachersBySchool(String school) async {
    return await _firebase.queryCollection(
      collection: 'teachers',
      field: 'school',
      value: school,
    );
  }

  // Method to get teachers by subject
  Future<List<Map<String, dynamic>>> getTeachersBySubject(
      String subject) async {
    return await _firebase.queryCollection(
      collection: 'teachers',
      field: 'subject',
      value: subject,
    );
  }

  // Method to update teacher information
  Future<void> updateTeacher(
      String teacherId, Map<String, dynamic> updates) async {
    await _firebase.updateDocument('teachers', teacherId, updates);
  }

  // Method to remove a teacher
  Future<void> removeTeacher(String username) async {
    final teachers = await _firebase.queryCollection(
      collection: 'teachers',
      field: 'username',
      value: username,
    );
    if (teachers.isNotEmpty) {
      await _firebase.deleteDocument('teachers', teachers.first['id']);
    }
  }

  // Method to check if username exists
  Future<bool> usernameExists(String username) async {
    final teachers = await _firebase.queryCollection(
      collection: 'teachers',
      field: 'username',
      value: username,
    );
    return teachers.isNotEmpty;
  }

  // Method to get teachers by grade and class
  Future<List<Map<String, dynamic>>> getTeachersByGradeAndClass(
      String grade, String className) async {
    final teachers = await _firebase.getTeachers();
    return teachers.where((teacher) {
      final grades = List<String>.from(teacher['grades'] ?? []);
      final classes = List<String>.from(teacher['classes'] ?? []);
      return grades.contains(grade) && classes.contains(className);
    }).toList();
  }

  // Method to clear all teachers
  Future<void> clearAll() async {
    final teachers = await _firebase.getTeachers();
    for (var teacher in teachers) {
      await _firebase.deleteDocument('teachers', teacher['id']);
    }
  }
}

// Access the singleton instance using `TeachersDatabase.instance`
final TeachersDatabase teachersDatabase = TeachersDatabase.instance;
