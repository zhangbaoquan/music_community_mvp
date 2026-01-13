import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/song.dart';

class PlayerController extends GetxController {
  final AudioPlayer _player = AudioPlayer();

  // Observables
  final isPlaying = false.obs;
  final isBuffering = false.obs; // Add buffering state
  final currentMood = ''.obs; // The ID for the current song (e.g. 'Happy')
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
      // Update buffering state
      isBuffering.value =
          state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;

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
      'url':
          'http://qinqinmusic.com/storage/v1/object/public/songs/happy_diyue.mp3',
      'title': '笛月',
      'artist': '董敏 - 笛月',
    },
    'Melancholy': {
      'url':
          'http://qinqinmusic.com/storage/v1/object/public/songs/sad_dayu.mp3',
      'title': '大鱼',
      'artist': '大鱼海棠',
    },
    'Peaceful': {
      'url':
          'http://qinqinmusic.com/storage/v1/object/public/songs/calmness_OldMemory.mp3',
      'title': 'Old Memory',
      'artist': '纯音乐',
    },
    'Focused': {
      'url':
          'http://qinqinmusic.com/storage/v1/object/public/songs/focus_FengJuZhuDeJieDao.mp3',
      'title': '风居住的街道',
      'artist': '矶村由纪子',
    },
  };

  Future<void> playMood(String mood) async {
    final track = _moodPlaylists[mood];
    if (track != null) {
      try {
        await _player.stop(); // Ensure previous track is stopped
        final url = track['url']!;
        print(
          "Attempting to load URL: $url",
        ); // Debug log available in browser console

        await _player.setUrl(url);
        currentMood.value = mood; // Update current mood ID
        currentTitle.value = track['title']!;
        currentArtist.value = track['artist']!;
        _player.play();
      } catch (e) {
        print("Error playing $mood: $e");
        Get.snackbar(
          "播放失败 (Error)",
          "无法加载歌曲: $mood\n$e",
          duration: const Duration(seconds: 5),
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer,
        );
      }
    }
  }

  Future<void> playSong(Song song) async {
    try {
      await _player.stop();
      await _player.setUrl(song.url);

      currentMood.value = song.moodTags?.firstOrNull ?? 'User Upload';
      currentTitle.value = song.title;
      currentArtist.value = song.artist ?? 'Pianist';

      _player.play();
    } catch (e) {
      print("Error playing song ${song.title}: $e");
      Get.snackbar("Error", "无法播放歌曲: ${e.toString()}");
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
