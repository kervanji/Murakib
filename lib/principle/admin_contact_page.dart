import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminContactPage extends StatefulWidget {
  final String principalUsername;

  const AdminContactPage({super.key, required this.principalUsername});

  @override
  _AdminContactPageState createState() => _AdminContactPageState();
}

class _AdminContactPageState extends State<AdminContactPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _titleController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messagesSnapshot = await _firestore
          .collection('admin_messages')
          .where('sender', isEqualTo: widget.principalUsername)
          .get();

      setState(() {
        _messages = messagesSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            ...data,
            'id': doc.id, // Add the document ID to the map
          };
        }).toList();

        // Sort messages by timestamp, newest first
        _messages.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      });
    } catch (e) {
      _showError('Error loading messages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

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

      // Send message
      await _firestore.collection('admin_messages').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'sender': widget.principalUsername,
        'senderType': 'principal',
        'school': school,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'response': null,
        'responseTimestamp': null,
      });

      _showSuccess('Message sent successfully');
      _titleController.clear();
      _messageController.clear();
      _loadMessages();
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
          'Contact Admin',
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
                  // New Message Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'New Message',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _sendMessage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Send Message',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Message History
                  if (_messages.isNotEmpty) ...[
                    const Text(
                      'Message History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                              message['title'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              DateFormat('MMM dd, yyyy HH:mm')
                                  .format(DateTime.parse(message['timestamp'])),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: message['response'] != null
                                    ? Colors.green
                                    : message['read']
                                        ? Colors.blue
                                        : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message['response'] != null
                                    ? 'REPLIED'
                                    : message['read']
                                        ? 'READ'
                                        : 'SENT',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Message:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(message['message']),
                                    if (message['response'] != null) ...[
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Admin Response:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(message['response']),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Responded on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(message['responseTimestamp']))}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No messages yet',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
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
