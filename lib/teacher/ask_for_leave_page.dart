import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AskForLeavePage extends StatefulWidget {
  final String teacherUsername;

  const AskForLeavePage({super.key, required this.teacherUsername});

  @override
  _AskForLeavePageState createState() => _AskForLeavePageState();
}

class _AskForLeavePageState extends State<AskForLeavePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _teacherName;
  String? _principalUsername;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      final teacherDoc = await _firestore
          .collection('teachers')
          .where('username', isEqualTo: widget.teacherUsername)
          .get();

      if (teacherDoc.docs.isNotEmpty) {
        final teacherData = teacherDoc.docs.first.data();
        setState(() {
          _teacherName = teacherData['name'];
        });

        // Get principal for the teacher's school
        final principalDoc = await _firestore
            .collection('principals')
            .where('school', isEqualTo: teacherData['school'])
            .get();

        if (principalDoc.docs.isNotEmpty) {
          setState(() {
            _principalUsername = principalDoc.docs.first['username'];
          });
        }
      }
    } catch (e) {
      _showError('Error loading teacher data: $e');
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, reset it
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (_startDate == null || _endDate == null) {
      _showError('Please select both start and end dates');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showError('Please provide a reason for leave');
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showError('End date cannot be before start date');
      return;
    }

    if (_principalUsername == null) {
      _showError('Could not find principal information');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final batch = _firestore.batch();

      // Create leave request
      final leaveRef = _firestore.collection('leave_requests').doc();
      batch.set(leaveRef, {
        'teacherUsername': widget.teacherUsername,
        'teacherName': _teacherName,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'submittedAt': DateTime.now().toIso8601String(),
      });

      // Create notification for principal
      final notificationRef = _firestore.collection('notifications').doc();
      final duration = _endDate!.difference(_startDate!).inDays + 1;
      final message =
          'Leave request from $_teacherName\nDuration: $duration days\nReason: ${_reasonController.text.trim()}';

      batch.set(notificationRef, {
        'title': 'New Leave Request',
        'message': message,
        'recipientUsername': _principalUsername,
        'recipientType': 'principal',
        'sender': widget.teacherUsername,
        'senderType': 'teacher',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'leaveRequestId': leaveRef.id,
      });

      await batch.commit();

      _showSuccess('Leave request submitted successfully');
      _resetForm();
    } catch (e) {
      _showError('Error submitting leave request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          'Request Leave',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Leave Duration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateSelector(
                                  'Start Date',
                                  _startDate,
                                  () => _selectDate(true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDateSelector(
                                  'End Date',
                                  _endDate,
                                  () => _selectDate(false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reason for Leave',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _reasonController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Enter your reason for leave...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitLeaveRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      'Submit Request',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      backgroundColor: const Color(0xFFFDF1E5),
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime? selectedDate,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedDate == null
                  ? 'Select Date'
                  : DateFormat('MMM dd, yyyy').format(selectedDate),
              style: TextStyle(
                fontSize: 16,
                color: selectedDate == null ? Colors.grey : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
