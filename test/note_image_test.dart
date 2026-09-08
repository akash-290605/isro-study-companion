import 'package:flutter_test/flutter_test.dart';
import 'package:isro_study_companion/data/models/note_model.dart';
import 'package:isro_study_companion/core/services/alarm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NoteModel Image Serialization Tests', () {
    test('NoteModel serializes and deserializes imageBase64 and imageName correctly', () {
      final now = DateTime.now();
      final note = NoteModel(
        noteId: 'note-101',
        userId: 'user-abc',
        title: 'Two-Port Network Parameter Matrix',
        content: r'Z-parameters: $$V_1 = z_{11}I_1 + z_{12}I_2$$',
        subject: 'Network Theory',
        topic: 'Two-Port Networks',
        tags: ['z-parameters', 'circuit'],
        imageBase64: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        imageName: 'two_port_z_matrix.png',
        createdAt: now,
        updatedAt: now,
      );

      final json = note.toJson();
      expect(json['imageBase64'], equals(note.imageBase64));
      expect(json['imageName'], equals('two_port_z_matrix.png'));

      final restored = NoteModel.fromJson(json);
      expect(restored.noteId, equals('note-101'));
      expect(restored.imageBase64, equals(note.imageBase64));
      expect(restored.imageName, equals('two_port_z_matrix.png'));
    });

    test('NoteModel copyWith preserves and updates image fields', () {
      final now = DateTime.now();
      final note = NoteModel(
        noteId: 'note-102',
        userId: 'user-xyz',
        title: 'Op-Amp Inverting Configuration',
        content: 'Gain = -Rf / R1',
        createdAt: now,
        updatedAt: now,
      );

      expect(note.imageBase64, isNull);
      expect(note.imageName, isNull);

      final updated = note.copyWith(
        imageBase64: 'dummy_base64_data',
        imageName: 'opamp_schematic.jpg',
      );

      expect(updated.imageBase64, equals('dummy_base64_data'));
      expect(updated.imageName, equals('opamp_schematic.jpg'));
      expect(updated.title, equals('Op-Amp Inverting Configuration'));
    });
  });

  group('AlarmService Logic Tests', () {
    test('AlarmService starts and stops correctly', () {
      final service = AlarmService();
      expect(service.isRinging, isFalse);
      expect(service.soundEnabled, isTrue);

      service.startAlarm();
      expect(service.isRinging, isTrue);

      service.stopAlarm();
      expect(service.isRinging, isFalse);

      service.toggleSound(false);
      expect(service.soundEnabled, isFalse);

      service.dispose();
    });
  });
}

