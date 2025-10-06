import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart'; // Import ChatService

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String receiverUserId; // Trebat će vam ID drugog korisnika

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _receiverUserName;
  @override
  void initState() {
    super.initState();
    _loadReceiverUserName();
  }

  Future<void> _loadReceiverUserName() async {
    try {
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.receiverUserId)
              .get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _receiverUserName = userData['displayName'] as String?;
        });
      } else {
        setState(() {
          _receiverUserName = 'Nepoznato';
        });
      }
    } catch (e) {
      setState(() {
        _receiverUserName = 'Greška';
        print('Greška prilikom dohvaćanja imena primatelja: $e');
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(
        widget.conversationId,
        _messageController.text.trim(),
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_receiverUserName ?? 'Učitavanje...')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _chatService.getChatMessages(widget.conversationId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Došlo je do greške pri učitavanju poruka.'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data ?? [];
                  return ListView.builder(
                    reverse: true, // Prikaz najnovijih poruka na dnu
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          _buildMessage(messages[index]),
                          const SizedBox(height: 4.0),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final bool isMe = message.isMe;
    return Align(
      alignment: isMe ? Alignment.topRight : Alignment.topLeft,
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isMe)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 15,
                child: Icon(Icons.person, size: 18),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[200] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(message.text),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Text(
                    _formatTimestamp(message.timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 10.0),
                  ),
                ),
              ],
            ),
          ),
          if (isMe)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                radius: 15,
                child: Icon(Icons.person, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'; // Jednostavan format
    // Možete koristiti naprednije formate s `intl` paketom ako želite
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: 'Unesite poruku...'),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
        ],
      ),
    );
  }
}
