import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String text;
  final String senderId;
  final String senderName;
  final DateTime time;
  final String? songName;
  final String? songUrl;
  final String? imageUrl;

  ChatMessage({
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.time,
    this.songName,
    this.songUrl,
    this.imageUrl,
  });

  // Método para crear un ChatMessage desde un Map (Firestore)
  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Usuario',
      time: (data['timestamp'] as Timestamp).toDate(), // Usar 'timestamp'
      songName: data['songName'],
      songUrl: data['songUrl'],
      imageUrl: data['imageUrl'],
    );
  }

  // Método para convertir un ChatMessage a un Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': Timestamp.fromDate(time), // Usar 'timestamp'
      'songName': songName,
      'songUrl': songUrl,
      'imageUrl': imageUrl,
    };
  }
}
