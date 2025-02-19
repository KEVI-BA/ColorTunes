import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:colortunes_beta/Api/music_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';

class MusicSearchPage extends StatefulWidget {
  final User user;

  const MusicSearchPage({Key? key, required this.user}) : super(key: key);

  @override
  _MusicSearchPageState createState() => _MusicSearchPageState();
}

class _MusicSearchPageState extends State<MusicSearchPage> {
  final MusicService _musicService = MusicService();
  List<Song> _songs = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Color> _gradientColors = [Colors.blue, Colors.purple, Colors.red];
  Timer? _colorChangeTimer;
  Set<String> _likedSongs = {}; // Almacena los "me gusta"

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _loadLikedSongs();
    _colorChangeTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _changeGradientColors();
    });
  }

  @override
  void dispose() {
    _colorChangeTimer?.cancel();
    super.dispose();
  }

  void _loadSongs() async {
    final songs = await _musicService.getRandomSongs();
    setState(() {
      _songs = songs;
    });
  }

  void _playPreview(String url) {
    _audioPlayer.play(UrlSource(url));
  }

  void _stopPreview() {
    _audioPlayer.stop();
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

  // Cargar "me gusta" desde Firebase
  Future<void> _loadLikedSongs() async {
    final docRef =
        FirebaseFirestore.instance.collection('likes').doc(widget.user.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      final likedSongs =
          List<String>.from(snapshot.data()?['likedSongs'] ?? []);
      setState(() {
        _likedSongs = likedSongs.toSet();
      });
    }
  }

  // Guardar "me gusta" en Firebase
  Future<void> _toggleLike(String songUrl) async {
    final docRef =
        FirebaseFirestore.instance.collection('likes').doc(widget.user.uid);

    setState(() {
      if (_likedSongs.contains(songUrl)) {
        _likedSongs.remove(songUrl);
        docRef.update({
          'likedSongs': FieldValue.arrayRemove([songUrl])
        });
      } else {
        _likedSongs.add(songUrl);
        docRef.set({
          'likedSongs': FieldValue.arrayUnion([songUrl])
        }, SetOptions(merge: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_songs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Music Search')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.user.photoURL != null
                  ? NetworkImage(widget.user.photoURL!)
                  : const AssetImage('assets/default_avatar.png')
                      as ImageProvider,
              radius: 20,
            ),
            const SizedBox(width: 10),
            Text(
              widget.user.displayName ?? 'Usuario',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: PageView.builder(
          itemCount: _songs.length,
          onPageChanged: (index) {
            _stopPreview();
            _playPreview(_songs[index].previewUrl);
          },
          itemBuilder: (context, index) {
            final song = _songs[index];

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.network(song.imageUrl),
                  const SizedBox(height: 20),
                  Text(
                    song.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(song.artist, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),

                  // Botón de "Me gusta"
                  IconButton(
                    icon: Icon(
                      _likedSongs.contains(song.previewUrl)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _likedSongs.contains(song.previewUrl)
                          ? Colors.red
                          : Colors.white,
                    ),
                    onPressed: () => _toggleLike(song.previewUrl),
                    iconSize: 40,
                  ),

                  const SizedBox(height: 20),

                  // Botón de Reproducir
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _playPreview(song.previewUrl),
                    iconSize: 60,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
