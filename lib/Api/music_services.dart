import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class MusicService {
  final List<String> _randomSearchTerms = [
    'pop',
    'rock',
    'jazz',
    'classical',
    'hip hop',
    'country',
    'electronic',
    'indie',
  ];

  Future<List<Song>> getRandomSongs() async {
    final randomTerm =
        _randomSearchTerms[Random().nextInt(_randomSearchTerms.length)];
    final response = await http.get(
      Uri.parse('https://itunes.apple.com/search?term=$randomTerm&entity=song'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Song> songs =
          (data['results'] as List).map((song) => Song.fromJson(song)).toList();
      return songs;
    } else {
      throw Exception('Failed to load songs');
    }
  }
}

class Song {
  final String title;
  final String imageUrl;
  final String previewUrl;
  final String artist;

  Song({
    required this.title,
    required this.imageUrl,
    required this.previewUrl,
    required this.artist,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['trackName'],
      imageUrl: json['artworkUrl100'],
      previewUrl: json['previewUrl'],
      artist: json['artistName'],
    );
  }
}
