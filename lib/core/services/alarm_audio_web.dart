// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

String? _cachedChimeUri;

String _getChimeDataUri() {
  if (_cachedChimeUri != null) return _cachedChimeUri!;

  const sampleRate = 22050;
  const durationSeconds = 0.35;
  const freq = 880.0;
  final numSamples = (sampleRate * durationSeconds).toInt();
  final byteRate = sampleRate * 2;
  final dataSize = numSamples * 2;
  final totalSize = 36 + dataSize;

  final bytes = ByteData(44 + dataSize);
  // RIFF chunk descriptor
  bytes.setUint8(0, 0x52); bytes.setUint8(1, 0x49); bytes.setUint8(2, 0x46); bytes.setUint8(3, 0x46); // 'RIFF'
  bytes.setUint32(4, totalSize, Endian.little);
  bytes.setUint8(8, 0x57); bytes.setUint8(9, 0x41); bytes.setUint8(10, 0x56); bytes.setUint8(11, 0x45); // 'WAVE'
  // fmt sub-chunk
  bytes.setUint8(12, 0x66); bytes.setUint8(13, 0x6D); bytes.setUint8(14, 0x74); bytes.setUint8(15, 0x20); // 'fmt '
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM format
  bytes.setUint16(22, 1, Endian.little); // Mono
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, byteRate, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little); // 16-bit
  // data sub-chunk
  bytes.setUint8(36, 0x64); bytes.setUint8(37, 0x61); bytes.setUint8(38, 0x74); bytes.setUint8(39, 0x61); // 'data'
  bytes.setUint32(40, dataSize, Endian.little);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final decay = math.max(0.0, 1.0 - (t / durationSeconds));
    final sample = (math.sin(2 * math.pi * freq * t) * 32767 * 0.45 * decay).toInt();
    bytes.setInt16(44 + (i * 2), sample, Endian.little);
  }

  _cachedChimeUri = 'data:audio/wav;base64,${base64Encode(bytes.buffer.asUint8List())}';
  return _cachedChimeUri!;
}

/// Plays a synthesized electronic alarm chime in web browsers
void playWebAlarmChime() {
  try {
    final audio = html.AudioElement(_getChimeDataUri());
    audio.play();
  } catch (_) {
    // Gracefully handle browser autoplay blocks
  }
}
