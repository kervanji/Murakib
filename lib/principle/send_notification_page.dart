import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendNotificationPage extends StatefulWidget {
  final String principalUsername;

  const SendNotificationPage({super.key, required this.principalUsername});

  @override
  _SendNotificationPageState createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  String? _selectedGrade;
  String? _selectedClass;
  List<Map<String, dynamic>> _grades = [];
  List<String> _classes = [];
  bool _sendToAll = false;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      final gradesSnapshot = await _firestore.collection('grades').get();
      setState(() {
        _grades = gradesSnapshot.docs
            .map((doc) => {
                  'name': doc['name'] as String,
                  'classes': (doc['classes'] as List<dynamic>).cast<String>(),
                })
            .toList();
      });
    } catch (e) {
      _showError('Error loading grades: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClasses(String grade) async {
    setState(() => _isLoading = true);
    try {
      final selectedGrade = _grades.firstWhere((g) => g['name'] == grade);
      setState(() {
        _classes = List<String>.from(selectedGrade['classes']);
        _selectedClass = null;
      });
    } catch (e) {
      _showError('Error loading classes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_sendToAll && _selectedGrade == null) {
      _showError('Please select a grade');
      return;
    }

    if (!_sendToAll && _selectedClass == null) {
      _showError('Please select a class');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get principal's school
      final principals = await _firestore
          .collection('principals')
          .where('username', isEqualTo: widget.principalUsername)
          .get();

      if (principals.docs.isEmpty) {
        _showError('Principal information not found');
        return;
      }

      final school = principals.docs.first['school'];

      // Create notification
      await _firestore.collection('notifications').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'school': school,
        'grade': _sendToAll ? 'all' : _selectedGrade,
        'class': _sendToAll ? 'all' : _selectedClass,
        'sender': widget.principalUsername,
        'senderType': 'principal',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });

      _showSuccess('Notification sent successfully');
      _resetForm();
    } catch (e) {
      _showError('Error sending notification: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _titleController.clear();
    _messageController.clear();
    setState(() {
      _selectedGrade = null;
      _selectedClass = null;
      _sendToAll = false;
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
          'Send Notification',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                labelText: 'Message',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a message';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CheckboxListTile(
                              title: const Text('Send to All'),
                              value: _sendToAll,
                              onChanged: (value) {
                                setState(() {
                                  _sendToAll = value ?? false;
                                });
                              },
                            ),
                            if (!_sendToAll) ...[
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedGrade,
                                decoration: const InputDecoration(
                                  labelText: 'Grade',
                                  border: OutlineInputBorder(),
                                ),
                                items: _grades.map((grade) {
                                  return DropdownMenuItem(
                                    value: grade['name'] as String,
                                    child: Text(grade['name'] as String),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGrade = value;
                                    if (value != null) {
                                      _loadClasses(value);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedClass,
                                decoration: const InputDecoration(
                                  labelText: 'Class',
                                  border: OutlineInputBorder(),
                                ),
                                items: _classes.map((className) {
                                  return DropdownMenuItem(
                                    value: className,
                                    child: Text(className),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedClass = value;
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _sendNotification,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Send Notification',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      backgroundColor: const Color(0xFFFDF1E5),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
