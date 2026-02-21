import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _enabled = true;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  static Future<void> playTap() async {
    if (!_enabled) return;
    // Play a short click sound — in production, load from assets
    // For now, we'll use a system-like approach
    try {
      await _player.play(AssetSource('sounds/tap.mp3'), volume: 0.3);
    } catch (_) {
      // Asset not found - graceful degradation
    }
  }

  static Future<void> playError() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/error.mp3'), volume: 0.5);
    } catch (_) {}
  }

  static Future<void> playSuccess() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/success.mp3'), volume: 0.5);
    } catch (_) {}
  }

  static Future<void> playWin() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/win.mp3'), volume: 0.7);
    } catch (_) {}
  }

  static void dispose() {
    _player.dispose();
  }
}
