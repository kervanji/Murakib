import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendMessageToPrincipalPage extends StatefulWidget {
  final String teacherUsername;

  const SendMessageToPrincipalPage({super.key, required this.teacherUsername});

  @override
  _SendMessageToPrincipalPageState createState() =>
      _SendMessageToPrincipalPageState();
}

class _SendMessageToPrincipalPageState
    extends State<SendMessageToPrincipalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String? _teacherSchool;
  String? _principalUsername;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);
    try {
      // Get teacher's school
      final teacherDoc = await _firestore
          .collection('teachers')
          .where('username', isEqualTo: widget.teacherUsername)
          .get();

      if (teacherDoc.docs.isEmpty) {
        throw Exception('Teacher not found');
      }

      _teacherSchool = teacherDoc.docs.first['school'] as String;

      // Get principal's username for the school
      final principalDoc = await _firestore
          .collection('principals')
          .where('school', isEqualTo: _teacherSchool)
          .get();

      if (principalDoc.docs.isEmpty) {
        throw Exception('Principal not found for school');
      }

      _principalUsername = principalDoc.docs.first['username'] as String;
    } catch (e) {
      _showError('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showError('Please enter a message');
      return;
    }

    if (_teacherSchool == null || _principalUsername == null) {
      _showError('Unable to send message: School or principal not found');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Create message document
      await _firestore.collection('principal_messages').add({
        'teacherUsername': widget.teacherUsername,
        'principalUsername': _principalUsername,
        'school': _teacherSchool,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'response': null,
        'responseTimestamp': null,
      });

      // Create notification for principal
      await _firestore.collection('notifications').add({
        'recipientUsername': _principalUsername,
        'type': 'teacher_message',
        'title': 'New Message from Teacher',
        'message':
            'You have received a new message from ${widget.teacherUsername}',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'senderUsername': widget.teacherUsername,
        'school': _teacherSchool,
      });

      _messageController.clear();
      _showSuccess('Message sent successfully');
    } catch (e) {
      _showError('Error sending message: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        title: const Text(
          'Send Message to Principal',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          hintText: "Tap to write...",
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text(
                      "Send",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
