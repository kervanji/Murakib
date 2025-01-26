import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MessagesInboxPage extends StatefulWidget {
  final String username;
  final String userType; // 'student', 'teacher', 'principal', 'admin'

  const MessagesInboxPage({
    super.key,
    required this.username,
    required this.userType,
  });

  @override
  State<MessagesInboxPage> createState() => _MessagesInboxPageState();
}

class _MessagesInboxPageState extends State<MessagesInboxPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
          .collection('messages')
          .where('recipientUsername', isEqualTo: widget.username)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _messages = messagesSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      _showError('Error loading messages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
      });

      setState(() {
        final index = _messages.indexWhere((msg) => msg['id'] == messageId);
        if (index != -1) {
          _messages[index]['isRead'] = true;
        }
      });
    } catch (e) {
      _showError('Error marking message as read: $e');
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
      setState(() {
        _messages.removeWhere((msg) => msg['id'] == messageId);
      });
      _showSuccess('Message deleted successfully');
    } catch (e) {
      _showError('Error deleting message: $e');
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('MMM d, y h:mm a').format(date);
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No messages',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _messages.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final bool isRead = message['isRead'] ?? false;

                    return Dismissible(
                      key: Key(message['id']),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteMessage(message['id']);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            message['title'] ?? 'No Title',
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message['message'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                'From: ${message['senderName'] ?? message['senderUsername'] ?? 'Unknown'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatTimestamp(message['timestamp']),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: !isRead
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(message['id']);
                            }
                            // Show message details in a dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(message['title'] ?? 'No Title'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(message['message'] ?? ''),
                                      const SizedBox(height: 16),
                                      Text(
                                        'From: ${message['senderName'] ?? message['senderUsername'] ?? 'Unknown'}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        _formatTimestamp(message['timestamp']),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
