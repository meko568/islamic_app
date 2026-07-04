import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AudioService {
  static const Map<String, String> _reciters = {
    'ar.minshawi': 'Al-Minshawi',
    'ar.alafasy': 'Al-Afasy',
    'ar.husary': 'Al-Husary',
    'ar.abdulbasitmurattal': 'Abdul Basit',
  };

  static final AudioPlayer _player = AudioPlayer();
  static String _currentReciter = 'ar.minshawi';
  static List<String>? _currentAudioUrls;
  static int _currentAyahIndex = 0;
  static bool _isPlayingSurah = false;

  // Get available reciters
  static Map<String, String> getReciters() {
    return _reciters;
  }

  // Set current reciter
  static void setReciter(String reciterKey) {
    _currentReciter = reciterKey;
  }

  // Get current reciter
  static String getCurrentReciter() {
    return _currentReciter;
  }

  // Fetch audio URLs for a surah
  static Future<List<String>> fetchAudioUrls(int surahNumber) async {
    final response = await http.get(
      Uri.parse(
        'https://api.alquran.cloud/v1/surah/$surahNumber/$_currentReciter',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final ayahs = data['data']['ayahs'] as List;
      return ayahs.map((ayah) => ayah['audio'] as String).toList();
    } else {
      throw Exception('Failed to load audio URLs');
    }
  }

  // Play single ayah
  static Future<void> playAyah(String audioUrl) async {
    try {
      _isPlayingSurah = false;
      await _player.setUrl(audioUrl);
      await _player.play();
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  // Play full surah
  static Future<void> playSurah(
    List<String> audioUrls, {
    int startAyah = 0,
  }) async {
    try {
      _currentAudioUrls = audioUrls;
      _currentAyahIndex = startAyah;
      _isPlayingSurah = true;

      await _player.setUrl(audioUrls[startAyah]);
      await _player.play();

      // Listen for completion to play next ayah
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed &&
            _isPlayingSurah) {
          _playNextAyah();
        }
      });
    } catch (e) {
      throw Exception('Failed to play surah: $e');
    }
  }

  // Play next ayah in surah
  static void _playNextAyah() {
    if (_currentAudioUrls != null &&
        _currentAyahIndex < _currentAudioUrls!.length - 1) {
      _currentAyahIndex++;
      _player.setUrl(_currentAudioUrls![_currentAyahIndex]);
      _player.play();
    } else {
      _isPlayingSurah = false;
    }
  }

  // Pause playback
  static Future<void> pause() async {
    await _player.pause();
  }

  // Resume playback
  static Future<void> resume() async {
    await _player.play();
  }

  // Stop playback
  static Future<void> stop() async {
    _isPlayingSurah = false;
    await _player.stop();
  }

  // Seek to specific position
  static Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // Get player stream for UI updates
  static Stream<Duration> get positionStream => _player.positionStream;

  // Get duration stream
  static Stream<Duration?> get durationStream => _player.durationStream;

  // Get player state stream
  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // Check if currently playing
  static bool get isPlaying => _player.playing;

  // Get current position
  static Duration get position => _player.position;

  // Get current duration
  static Duration? get duration => _player.duration;

  // Dispose player
  static void dispose() {
    _player.dispose();
  }
}
