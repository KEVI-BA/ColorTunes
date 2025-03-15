import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:colortunes_beta/Datos/songs.dart';

class MusicService {
  // Change from _randomSearchTerms to randomSearchTerms
  final List<String> randomSearchTerms = [
    'pop',
    'jazz',
    'hip hop',
    'country',
    'electronic',
    'reggaeton',
    'metal',
    'folk',
    'ambient',
    'alternative',
    'dancehall',
    'disco',
    'trap',
    'techno',
    'house',
    'dubstep',
    'synthwave',
    'psytrance',
    'reggae',
    'merengue',
    'flamenco',
    'cumbia',
    'corridos',
    'bolero',
    'ranchera',
    'trova',
    'mariachi',
    'bossa nova',
    'tango',
    'trap latino',
    'vallenato',
    'samba',
    'rumba',
    'bachata',
    'norteño',
    'paseo',
    'son cubano',
    'canción romántica',
    'balada',
    'pop latino'
  ];

  Future<List<Song>> getRandomSongs({String? genre}) async {
    final searchTerm =
        genre ?? randomSearchTerms[Random().nextInt(randomSearchTerms.length)];
    final response = await http.get(
      Uri.parse('https://itunes.apple.com/search?term=$searchTerm&entity=song'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null) {
        List<Song> songs = (data['results'] as List)
            .map((song) => Song.fromApi(song))
            .toList();
        return songs;
      } else {
        throw Exception('No songs found in the response');
      }
    } else {
      throw Exception('Failed to load songs');
    }
  }
}
