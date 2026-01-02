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

  Future<void> loadMockTrack() async {
    try {
      // Using a reliable test audio from standard sources or public domain
      // This is a sample MP3 from generic testing sources
      await _player.setUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
      currentTitle.value = 'Healing Rain';
      currentArtist.value = 'Nature Sounds';
    } catch (e) {
      print("Error loading audio: $e");
    }
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
