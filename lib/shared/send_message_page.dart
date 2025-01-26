import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendMessagePage extends StatefulWidget {
  final String senderUsername;
  final String senderName;
  final String senderType; // 'student', 'teacher', 'principal', 'admin'
  final String? recipientUsername; // Optional, if pre-selected
  final String? recipientType; // Optional, if pre-selected

  const SendMessagePage({
    super.key,
    required this.senderUsername,
    required this.senderName,
    required this.senderType,
    this.recipientUsername,
    this.recipientType,
  });

  @override
  State<SendMessagePage> createState() => _SendMessagePageState();
}

class _SendMessagePageState extends State<SendMessagePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;
  String? _selectedRecipientType;
  String? _selectedRecipient;
  List<Map<String, dynamic>> _availableRecipients = [];

  @override
  void initState() {
    super.initState();
    _selectedRecipientType = widget.recipientType;
    _selectedRecipient = widget.recipientUsername;
    if (_selectedRecipientType != null) {
      _loadRecipients(_selectedRecipientType!);
    }
  }

  Future<void> _loadRecipients(String recipientType) async {
    setState(() => _isLoading = true);
    try {
      // Get sender's school context
      String? school;
      final senderDoc = await _firestore
          .collection(widget.senderType == 'admin' ? 'admins' : '${widget.senderType}s')
          .where('username', isEqualTo: widget.senderUsername)
          .get();

      if (senderDoc.docs.isNotEmpty) {
        school = senderDoc.docs.first['school'];
      }

      // Load recipients based on type and school context
      final recipientsSnapshot = await _firestore
          .collection('${recipientType}s')
          .where('school', isEqualTo: school)
          .get();

      setState(() {
        _availableRecipients = recipientsSnapshot.docs
            .map((doc) => {
                  'username': doc['username'] as String,
                  'name': doc['name'] as String,
                })
            .toList();
      });
    } catch (e) {
      _showError('Error loading recipients: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRecipientType == null || _selectedRecipient == null) {
      _showError('Please select a recipient');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final messageData = {
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'senderUsername': widget.senderUsername,
        'senderName': widget.senderName,
        'senderType': widget.senderType,
        'recipientUsername': _selectedRecipient,
        'recipientType': _selectedRecipientType,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      await _firestore.collection('messages').add(messageData);
      
      if (!mounted) return;
      _showSuccess('Message sent successfully');
      Navigator.pop(context);
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
          'Send Message',
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
                    if (widget.recipientType == null) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedRecipientType,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Type',
                          border: OutlineInputBorder(),
                        ),
                        items: <String>['student', 'teacher', 'principal', 'admin']
                            .map<DropdownMenuItem<String>>((String type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRecipientType = value;
                            _selectedRecipient = null;
                            if (value != null) {
                              _loadRecipients(value);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_selectedRecipientType != null) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedRecipient,
                        decoration: const InputDecoration(
                          labelText: 'Recipient',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableRecipients
                            .map<DropdownMenuItem<String>>((recipient) => DropdownMenuItem<String>(
                                  value: recipient['username'] as String,
                                  child: Text(
                                      '${recipient['name']} (${recipient['username']})'),
                                ))
                            .toList(),
                        onChanged: widget.recipientUsername == null
                            ? (value) {
                                setState(() {
                                  _selectedRecipient = value;
                                });
                              }
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
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
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Send Message',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
