import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:colortunes_beta/Modelos/songs.dart';

class MusicService {
  final List<String> _randomSearchTerms = [
    // Géneros en inglés
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

  Future<List<Song>> getRandomSongs() async {
    final randomTerm =
        _randomSearchTerms[Random().nextInt(_randomSearchTerms.length)];
    final response = await http.get(
      Uri.parse('https://itunes.apple.com/search?term=$randomTerm&entity=song'),
    );

    if (response.statusCode == 200) {
      // Verificar la respuesta completa
      print(response
          .body); // Verifica si la respuesta tiene la estructura esperada

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
