import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/crypto/aes_gcm_helper.dart';
import '../../../core/crypto/session_key_holder.dart';
import '../../../core/database/notes_dao.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/encrypted_note_record.dart';
import '../models/secure_note.dart';
import 'notes_auth_provider.dart';

final notesDaoProvider = Provider<NotesDao>((ref) {
  return NotesDao();
});

final notesSearchQueryProvider = StateProvider<String>((ref) => '');
final notesSelectedTagProvider = StateProvider<String?>((ref) => null);

final decryptedNotesProvider =
    StateNotifierProvider<DecryptedNotesNotifier, AsyncValue<List<SecureNote>>>((ref) {
  final dao = ref.watch(notesDaoProvider);
  final keyHolder = ref.watch(sessionKeyHolderProvider);
  final userId = ref.watch(currentUserIdProvider);
  return DecryptedNotesNotifier(dao, keyHolder, userId);
});

class DecryptedNotesNotifier extends StateNotifier<AsyncValue<List<SecureNote>>> {
  DecryptedNotesNotifier(this._dao, this._keyHolder, [this._userId])
      : super(const AsyncValue.data([]));

  final NotesDao _dao;
  final SessionKeyHolder _keyHolder;
  final String? _userId;

  Future<void> loadDecryptedNotes() async {
    if (!_keyHolder.hasKey) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final key = _keyHolder.key!;
      final records = await _dao.getAllEncryptedNotes(_userId);
      final List<SecureNote> decryptedList = [];

      for (final row in records) {
        final record = EncryptedNoteRecord.fromMap(row);
        final title = await AesGcmHelper.decrypt(
          packedPayload: record.encryptedTitle,
          derivedKey: key,
        );
        final content = await AesGcmHelper.decrypt(
          packedPayload: record.encryptedContent,
          derivedKey: key,
        );
        final tagsJson = await AesGcmHelper.decrypt(
          packedPayload: record.encryptedTags,
          derivedKey: key,
        );
        List<String> tags = [];
        try {
          final decoded = jsonDecode(tagsJson);
          if (decoded is List) {
            tags = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}

        decryptedList.add(
          SecureNote(
            id: record.id,
            title: title,
            content: content,
            tags: tags,
            isPinned: record.isPinned,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
          ),
        );
      }

      state = AsyncValue.data(decryptedList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNote({
    required String title,
    required String content,
    List<String> tags = const [],
    bool isPinned = false,
  }) async {
    if (!_keyHolder.hasKey) return;
    final key = _keyHolder.key!;
    final now = DateTime.now();

    final encTitle = await AesGcmHelper.encrypt(plainText: title.trim(), derivedKey: key);
    final encContent = await AesGcmHelper.encrypt(plainText: content.trim(), derivedKey: key);
    final encTags = await AesGcmHelper.encrypt(plainText: jsonEncode(tags), derivedKey: key);

    final record = EncryptedNoteRecord(
      id: 'note_${now.microsecondsSinceEpoch}',
      encryptedTitle: encTitle,
      encryptedContent: encContent,
      encryptedTags: encTags,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );

    await _dao.insertNote(record.toMap(), _userId);

    final newNote = SecureNote(
      id: record.id,
      title: title.trim(),
      content: content.trim(),
      tags: tags,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );

    state.whenData((list) {
      final updated = [newNote, ...list];
      updated.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      state = AsyncValue.data(updated);
    });
  }

  Future<void> updateNote(SecureNote note) async {
    if (!_keyHolder.hasKey) return;
    final key = _keyHolder.key!;
    final now = DateTime.now();

    final encTitle = await AesGcmHelper.encrypt(plainText: note.title.trim(), derivedKey: key);
    final encContent = await AesGcmHelper.encrypt(plainText: note.content.trim(), derivedKey: key);
    final encTags = await AesGcmHelper.encrypt(plainText: jsonEncode(note.tags), derivedKey: key);

    final record = EncryptedNoteRecord(
      id: note.id,
      encryptedTitle: encTitle,
      encryptedContent: encContent,
      encryptedTags: encTags,
      isPinned: note.isPinned,
      createdAt: note.createdAt,
      updatedAt: now,
    );

    await _dao.updateNote(record.toMap(), _userId);

    final updatedNote = note.copyWith(updatedAt: now);

    state.whenData((list) {
      final updated = list.map((n) => n.id == note.id ? updatedNote : n).toList();
      updated.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      state = AsyncValue.data(updated);
    });
  }

  Future<void> togglePin(String id) async {
    final currentList = state.value ?? [];
    final note = currentList.firstWhere((n) => n.id == id);
    final newPinned = !note.isPinned;
    final now = DateTime.now();

    await _dao.togglePin(
      id: id,
      isPinned: newPinned,
      updatedAt: now.millisecondsSinceEpoch,
      userId: _userId,
    );

    state.whenData((list) {
      final updated = list.map((n) => n.id == id ? n.copyWith(isPinned: newPinned, updatedAt: now) : n).toList();
      updated.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      state = AsyncValue.data(updated);
    });
  }

  Future<void> deleteNote(String id) async {
    await _dao.deleteNote(id, _userId);
    state.whenData((list) {
      state = AsyncValue.data(list.where((n) => n.id != id).toList());
    });
  }

  /// Purges decrypted notes completely from memory on lock or inactivity timeout.
  void purgeMemory() {
    state = const AsyncValue.data([]);
  }
}

/// Filtered decrypted notes according to search text and tag filter
final filteredNotesProvider = Provider<List<SecureNote>>((ref) {
  final notesAsync = ref.watch(decryptedNotesProvider);
  final query = ref.watch(notesSearchQueryProvider).toLowerCase().trim();
  final selectedTag = ref.watch(notesSelectedTagProvider);

  return notesAsync.maybeWhen(
    data: (notes) {
      return notes.where((note) {
        if (selectedTag != null && !note.tags.contains(selectedTag)) {
          return false;
        }
        if (query.isNotEmpty) {
          final titleMatches = note.title.toLowerCase().contains(query);
          final contentMatches = note.content.toLowerCase().contains(query);
          final tagMatches = note.tags.any((t) => t.toLowerCase().contains(query));
          if (!titleMatches && !contentMatches && !tagMatches) return false;
        }
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

final pinnedNotesProvider = Provider<List<SecureNote>>((ref) {
  return ref.watch(filteredNotesProvider).where((n) => n.isPinned).toList();
});

final unpinnedNotesProvider = Provider<List<SecureNote>>((ref) {
  return ref.watch(filteredNotesProvider).where((n) => !n.isPinned).toList();
});
