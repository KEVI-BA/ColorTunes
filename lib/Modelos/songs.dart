// lib/Modelos/song.dart

class Song {
  final String artist;
  final String genre;
  final String name;
  final String url;
  final String imageUrl;
  final String previewUrl;
  final String userAvatarUrl;
  final String username;

  Song({
    required this.artist,
    required this.genre,
    required this.name,
    required this.url,
    required this.imageUrl,
    required this.previewUrl,
    required this.userAvatarUrl,
    required this.username,
  });

  // Crear una instancia de Song desde los datos de la API (iTunes)
  factory Song.fromApi(Map<String, dynamic> data) {
    return Song(
      artist: data['artistName'] ?? '',
      genre: data['primaryGenreName'] ?? '',
      name: data['trackName'] ?? '',
      url: data['collectionViewUrl'] ?? '',
      imageUrl: data['artworkUrl100'] ?? '',
      previewUrl: data['previewUrl'] ?? '',
      userAvatarUrl: data['sharedByPhoto'] ?? '',
      username: data['shareByName'] ?? '',
    );
  }

  // Método para convertir un objeto Song a un mapa (por si necesitas usarlo en Firebase u otros)
  Map<String, dynamic> toMap() {
    return {
      'artist': artist,
      'genre': genre,
      'name': name,
      'url': url,
      'imageUrl': imageUrl,
      'previewUrl': previewUrl,
    };
  }
}
