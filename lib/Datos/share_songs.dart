import 'package:cloud_firestore/cloud_firestore.dart';

class SharedSong {
  final String id;
  final String songName;
  final String songUrl;
  final String image;
  final String userAvatarUrl;
  final String username;
  final String userId;
  final Timestamp timestamp;
  final List<String> likes;
  final String artist;
  final String mood;

  SharedSong({
    required this.id,
    required this.songName,
    required this.songUrl,
    required this.image,
    required this.userAvatarUrl,
    required this.username,
    required this.userId,
    required this.timestamp,
    required this.likes,
    required this.artist,
    required this.mood,
  });

  factory SharedSong.fromMap(Map<String, dynamic> map, String id) {
    return SharedSong(
      id: id,
      songName: map['songName'] ?? '',
      songUrl: map['songUrl'] ?? '',
      image: map['image'] ?? '',
      userAvatarUrl: map['sharedByPhoto'] ?? '',
      username: map['shareByName'] ?? '',
      userId: map['sharedBy'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      likes: List<String>.from(map['likes'] ?? []),
      artist: map['artist'] ?? '',
      mood: map['mood'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'songName': songName,
      'songUrl': songUrl,
      'image': image,
      'sharedByPhoto': userAvatarUrl,
      'shareByName': username,
      'sharedBy': userId,
      'timestamp': timestamp,
      'likes': likes,
      'artist': artist,
      'mood': mood,
    };
  }
}
