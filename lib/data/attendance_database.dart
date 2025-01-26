import 'package:murakib_vip/services/firebase_service.dart';

class AttendanceDatabase {
  static final AttendanceDatabase _instance = AttendanceDatabase._internal();
  final FirebaseService _firebase = FirebaseService.instance;

  AttendanceDatabase._internal();
  static AttendanceDatabase get instance => _instance;

  // Method to record attendance
  Future<void> recordAttendance({
    required String studentId,
    required String date,
    required bool isPresent,
    required String grade,
    required String className,
    required String school,
  }) async {
    try {
      await _firebase.addAttendance({
        'studentId': studentId,
        'date': date,
        'isPresent': isPresent,
        'grade': grade,
        'class': className,
        'school': school,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error recording attendance: $e');
      rethrow;
    }
  }

  // Method to get attendance by date
  Future<List<Map<String, dynamic>>> getAttendanceByDate(String date) async {
    return await _firebase.queryCollection(
      collection: 'attendance',
      field: 'date',
      value: date,
    );
  }

  // Method to get attendance by student
  Future<List<Map<String, dynamic>>> getAttendanceByStudent(
      String studentId) async {
    return await _firebase.queryCollection(
      collection: 'attendance',
      field: 'studentId',
      value: studentId,
    );
  }

  // Method to get attendance by grade and class
  Future<List<Map<String, dynamic>>> getAttendanceByGradeAndClass(
    String date,
    String grade,
    String className,
  ) async {
    final attendanceRecords = await _firebase.getAttendance();
    return attendanceRecords
        .where((record) =>
            record['date'] == date &&
            record['grade'] == grade &&
            record['class'] == className)
        .toList();
  }

  // Method to update attendance
  Future<void> updateAttendance(String attendanceId, bool isPresent) async {
    await _firebase.updateDocument('attendance', attendanceId, {
      'isPresent': isPresent,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Method to get attendance statistics
  Future<Map<String, dynamic>> getAttendanceStatistics(
    String studentId,
    String startDate,
    String endDate,
  ) async {
    final records = await _firebase.queryCollection(
      collection: 'attendance',
      field: 'studentId',
      value: studentId,
    );

    int totalDays = 0;
    int presentDays = 0;

    for (var record in records) {
      String recordDate = record['date'];
      if (recordDate.compareTo(startDate) >= 0 &&
          recordDate.compareTo(endDate) <= 0) {
        totalDays++;
        if (record['isPresent'] == true) {
          presentDays++;
        }
      }
    }

    return {
      'totalDays': totalDays,
      'presentDays': presentDays,
      'absentDays': totalDays - presentDays,
      'attendancePercentage': totalDays > 0
          ? (presentDays / totalDays * 100).toStringAsFixed(2)
          : '0',
    };
  }

  // Method to delete attendance record
  Future<void> deleteAttendance(String attendanceId) async {
    await _firebase.deleteDocument('attendance', attendanceId);
  }

  // Method to clear all attendance records
  Future<void> clearAll() async {
    final records = await _firebase.getAttendance();
    for (var record in records) {
      await _firebase.deleteDocument('attendance', record['id']);
    }
  }
}
