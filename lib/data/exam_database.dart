/// Singleton to manage exam database
library;

import 'package:murakib_vip/services/firebase_service.dart';

class ExamDatabase {
  static final ExamDatabase _instance = ExamDatabase._internal();
  final FirebaseService _firebase = FirebaseService.instance;

  ExamDatabase._internal();
  static ExamDatabase get instance => _instance;

  // Method to add an exam
  Future<void> addExam({
    required String subject,
    required String date,
    required String time,
    required String grade,
    required String className,
    required String school,
    String? description,
  }) async {
    try {
      await _firebase.addExam({
        'subject': subject,
        'date': date,
        'time': time,
        'grade': grade,
        'class': className,
        'school': school,
        'description': description,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding exam: $e');
      rethrow;
    }
  }

  // Method to get all exams
  Future<List<Map<String, dynamic>>> getAllExams() async {
    return await _firebase.getExams();
  }

  // Method to get exams by date
  Future<List<Map<String, dynamic>>> getExamsByDate(String date) async {
    return await _firebase.queryCollection(
      collection: 'exams',
      field: 'date',
      value: date,
    );
  }

  // Method to get exams by grade and class
  Future<List<Map<String, dynamic>>> getExamsByGradeAndClass(
    String grade,
    String className,
  ) async {
    final exams = await _firebase.getExams();
    return exams
        .where((exam) => exam['grade'] == grade && exam['class'] == className)
        .toList();
  }

  // Method to get exams by subject
  Future<List<Map<String, dynamic>>> getExamsBySubject(String subject) async {
    return await _firebase.queryCollection(
      collection: 'exams',
      field: 'subject',
      value: subject,
    );
  }

  // Method to update exam
  Future<void> updateExam(String examId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = DateTime.now().toIso8601String();
    await _firebase.updateDocument('exams', examId, updates);
  }

  // Method to delete exam
  Future<void> deleteExam(String examId) async {
    await _firebase.deleteDocument('exams', examId);
  }

  // Method to clear all exams
  Future<void> clearAll() async {
    final exams = await _firebase.getExams();
    for (var exam in exams) {
      await _firebase.deleteDocument('exams', exam['id']);
    }
  }
}

// Global instance of the exam database
final ExamDatabase examDatabase = ExamDatabase.instance;
