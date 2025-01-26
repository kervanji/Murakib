import 'package:flutter/material.dart';
import 'package:murakib_vip/services/firebase_service.dart';
import 'package:intl/intl.dart';

class ExamsPage extends StatefulWidget {
  final String studentUsername;

  const ExamsPage({super.key, required this.studentUsername});

  @override
  _ExamsPageState createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  final FirebaseService _firebase = FirebaseService.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _exams = [];
  Map<String, dynamic>? _studentData;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      final students = await _firebase.queryCollection(
        collection: 'students',
        field: 'username',
        value: widget.studentUsername,
      );

      if (students.isEmpty) {
        _showError('Student information not found');
        return;
      }

      setState(() {
        _studentData = students.first;
      });

      await _loadExams();
    } catch (e) {
      _showError('Error loading student data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExams() async {
    if (_studentData == null) return;

    try {
      final examSnapshot = await _firebase.queryCollection(
        collection: 'exams',
        field: 'grade',
        value: _studentData!['grade'],
      );

      setState(() {
        _exams = examSnapshot
            .where((exam) =>
                exam['class'] == _studentData!['class'] ||
                exam['class'] == 'all')
            .map((doc) => {
                  'subject': doc['subject'] as String,
                  'date': doc['date'] as String,
                  'time': doc['time'] as String,
                  'duration': doc['duration'] as String,
                  'room': doc['room'] as String,
                  'type': doc['type'] as String,
                }).toList();

        // Sort by date, upcoming first
        _exams.sort((a, b) => a['date'].compareTo(b['date']));
      });
    } catch (e) {
      _showError('Error loading exams: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          'Exams Schedule',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentData == null
              ? const Center(child: Text('No student data found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Student Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _studentData!['name'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Grade: ${_studentData!['grade']} | Class: ${_studentData!['class']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Exams Summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upcoming Exams',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Total Exams: ${_exams.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Exams List
                      if (_exams.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No upcoming exams found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _exams.length,
                          itemBuilder: (context, index) {
                            final exam = _exams[index];
                            final examDate = DateTime.parse(exam['date']);
                            final isUpcoming = examDate.isAfter(DateTime.now());

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                title: Text(
                                  exam['subject'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('EEEE, MMM dd, yyyy')
                                      .format(examDate),
                                  style: TextStyle(
                                    color: isUpcoming
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getExamTypeColor(exam['type'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    exam['type'].toUpperCase(),
                                    style: TextStyle(
                                      color: _getExamTypeColor(exam['type']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildExamDetail(
                                          'Time',
                                          exam['time'],
                                          Icons.access_time,
                                        ),
                                        _buildExamDetail(
                                          'Duration',
                                          exam['duration'],
                                          Icons.timer,
                                        ),
                                        _buildExamDetail(
                                          'Room',
                                          exam['room'],
                                          Icons.room,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
      backgroundColor: const Color(0xFFFDF1E5),
    );
  }

  Color _getExamTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'final':
        return Colors.red;
      case 'midterm':
        return Colors.orange;
      case 'quiz':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildExamDetail(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
