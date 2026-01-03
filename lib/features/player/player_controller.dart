import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class PlayerController extends GetxController {
  final AudioPlayer _player = AudioPlayer();

  // Observables
  final isPlaying = false.obs;
  final currentTitle = ''.obs;
  final currentArtist = ''.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  final bufferedPosition = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // Listen to player state
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
        _player.seek(Duration.zero);
        _player.pause();
      }
    });

    // Listen to duration
    _player.durationStream.listen((duration) {
      totalDuration.value = duration ?? Duration.zero;
    });

    // Listen to position
    _player.positionStream.listen((position) {
      currentPosition.value = position;
    });

    // Listen to buffered position
    _player.bufferedPositionStream.listen((buffered) {
      bufferedPosition.value = buffered;
    });

    // Load a mock playlist item
    await loadMockTrack();
  }

  // Demo Playlist Data
  final Map<String, Map<String, String>> _moodPlaylists = {
    'Happy': {
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      'title': '晴朗的一天',
      'artist': '欢快节拍',
    },
    'Melancholy': {
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      'title': '雨窗之思',
      'artist': '蓝色心绪',
    },
    'Peaceful': {
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      'title': '海风轻拂',
      'artist': '自然之声',
    },
    'Focused': {
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      'title': '深度工作',
      'artist': 'Lofi 学习',
    },
  };

  Future<void> playMood(String mood) async {
    final track = _moodPlaylists[mood];
    if (track != null) {
      try {
        await _player.setUrl(track['url']!);
        currentTitle.value = track['title']!;
        currentArtist.value = track['artist']!;
        _player.play();
      } catch (e) {
        Get.snackbar("Error", "Could not load track for $mood");
      }
    }
  }

  // Initial load can be empty or a default track
  Future<void> loadMockTrack() async {
    // Optional: load a default track without playing
  }

  void togglePlay() {
    if (isPlaying.value) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
