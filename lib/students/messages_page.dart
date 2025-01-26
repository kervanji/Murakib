import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MessagesPage extends StatefulWidget {
  final String studentUsername;

  const MessagesPage({super.key, required this.studentUsername});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _studentData;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('username', isEqualTo: widget.studentUsername)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        _showError('Student information not found');
        return;
      }

      setState(() {
        _studentData = studentsSnapshot.docs.first.data();
      });

      await _loadMessages();
    } catch (e) {
      _showError('Error loading student data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_studentData == null) return;

    try {
      final messageSnapshot = await _firestore
          .collection('messages')
          .where('studentUsername', isEqualTo: widget.studentUsername)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _messages = messageSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'message': doc['message'] as String,
                  'timestamp': doc['timestamp'] as String,
                  'isRead': doc['isRead'] as bool,
                  'response': doc['response'] as String?,
                  'responseTimestamp': doc['responseTimestamp'] as String?,
                })
            .toList();
      });
    } catch (e) {
      _showError('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showError('Please enter a message');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final timestamp = DateTime.now().toIso8601String();

      await _firestore.collection('messages').add({
        'studentUsername': widget.studentUsername,
        'message': _messageController.text.trim(),
        'timestamp': timestamp,
        'isRead': false,
        'response': null,
        'responseTimestamp': null,
      });

      _messageController.clear();
      await _loadMessages();
      _showSuccess('Message sent successfully');
    } catch (e) {
      _showError('Error sending message: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
          'Messages',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentData == null
              ? const Center(child: Text('No student data found'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
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

                            // Messages List
                            if (_messages.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      'No messages found',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ExpansionTile(
                                      title: Text(
                                        message['message'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        DateFormat('MMM dd, yyyy HH:mm').format(
                                          DateTime.parse(message['timestamp']),
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: message['isRead']
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          message['isRead'] ? 'READ' : 'UNREAD',
                                          style: TextStyle(
                                            color: message['isRead']
                                                ? Colors.green
                                                : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      children: [
                                        if (message['response'] != null)
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Response:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(message['response']!),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Responded on: ${DateFormat('MMM dd, yyyy HH:mm').format(
                                                    DateTime.parse(
                                                      message[
                                                          'responseTimestamp']!,
                                                    ),
                                                  )}',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
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
                    ),
                    // Message Input
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type your message...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _sendMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      backgroundColor: const Color(0xFFFDF1E5),
    );
  }
}
