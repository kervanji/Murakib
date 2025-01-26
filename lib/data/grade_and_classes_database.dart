import 'package:murakib_vip/services/firebase_service.dart';

class GradeAndClassesDatabase {
  static final GradeAndClassesDatabase _instance =
      GradeAndClassesDatabase._internal();
  final FirebaseService _firebase = FirebaseService.instance;

  GradeAndClassesDatabase._internal();
  static GradeAndClassesDatabase get instance => _instance;

  // Method to add a grade and class combination
  Future<void> addGradeAndClass(String grade, String className) async {
    try {
      // Check if combination already exists
      final existing = await _firebase.queryCollection(
        collection: 'grades_classes',
        field: 'grade',
        value: grade,
      );

      if (existing.any((item) => item['class'] == className)) {
        return; // Already exists, no need to add
      }

      await _firebase.addGradeAndClass({
        'grade': grade,
        'class': className,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding grade and class: $e');
      rethrow;
    }
  }

  // Method to get all grades and classes
  Future<List<Map<String, dynamic>>> getAllGradesAndClasses() async {
    return await _firebase.getGradesAndClasses();
  }

  // Method to get all grades
  Future<List<String>> getAllGrades() async {
    final records = await _firebase.getGradesAndClasses();
    return records.map((record) => record['grade'] as String).toSet().toList()
      ..sort();
  }

  // Method to get classes for a grade
  Future<List<String>> getClassesForGrade(String grade) async {
    final records = await _firebase.queryCollection(
      collection: 'grades_classes',
      field: 'grade',
      value: grade,
    );
    return records.map((record) => record['class'] as String).toList()..sort();
  }

  // Method to update grade and class
  Future<void> updateGradeAndClass(
    String id,
    String newGrade,
    String newClassName,
  ) async {
    await _firebase.updateDocument('grades_classes', id, {
      'grade': newGrade,
      'class': newClassName,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Method to delete grade and class
  Future<void> deleteGradeAndClass(String id) async {
    await _firebase.deleteDocument('grades_classes', id);
  }

  // Method to clear all grades and classes
  Future<void> clearAll() async {
    final records = await _firebase.getGradesAndClasses();
    for (var record in records) {
      await _firebase.deleteDocument('grades_classes', record['id']);
    }
  }

  // Method to check if grade and class combination exists
  Future<bool> gradeAndClassExists(String grade, String className) async {
    final records = await _firebase.queryCollection(
      collection: 'grades_classes',
      field: 'grade',
      value: grade,
    );
    return records.any((record) => record['class'] == className);
  }
}
