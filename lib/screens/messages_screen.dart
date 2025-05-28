import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './chat_screen.dart';
import '../models/chat_message.dart';
import './new_chat_screen.dart';
import './majstor_details_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  Future<String?> _getUserName(String userId) async {
    try {
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['displayName'] as String?;
      }
    } catch (e) {
      print('Greška prilikom dohvaćanja imena korisnika: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ChatService _chatService = ChatService();
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Poruke')),
      body:
          currentUserId == null
              ? const Center(child: Text('Niste prijavljeni.'))
              : StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getUserChatsWithLastMessage(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Došlo je do greške: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chatsWithLastMessage = snapshot.data ?? [];
                  if (chatsWithLastMessage.isEmpty) {
                    return const Center(
                      child: Text('Nemate aktivnih razgovora.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: chatsWithLastMessage.length,
                    itemBuilder: (context, index) {
                      final chatInfo = chatsWithLastMessage[index];
                      final chatId = chatInfo['chatId'] as String;
                      final lastMessage =
                          chatInfo['lastMessage'] as ChatMessage?;
                      // Sada 'chatId' je String, pa možemo koristiti replaceAll
                      final otherUserId = chatId
                          .replaceAll(currentUserId, '')
                          .replaceAll('_', '');

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: FutureBuilder<String?>(
                            future: _getUserName(otherUserId),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text('Učitavanje...');
                              }
                              if (userSnapshot.hasError) {
                                return const Text('Greška');
                              }
                              return Text(
                                'Razgovor s: ${userSnapshot.data ?? 'Nepoznato'}',
                              );
                            },
                          ),
                          subtitle: Text(lastMessage?.text ?? 'Nema poruka'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ChatScreen(
                                      // Sada pravilno prosljeđujemo chatId kao String
                                      conversationId: chatId,
                                      receiverUserId: otherUserId,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewChatScreen()),
              );
            },
          ),
          const SizedBox(height: 16.0),
          FloatingActionButton(
            // Novi gumb za testiranje
            child: const Icon(Icons.person_search),
            onPressed: () {
              // Zamijenite 'NEKI_ID_MAJSTORA' sa stvarnim ID-jem majstora iz vaše baze
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => const MajstorDetailsScreen(
                        majstorId: 'NEKI_ID_MAJSTORA',
                      ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
