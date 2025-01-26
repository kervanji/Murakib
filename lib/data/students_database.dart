import 'package:murakib_vip/data/grade_and_classes_database.dart';
import 'package:murakib_vip/services/firebase_service.dart';

class StudentsDatabase {
  static final StudentsDatabase _instance = StudentsDatabase._internal();
  final FirebaseService _firebase = FirebaseService.instance;

  StudentsDatabase._internal();
  static StudentsDatabase get instance => _instance;

  // Method to add a student
  Future<void> addStudent(String principalUsername, String username,
      String password, String phone, String grade, String className) async {
    try {
      // Get principal's school
      final principals = await _firebase.queryCollection(
        collection: 'principals',
        field: 'username',
        value: principalUsername,
      );

      if (principals.isEmpty) {
        throw Exception(
            'Principal with username $principalUsername not found or school not assigned.');
      }

      final principal = principals.first;
      final schoolName = principal['school'];

      // Add grade and class
      await GradeAndClassesDatabase.instance.addGradeAndClass(grade, className);

      // Check if username exists
      final existingStudents = await _firebase.queryCollection(
        collection: 'students',
        field: 'username',
        value: username,
      );

      if (existingStudents.isNotEmpty) {
        throw Exception('Username already exists');
      }

      // Add student to Firebase
      await _firebase.addStudent({
        'username': username,
        'password': password,
        'phone': phone,
        'grade': grade,
        'class': className,
        'school': schoolName,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding student: $e');
      rethrow;
    }
  }

  // Method to check if a username exists
  Future<bool> usernameExists(String username) async {
    final students = await _firebase.queryCollection(
      collection: 'students',
      field: 'username',
      value: username,
    );
    return students.isNotEmpty;
  }

  // Method to fetch students by grade
  Future<List<Map<String, dynamic>>> fetchByGrade(String grade) async {
    return await _firebase.queryCollection(
      collection: 'students',
      field: 'grade',
      value: grade,
    );
  }

  // Method to fetch students by class
  Future<List<Map<String, dynamic>>> fetchByClass(String className) async {
    return await _firebase.queryCollection(
      collection: 'students',
      field: 'class',
      value: className,
    );
  }

  // Method to get students by grade and class
  Future<List<Map<String, dynamic>>> getStudentsByGradeAndClass(
      String grade, String className) async {
    final students = await _firebase.getStudents();
    return students
        .where((student) =>
            student['grade'] == grade && student['class'] == className)
        .toList();
  }

  // Method to remove a student by username
  Future<void> removeStudent(String username) async {
    final students = await _firebase.queryCollection(
      collection: 'students',
      field: 'username',
      value: username,
    );
    if (students.isNotEmpty) {
      await _firebase.deleteDocument('students', students.first['id']);
    }
  }

  // Method to clear all student records
  Future<void> clearAll() async {
    final students = await _firebase.getStudents();
    for (var student in students) {
      await _firebase.deleteDocument('students', student['id']);
    }
  }
}
