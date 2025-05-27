import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import './chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final ChatService _chatService = ChatService();

  void _startNewChat(BuildContext context) async {
    final String otherUserId = _userIdController.text.trim();
    if (otherUserId.isNotEmpty) {
      final String? chatId = await _chatService.startChat(otherUserId);
      if (chatId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  conversationId: chatId,
                  receiverUserId: otherUserId,
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Greška pri pokretanju razgovora.')),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unesite ID korisnika.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novi razgovor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'Unesite ID korisnika s kojim želite razgovarati',
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () => _startNewChat(context),
              child: const Text('Započni razgovor'),
            ),
          ],
        ),
      ),
    );
  }
}
