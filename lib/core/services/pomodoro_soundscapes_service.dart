import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Soundscape types
// ─────────────────────────────────────────────────────────────────────────────

enum SoundscapeType {
  alpha40Hz('Alpha 40Hz', 'Binaural focus induction at 40 Hz gamma/alpha crossover'),
  brownNoise('Brown Noise', 'Low-frequency masking noise for deep concentration'),
  rain('Rain', 'Synthetic rainfall ambience for calm focus');

  final String label;
  final String description;
  const SoundscapeType(this.label, this.description);
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class SoundscapeState {
  final SoundscapeType? active;
  final bool isPlaying;
  final double volume; // 0.0 – 1.0

  const SoundscapeState({
    this.active,
    this.isPlaying = false,
    this.volume = 0.7,
  });

  SoundscapeState copyWith({
    SoundscapeType? active,
    bool? isPlaying,
    double? volume,
  }) {
    return SoundscapeState(
      active: active ?? this.active,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service / Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Ambient focus audio engine.
///
/// Generates PCM waveforms offline for three soundscapes:
///   - Alpha 40Hz: 40 Hz isochronic tone modulated over a 220 Hz carrier
///   - Brown Noise: random-walk (1/f²) noise tinted to the brown spectrum
///   - Rain: randomised droplet density Gaussian noise + low-pass emphasis
///
/// All audio is synthesised on-device (no network required) and streamed via
/// `audioplayers` BytesSource with looping enabled.
class PomodoroSoundscapesNotifier extends StateNotifier<SoundscapeState> {
  PomodoroSoundscapesNotifier() : super(const SoundscapeState());

  final AudioPlayer _player = AudioPlayer();
  final Map<SoundscapeType, Uint8List> _cache = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> play(SoundscapeType type) async {
    if (state.isPlaying && state.active == type) return;

    await _player.stop();

    final wavBytes = _cache[type] ?? _generate(type);
    _cache[type] = wavBytes;

    await _player.setVolume(state.volume);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(BytesSource(wavBytes));

    state = state.copyWith(active: type, isPlaying: true);
  }

  Future<void> pause() async {
    await _player.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> resume() async {
    if (!state.isPlaying && state.active != null) {
      await _player.resume();
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = const SoundscapeState();
  }

  Future<void> setVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    await _player.setVolume(v);
    state = state.copyWith(volume: v);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ── Waveform Generators ────────────────────────────────────────────────────

  Uint8List _generate(SoundscapeType type) {
    switch (type) {
      case SoundscapeType.alpha40Hz:
        return _generateAlpha40Hz();
      case SoundscapeType.brownNoise:
        return _generateBrownNoise();
      case SoundscapeType.rain:
        return _generateRain();
    }
  }

  /// 40 Hz isochronic tone — 220 Hz carrier amplitude-modulated at 40 Hz.
  /// Sample rate: 44100 Hz, mono 16-bit PCM, 3 seconds loopable.
  Uint8List _generateAlpha40Hz() {
    const sampleRate = 44100;
    const durationSeconds = 3;
    const carrier = 220.0; // Hz
    const modFreq = 40.0; // Hz
    const totalSamples = sampleRate * durationSeconds;

    final samples = Int16List(totalSamples);
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final envelope = (0.5 + 0.5 * math.sin(2.0 * math.pi * modFreq * t));
      final wave = math.sin(2.0 * math.pi * carrier * t);
      samples[i] = (envelope * wave * 28000).round().clamp(-32768, 32767);
    }
    return _buildWav(samples, sampleRate);
  }

  /// Brown noise — random walk in the time domain (1/f² spectrum).
  Uint8List _generateBrownNoise() {
    const sampleRate = 44100;
    const durationSeconds = 4;
    const totalSamples = sampleRate * durationSeconds;

    final rng = math.Random(42);
    final samples = Int16List(totalSamples);
    double accumulator = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final white = (rng.nextDouble() * 2.0) - 1.0;
      accumulator = (accumulator + (0.02 * white)).clamp(-1.0, 1.0);
      samples[i] = (accumulator * 32000).round().clamp(-32768, 32767);
    }
    return _buildWav(samples, sampleRate);
  }

  /// Rain — layered Gaussian noise with a soft low-pass roll-off simulation.
  Uint8List _generateRain() {
    const sampleRate = 44100;
    const durationSeconds = 4;
    const totalSamples = sampleRate * durationSeconds;

    final rng = math.Random(99);
    final samples = Int16List(totalSamples);
    // Simple one-pole IIR low-pass: y[n] = α·x[n] + (1−α)·y[n-1]
    const alpha = 0.25;
    double prev = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      // Multiple white noise layers at different gains for rain density texture
      final base = (rng.nextDouble() * 2.0) - 1.0;
      final sparse = rng.nextDouble() < 0.3 ? (rng.nextDouble() * 2.0 - 1.0) * 0.5 : 0.0;
      final raw = base * 0.7 + sparse;
      final filtered = alpha * raw + (1 - alpha) * prev;
      prev = filtered;
      samples[i] = (filtered * 26000).round().clamp(-32768, 32767);
    }
    return _buildWav(samples, sampleRate);
  }

  // ── WAV Serializer ─────────────────────────────────────────────────────────

  Uint8List _buildWav(Int16List samples, int sampleRate) {
    final numSamples = samples.length;
    final dataSize = numSamples * 2; // 16-bit = 2 bytes/sample
    final totalSize = 44 + dataSize;
    final bytes = Uint8List(totalSize);
    final data = ByteData.view(bytes.buffer);

    // RIFF header
    bytes.setRange(0, 4, [0x52, 0x49, 0x46, 0x46]); // 'RIFF'
    data.setUint32(4, 36 + dataSize, Endian.little);
    bytes.setRange(8, 12, [0x57, 0x41, 0x56, 0x45]); // 'WAVE'
    bytes.setRange(12, 16, [0x66, 0x6D, 0x74, 0x20]); // 'fmt '
    data.setUint32(16, 16, Endian.little); // chunk size
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    data.setUint16(32, 2, Endian.little); // block align
    data.setUint16(34, 16, Endian.little); // bits per sample
    bytes.setRange(36, 40, [0x64, 0x61, 0x74, 0x61]); // 'data'
    data.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      data.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return bytes;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final pomodoroSoundscapesProvider =
    StateNotifierProvider<PomodoroSoundscapesNotifier, SoundscapeState>(
  (ref) => PomodoroSoundscapesNotifier(),
);
