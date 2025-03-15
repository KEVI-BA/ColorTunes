import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  final AudioPlayer _audioPlayer = AudioPlayer();

  factory AudioPlayerService() {
    return _instance;
  }

  AudioPlayerService._internal();

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> play(String url) async {
    await _audioPlayer.play(UrlSource(url));
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;
  Stream<PlayerState> get onPlayerStateChanged =>
      _audioPlayer.onPlayerStateChanged;
}
