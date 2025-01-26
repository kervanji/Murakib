import 'package:murakib_vip/services/firebase_service.dart';

/// Singleton to manage lessons database
class LessonsDatabase {
  static final LessonsDatabase _instance = LessonsDatabase._internal();
  final FirebaseService _firebase = FirebaseService.instance;

  LessonsDatabase._internal();
  static LessonsDatabase get instance => _instance;

  // Method to add a lesson
  Future<void> addLesson({
    required String subject,
    required String teacherId,
    required String grade,
    required String className,
    required String school,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    try {
      await _firebase.addLesson({
        'subject': subject,
        'teacherId': teacherId,
        'grade': grade,
        'class': className,
        'school': school,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding lesson: $e');
      rethrow;
    }
  }

  // Method to get all lessons
  Future<List<Map<String, dynamic>>> getAllLessons() async {
    return await _firebase.getLessons();
  }

  // Method to get lessons by teacher
  Future<List<Map<String, dynamic>>> getLessonsByTeacher(
      String teacherId) async {
    return await _firebase.queryCollection(
      collection: 'lessons',
      field: 'teacherId',
      value: teacherId,
    );
  }

  // Method to get lessons by grade and class
  Future<List<Map<String, dynamic>>> getLessonsByGradeAndClass(
    String grade,
    String className,
  ) async {
    final lessons = await _firebase.getLessons();
    return lessons
        .where((lesson) =>
            lesson['grade'] == grade && lesson['class'] == className)
        .toList();
  }

  // Method to get lessons by day
  Future<List<Map<String, dynamic>>> getLessonsByDay(String dayOfWeek) async {
    return await _firebase.queryCollection(
      collection: 'lessons',
      field: 'dayOfWeek',
      value: dayOfWeek,
    );
  }

  // Method to update lesson
  Future<void> updateLesson(
      String lessonId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = DateTime.now().toIso8601String();
    await _firebase.updateDocument('lessons', lessonId, updates);
  }

  // Method to delete lesson
  Future<void> deleteLesson(String lessonId) async {
    await _firebase.deleteDocument('lessons', lessonId);
  }

  // Method to get lessons schedule
  Future<Map<String, List<Map<String, dynamic>>>> getWeeklySchedule(
    String grade,
    String className,
  ) async {
    final lessons = await getLessonsByGradeAndClass(grade, className);
    final schedule = <String, List<Map<String, dynamic>>>{};

    final daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    for (var day in daysOfWeek) {
      schedule[day] = lessons
          .where((lesson) => lesson['dayOfWeek'] == day)
          .toList()
        ..sort((a, b) => a['startTime'].compareTo(b['startTime']));
    }

    return schedule;
  }

  // Method to clear all lessons
  Future<void> clearAll() async {
    final lessons = await _firebase.getLessons();
    for (var lesson in lessons) {
      await _firebase.deleteDocument('lessons', lesson['id']);
    }
  }
}

// Global instance of the lessons database
final LessonsDatabase lessonsDatabase = LessonsDatabase.instance;
