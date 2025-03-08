import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colortunes_beta/Screens/share_songs.dart';
import 'package:colortunes_beta/Widget/barra_menu.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:colortunes_beta/Api/music_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import 'package:colortunes_beta/Modelos/songs.dart';
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
      print("Error al cargar las canciones: $e");
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
      ];
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
                  const SizedBox(width: 150),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
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

  // Agregar este nuevo método
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
      }
    } catch (e) {
      print('Error en la búsqueda: $e');
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
                icon: const Icon(Icons.share),
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

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SharedSongsPage(user: widget.user, song: song),
                      ),
                    );
                  } catch (e) {
                    print("Error sharing song: $e");
                  }
                },
                iconSize: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
