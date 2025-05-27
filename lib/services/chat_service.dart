import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart'; // Import ChatMessage model

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Metoda za slanje nove poruke
  Future<void> sendMessage(String chatId, String text) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String receiverId = chatId
        .replaceAll(currentUserId, '')
        .replaceAll(
          '_',
          '',
        ); // Jednostavno izdvajanje drugog korisnika iz chatId-a (pretpostavljamo format 'uid1_uid2')

    final message = ChatMessage(
      senderId: currentUserId,
      receiverId: receiverId,
      text: text.trim(),
      timestamp:
          DateTime.now(), // Koristimo lokalno vrijeme za sada, kasnije prebaciti na serverTimestamp
      isMe: true,
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toFirestore());

    // Ažurirajte timestamp zadnje poruke u glavnom dokumentu chata
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // Metoda za dohvaćanje stream-a poruka za određeni chat
  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => ChatMessage.fromFirestore(doc as Map<String, dynamic>),
              )
              .toList();
        });
  }

  // Metoda za dohvaćanje stream-a aktivnih razgovora za korisnika
  Stream<List<String>> getUserChats() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('chats')
        .where(
          'userIds',
          arrayContains: currentUserId,
        ) // Pretpostavljamo da imate polje 'userIds' (niz UID-ova) u dokumentu chata
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Ovdje ćete morati izvući ID drugog korisnika i/ili informacije o razgovoru
            // Za sada vraćamo samo ID dokumenta chata
            return doc.id;
          }).toList();
        });
  }

  // Metoda za kreiranje jedinstvenog ID-a chata između dva korisnika
  String getChatId(String userId1, String userId2) {
    if (userId1.compareTo(userId2) < 0) {
      return '${userId1}_${userId2}';
    } else {
      return '${userId2}_${userId1}';
    }
  }

  Stream<List<Map<String, dynamic>>> getUserChatsWithLastMessage() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('chats')
        .where('userIds', arrayContains: currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Map<String, dynamic>> chatsWithLastMessage = [];
          for (final doc in snapshot.docs) {
            final chatId = doc.id;
            ChatMessage? lastMessage;
            final messagesSnapshot =
                await _firestore
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get();

            if (messagesSnapshot.docs.isNotEmpty) {
              lastMessage = ChatMessage.fromFirestore(
                messagesSnapshot.docs.first as Map<String, dynamic>,
              );
            }

            chatsWithLastMessage.add({
              'chatId': chatId,
              'lastMessage': lastMessage,
            });
          }
          return chatsWithLastMessage;
        });
  }

  Future<String?> startChat(String otherUserId) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = getChatId(currentUserId, otherUserId);

    final DocumentSnapshot chatSnapshot =
        await _firestore.collection('chats').doc(chatId).get();

    if (!chatSnapshot.exists) {
      // Kreiraj novi chat dokument ako ne postoji
      await _firestore.collection('chats').doc(chatId).set({
        'userIds': [currentUserId, otherUserId],
        'lastMessageTimestamp':
            FieldValue.serverTimestamp(), // Postavi početni timestamp
      });
    }

    return chatId;
  }
}

// Ažurirajte model ChatMessage sa factory konstruktorom i toFirestore metodom
extension ChatMessageExtension on ChatMessage {
  static ChatMessage fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ChatMessage(
      senderId: data['senderId'] as String,
      receiverId: data['receiverId'] as String,
      text: data['text'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isMe: data['senderId'] == FirebaseAuth.instance.currentUser?.uid,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
