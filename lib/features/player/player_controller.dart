import 'dart:async';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/song.dart';
import '../../data/services/log_service.dart'; // Import LogService

class PlayerController extends GetxController {
  final AudioPlayer _player = AudioPlayer();
  // Ensure LogService is available. Better to put it in initial binding, but find is ok here if already put.
  // Using Get.put to be safe if not initialized elsewhere yet.
  final LogService _logService = Get.put(LogService());

  // Observables
  final isPlaying = false.obs;
  final isBuffering = false.obs;
  final currentMood = ''.obs;
  final currentTitle = ''.obs;
  final currentArtist = ''.obs;
  final currentCoverUrl = ''.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  final bufferedPosition = Duration.zero.obs;
  final volume = 1.0.obs;

  final Rxn<Song> currentSong = Rxn<Song>();

  // Initialization tracking
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get ready => _initCompleter.future;

  @override
  void onInit() {
    super.onInit();
    _logService.uploadLog(content: 'PlayerController _initPlayer');
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // Listen to player state
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      isBuffering.value =
          state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;

      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
        _player.seek(Duration.zero);
        if (_player.playing) {
          _player.pause();
        }
      }
    });

    _player.durationStream.listen((duration) {
      totalDuration.value = duration ?? Duration.zero;
    });

    _player.positionStream.listen((position) {
      currentPosition.value = position;
    });

    _player.bufferedPositionStream.listen((buffered) {
      bufferedPosition.value = buffered;
    });

    _player.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace stackTrace) {
        _logService.uploadLog(content: 'Player Stream Error: $e');
        // Only show snackbar for genuine errors if needed, or keep it silent for now specific to stream errors
      },
    );

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  String? _currentUrl;

  Future<void> playSong(Song song) async {
    try {
      // Stop previous track properly
      if (_player.playing || _player.processingState != ProcessingState.idle) {
        await _player.stop();
      }

      _currentUrl = song.url;

      // Update UI
      currentSong.value = song;
      currentMood.value = song.moodTags?.firstOrNull ?? 'User Upload';
      currentTitle.value = song.title;
      currentArtist.value = song.artist ?? 'Pianist';
      currentCoverUrl.value = song.coverUrl ?? '';

      await _player.setVolume(1.0);

      // Standard Logic: Await Load URL
      await _player.setUrl(song.url);

      // Standard Logic: Attempt Play
      await _player.play();
    } catch (e) {
      _logService.uploadLog(content: "Play Error: $e");
      isPlaying.value = false;

      // Only show user-facing errors for interaction issues
      if (e.toString().contains("interact") ||
          e.toString().contains("Autoplay")) {
        Get.snackbar("提示", "需点击播放按钮开始播放");
      } else {
        Get.snackbar("播放错误", "无法播放音乐");
      }
    }
  }

  Future<void> togglePlay() async {
    try {
      if (isPlaying.value) {
        await _player.pause();
        Get.snackbar("提示", "已暂停");
      } else {
        if (_player.processingState == ProcessingState.idle ||
            _player.processingState == ProcessingState.completed) {
          if (_currentUrl != null) {
            await _player.setUrl(_currentUrl!);
          } else {
            Get.snackbar("错误", "暂无正在播放的歌曲");
            return;
          }
        }
        await _player.play();
      }
    } catch (e) {
      _logService.uploadLog(content: "Toggle Play Error: $e");
      Get.snackbar("播放错误", "操作失败");

      // Basic Emergency Reload
      if (_currentUrl != null) {
        try {
          await _player.stop();
          await _player.setUrl(_currentUrl!);
          await _player.play();
        } catch (e2) {
          _logService.uploadLog(content: "Emergency Reload Failed: $e2");
        }
      }
    }
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  void setVolume(double value) {
    volume.value = value;
    _player.setVolume(value);
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
