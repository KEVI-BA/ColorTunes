import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String artist;
  final String color;
  final String createdAt;
  final String songName;
  final String songUrl;
  final String userId;
  final List<String> comments;
  int likes;
  final String mood;
  List<String> likedBy;
  final String id;

  Post({
    required this.artist,
    required this.color,
    required this.createdAt,
    required this.songName,
    required this.songUrl,
    required this.userId,
    required this.comments,
    required this.likes,
    required this.mood,
    required this.likedBy,
    required this.id,
  });

  factory Post.fromMap(Map<String, dynamic> data, String id) {
    return Post(
      artist: data['artist'] ?? '',
      color: data['color'] ?? '',
      createdAt: data['created_at'] is Timestamp
          ? data['created_at']
          : Timestamp.now(),
      songName: data['song_name'] ?? '',
      songUrl: data['song_url'] ?? '',
      userId: data['userId'] ?? '',
      comments: List<String>.from(data['comments'] ?? []),
      likes: data['likes'] ?? 0,
      mood: data['mood'] ?? '',
      likedBy: List<String>.from(data['likedBy'] ?? []),
      id: id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'artist': artist,
      'color': color,
      'created_at': createdAt,
      'song_name': songName,
      'song_url': songUrl,
      'userId': userId,
      'comments': comments,
      'likes': likes,
      'mood': mood,
      'likedBy': likedBy,
    };
  }
}
