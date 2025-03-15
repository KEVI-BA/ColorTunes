import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colortunes_beta/Presentacion/Widget/barra_menu.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:colortunes_beta/Negocio/Api/music_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import 'package:colortunes_beta/Datos/songs.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MusicSearchPage extends StatefulWidget {
  final User user;
  const MusicSearchPage({super.key, required this.user});

  @override
  _MusicSearchPageState createState() => _MusicSearchPageState();
}

class _MusicSearchPageState extends State<MusicSearchPage>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  List<Song> _songs = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Color> _gradientColors = [Colors.blue, Colors.purple, Colors.red];
  Timer? _colorChangeTimer;
  int _currentSongIndex = 0;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  // ignore: unused_field
  int _currentIndex = 0;
  // Agregar estas nuevas variables
  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isSearching = false;
  // ignore: unused_field
  final _selectedGenre = '';

  @override
  void initState() {
    super.initState();

    _loadSongs();
    _colorChangeTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _changeGradientColors();
    });

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _rotationAnimation = Tween(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _colorChangeTimer?.cancel();
    _audioPlayer.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _loadSongs() async {
    try {
      final songs = await _musicService.getRandomSongs();
      setState(() {
        _songs = songs;
      });
      if (_songs.isNotEmpty) {
        _audioPlayer.play(UrlSource(_songs[0].previewUrl));
      }
    } catch (e) {
      debugPrint("Error al cargar las canciones: $e");
    }
  }

  void _loadSongsByGenre(String genre) async {
    try {
      final songs = await _musicService.getRandomSongs(genre: genre);
      setState(() {
        _songs = songs;
      });
      if (_songs.isNotEmpty) {
        _audioPlayer.play(UrlSource(_songs[0].previewUrl));
      }
    } catch (e) {
      throw Exception("Error al cargar las canciones: $e");
    }
  }

  void _changeGradientColors() {
    final random = Random();
    setState(() {
      _gradientColors = [
        Color.fromRGBO(
            random.nextInt(256), random.nextInt(256), random.nextInt(256), 1),
        Color.fromRGBO(
            random.nextInt(256), random.nextInt(256), random.nextInt(256), 1),
        Color.fromRGBO(
            random.nextInt(256), random.nextInt(256), random.nextInt(256), 1),
        Color.fromRGBO(
            random.nextInt(256), random.nextInt(256), random.nextInt(256), 1),
      ];
    });
  }

  Future<List<String>> _getFollowing() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('following')
          .get();

      // Obtener los IDs de los usuarios seguidos
      List<String> following = snapshot.docs.map((doc) => doc.id).toList();
      return following;
    } catch (e) {
      throw Exception("Error al obtener mis seguidores: $e");
    }
  }

  void _showFollowerSelectionDialog(Song song) async {
    try {
      List<String> followings = await _getFollowing();

      if (followings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No tienes seguidos para compartir la canción.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Crear una lista de Futures para obtener los detalles de los seguidores en paralelo
      List<Future<DocumentSnapshot>> userFutures = followings.map((followerId) {
        return FirebaseFirestore.instance
            .collection('users')
            .doc(followerId)
            .get();
      }).toList();

      // Esperar a que todos los datos se obtengan
      List<DocumentSnapshot> userDocs = await Future.wait(userFutures);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Selecciona un usuario para compartir'),
            content: SingleChildScrollView(
              child: Column(
                children: userDocs.map((followerDoc) {
                  if (followerDoc.exists) {
                    var followerData = followerDoc;
                    String followerName =
                        followerData['displayName'] ?? 'Usuario';
                    String followerPhotoUrl = followerData['photoURL'] ?? '';

                    return ListTile(
                      title: Text(followerName),
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(followerPhotoUrl),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _shareSongAsMessage(song, followerDoc.id);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cargar mis seguidos: $e'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _shareSongAsMessage(Song song, String recipientId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      String userPhotoUrl = userDoc['photoURL'] ?? "";
      String userDisplayName = userDoc['displayName'] ?? "";

      List<String> ids = [widget.user.uid, recipientId];
      ids.sort();
      String chatRoomId = ids.join('_');

      // Crea un mensaje con la información de la canción
      final message = {
        'text': '¡Escucha esta canción! ${song.name} de ${song.artist}',
        'senderId': widget.user.uid,
        'senderName': userDisplayName,
        'senderPhotoUrl': userPhotoUrl,
        'songName': song.name,
        'songUrl': song.previewUrl,
        'imageUrl': song.imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Guarda el mensaje en la colección de mensajes de Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add(message);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('¡Canción compartida como mensaje con éxito!'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al compartir la canción'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
      ));
    }
  }

  //Dialogo
  void _showGenreDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Seleciona el género que quieras escuchar'),
              content: SingleChildScrollView(
                  child: Column(
                children: _musicService.randomSearchTerms.map((genre) {
                  return ListTile(
                    title: Text(genre),
                    onTap: () {
                      Navigator.of(context).pop();
                      _loadSongsByGenre(genre);
                    },
                  );
                }).toList(),
              )));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar canciones...',
                  hintStyle: const TextStyle(color: Colors.black),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _audioPlayer.stop();
                      _audioPlayer.play(UrlSource(_songs[0].previewUrl));
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                        _searchResults.clear();
                      });
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                onSubmitted: _performSearch,
              )
            : Row(
                children: [
                  CircleAvatar(
                    backgroundImage: widget.user.photoURL != null &&
                            widget.user.photoURL!.isNotEmpty
                        ? NetworkImage(widget.user.photoURL!)
                        : null,
                    child: widget.user.photoURL == null ||
                            widget.user.photoURL!.isEmpty
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(widget.user.displayName ?? 'Usuario'),
                  const SizedBox(width: 70),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showGenreDialog,
                  ),
                ],
              ),
      ),
      body: _songs.isEmpty && !_isSearching
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount:
                          _isSearching ? _searchResults.length : _songs.length,
                      itemBuilder: (context, index) {
                        final song = _isSearching
                            ? _searchResults[index]
                            : _songs[index];
                        return _buildSongCard(song);
                      },
                      onPageChanged: (index) {
                        setState(() {
                          _currentSongIndex = index;
                          _audioPlayer.play(
                            UrlSource(_isSearching
                                ? _searchResults[index].previewUrl
                                : _songs[index].previewUrl),
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomNavBar(
        user: widget.user,
        song: _songs.isNotEmpty
            ? _songs[_currentSongIndex]
            : Song(
                artist: '',
                genre: '',
                name: '',
                url: '',
                imageUrl: '',
                previewUrl: '',
                userAvatarUrl: '',
                username: ''),
        currentIndex: 0,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }
    try {
      final response = await http.get(
        Uri.parse(
            'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=song'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          setState(() {
            _searchResults = (data['results'] as List)
                .map((song) => Song.fromApi(song))
                .toList();
          });
        }

        if (_searchResults.isNotEmpty) {
          try {
            await _audioPlayer.stop();
            _audioPlayer.play(
              UrlSource(_searchResults[0].previewUrl),
            );
          } catch (e) {
            throw Exception('Error al cargar las canciones: $e');
          }
        }
      } else {
        throw Exception('Error en la búsqueda: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la búsqueda: $e');
    }
  }

  Widget _buildSongCard(Song song) {
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: ClipOval(
                      child: Image.network(
                        song.imageUrl,
                        width: 130.0,
                        height: 130.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                song.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                song.artist,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              IconButton(
                icon: const Icon(Icons.publish),
                onPressed: () async {
                  try {
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.user.uid)
                        .get();

                    String userPhotoUrl = userDoc['photoURL'] ?? "";
                    String userDisplayName = userDoc['displayName'] ?? "";

                    await FirebaseFirestore.instance
                        .collection('shared_songs')
                        .add({
                      'songName': song.name,
                      'songUrl': song.previewUrl,
                      'sharedBy': widget.user.uid,
                      'sharedByPhoto': userPhotoUrl,
                      'shareByName': userDisplayName,
                      'timestamp': FieldValue.serverTimestamp(),
                      'image': song.imageUrl,
                      'comments': "",
                      'likes': [],
                      'mood': "",
                      'artist': song.artist,
                      'color': "",
                      'created_at': FieldValue.serverTimestamp(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('¡Publicación realizada con éxito!'),
                        duration: Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Error al publicar la canción'),
                        duration: Duration(seconds: 3),
                        backgroundColor: Colors.red));
                  }
                },
                iconSize: 40,
              ),
              IconButton(
                  onPressed: () {
                    _showFollowerSelectionDialog(song);
                  },
                  icon: const Icon(Icons.share))
            ],
          ),
        ),
      ),
    );
  }
}
