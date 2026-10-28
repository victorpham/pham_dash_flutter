import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads a word aloud with the device's text-to-speech engine, for the picture
/// book's flashcards.
///
/// Slow and slightly high on purpose: the listener is a toddler learning the
/// word, not an adult skimming. The engine is created on first use, so a test
/// that overrides [speakerProvider] with a subclass never touches the plugin.
class Speaker {
  Speaker();

  FlutterTts? _tts;

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;

    final tts = FlutterTts();
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.4);
    await tts.setPitch(1.1);
    _tts = tts;
    return tts;
  }

  /// Interrupts whatever is still being said: a toddler tapping twice wants
  /// to hear the word again, not twice in a row.
  Future<void> speak(String text) async {
    final tts = await _engine();
    await tts.stop();
    await tts.speak(text);
  }

  Future<void> stop() async => _tts?.stop();
}

final speakerProvider = Provider<Speaker>((ref) {
  final speaker = Speaker();
  ref.onDispose(speaker.stop);
  return speaker;
});
