import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isMe; // Da li je poruku poslao trenutni korisnik

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  // Dodajte factory konstruktor za kreiranje iz Firestore dokumenta ako je potrebno
  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      text: data['text'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isMe: data['isMe'],
    );
  }

  // Dodajte metodu za pretvaranje u mapu za Firestore ako je potrebno
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'isMe': isMe,
    };
  }
}
