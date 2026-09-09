import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Audio notification service for Focus timer and Break alarms.
/// Generates pristine offline chime/alarm sound waves and plays them via audioplayers.
class AudioNotificationService {
  AudioNotificationService._();
  static final AudioNotificationService instance = AudioNotificationService._();

  AudioPlayer? _player;
  Uint8List? _cachedBellBytes;
  Uint8List? _cachedAlarmBytes;

  AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Plays a soothing, resonant Tibetan bell / chime when focus timer completes.
  Future<void> playFocusCompleteChime() async {
    try {
      HapticFeedback.vibrate();
      final wavBytes = _cachedBellBytes ??= _generateBellWav();
      final player = _audioPlayer;
      await player.stop();
      await player.play(BytesSource(wavBytes));
    } catch (e) {
      debugPrint('AudioNotificationService.playFocusCompleteChime: $e');
    }
  }

  /// Plays an alert two-tone alarm when break timer completes.
  Future<void> playBreakCompleteAlarm() async {
    try {
      HapticFeedback.vibrate();
      final wavBytes = _cachedAlarmBytes ??= _generateAlarmWav();
      final player = _audioPlayer;
      await player.stop();
      await player.play(BytesSource(wavBytes));
    } catch (e) {
      debugPrint('AudioNotificationService.playBreakCompleteAlarm: $e');
    }
  }

  /// Disposes the underlying AudioPlayer.
  void dispose() {
    try {
      _player?.dispose();
      _player = null;
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Procedural 16-bit PCM WAV Sound Synthesis
  // ──────────────────────────────────────────────────────────────────────────

  /// Generates a resonant bell chime (A5 880Hz + harmonic overtone 1760Hz with exponential decay).
  static Uint8List _generateBellWav({
    int sampleRate = 44100,
    double durationSeconds = 1.6,
  }) {
    final totalSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = totalSamples * 2; // 16-bit = 2 bytes per sample
    final buffer = ByteData(44 + dataSize);

    _writeWavHeader(buffer, dataSize, sampleRate);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      // Exponential decay envelope
      final envelope = exp(-3.2 * t);
      // Fundamental 880Hz + second harmonic 1760Hz + fifth harmonic 2640Hz
      final wave = 0.65 * sin(2 * pi * 880.0 * t) +
          0.25 * sin(2 * pi * 1760.0 * t) +
          0.10 * sin(2 * pi * 2640.0 * t);
      final sample = (wave * envelope * 28000.0).clamp(-32768.0, 32767.0).toInt();
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// Generates a two-tone alarm chime for break completion.
  static Uint8List _generateAlarmWav({
    int sampleRate = 44100,
    double durationSeconds = 1.0,
  }) {
    final totalSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = totalSamples * 2;
    final buffer = ByteData(44 + dataSize);

    _writeWavHeader(buffer, dataSize, sampleRate);

    final halfSamples = totalSamples ~/ 2;
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final freq = i < halfSamples ? 587.33 : 880.0; // D5 to A5 fanfare
      final envelope = exp(-2.5 * (t % (durationSeconds / 2)));
      final wave = 0.8 * sin(2 * pi * freq * t) + 0.2 * sin(4 * pi * freq * t);
      final sample = (wave * envelope * 27000.0).clamp(-32768.0, 32767.0).toInt();
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  static void _writeWavHeader(ByteData buffer, int dataSize, int sampleRate) {
    // RIFF chunk descriptor
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    buffer.setUint8(8, 0x57);  // 'W'
    buffer.setUint8(9, 0x41);  // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    buffer.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    buffer.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    buffer.setUint32(24, sampleRate, Endian.little); // SampleRate
    buffer.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
    buffer.setUint16(32, 2, Endian.little);  // BlockAlign (NumChannels * BitsPerSample/8)
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample (16 bits)

    // data subchunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);
  }
}
