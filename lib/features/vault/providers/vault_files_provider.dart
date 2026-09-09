import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/crypto/aes_gcm_helper.dart';
import '../../../core/crypto/session_key_holder.dart';
import '../../../core/database/vault_files_dao.dart';
import '../../notes/providers/notes_auth_provider.dart';
import '../models/vault_file_item.dart';

final vaultFilesDaoProvider = Provider<VaultFilesDao>((ref) {
  return VaultFilesDao();
});

final decryptedVaultFilesProvider =
    StateNotifierProvider<VaultFilesNotifier, AsyncValue<List<VaultFileItem>>>((ref) {
  final dao = ref.watch(vaultFilesDaoProvider);
  final keyHolder = ref.watch(sessionKeyHolderProvider);
  return VaultFilesNotifier(dao, keyHolder);
});

class VaultFilesNotifier extends StateNotifier<AsyncValue<List<VaultFileItem>>> {
  final VaultFilesDao _dao;
  final SessionKeyHolder _keyHolder;

  VaultFilesNotifier(this._dao, this._keyHolder) : super(const AsyncValue.data([]));

  Future<Directory> _getVaultDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(appDocDir.path, 'vault_storage'));
    if (!vaultDir.existsSync()) {
      vaultDir.createSync(recursive: true);
    }
    return vaultDir;
  }

  Future<void> loadDecryptedFiles() async {
    if (!_keyHolder.hasKey) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final key = _keyHolder.derivedKey!;
      final rows = await _dao.getAllVaultFiles();
      final List<VaultFileItem> items = [];

      for (final row in rows) {
        final item = VaultFileItem.fromMap(row);
        String? clearName;
        String? clearMime;
        try {
          clearName = await AesGcmHelper.decrypt(
            packedPayload: item.encryptedFileName,
            derivedKey: key,
          );
          clearMime = await AesGcmHelper.decrypt(
            packedPayload: item.encryptedMimeType,
            derivedKey: key,
          );
        } catch (_) {
          clearName = 'Encrypted File';
          clearMime = 'application/octet-stream';
        }

        items.add(item.copyWith(
          decryptedFileName: clearName,
          decryptedMimeType: clearMime,
        ));
      }

      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> pickAndEncryptFiles() async {
    if (!_keyHolder.hasKey) return;

    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final key = _keyHolder.derivedKey!;
    final vaultDir = await _getVaultDirectory();

    for (final platformFile in result.files) {
      Uint8List? rawBytes = platformFile.bytes;
      if (rawBytes == null && platformFile.path != null) {
        final localFile = File(platformFile.path!);
        if (localFile.existsSync()) {
          rawBytes = localFile.readAsBytesSync();
        }
      }

      if (rawBytes == null || rawBytes.isEmpty) continue;

      final now = DateTime.now();
      final fileId = 'vf_${now.microsecondsSinceEpoch}';
      final fileName = platformFile.name;
      final fileExt = p.extension(fileName).toLowerCase();

      // Encrypt file content with fresh AES-GCM nonce
      final encryptedContentBytes = await AesGcmHelper.encryptBytes(
        clearBytes: rawBytes,
        derivedKey: key,
      );

      // Save encrypted content to sandbox disk
      final relativeFileName = '$fileId.enc';
      final diskFile = File(p.join(vaultDir.path, relativeFileName));
      await diskFile.writeAsBytes(encryptedContentBytes, flush: true);

      // Encrypt file metadata
      final encryptedName = await AesGcmHelper.encrypt(
        plainText: fileName,
        derivedKey: key,
      );
      final mimeGuess = _guessMimeType(fileExt);
      final encryptedMime = await AesGcmHelper.encrypt(
        plainText: mimeGuess,
        derivedKey: key,
      );

      final vaultItem = VaultFileItem(
        id: fileId,
        encryptedFileName: encryptedName,
        encryptedMimeType: encryptedMime,
        relativePath: relativeFileName,
        fileSizeBytes: rawBytes.length,
        ivBase64: base64Encode(encryptedContentBytes.sublist(0, 12)),
        createdAt: now,
        updatedAt: now,
        decryptedFileName: fileName,
        decryptedMimeType: mimeGuess,
      );

      await _dao.insertVaultFile(vaultItem.toMap());
    }

    await loadDecryptedFiles();
  }

  Future<Uint8List> getDecryptedBytes(VaultFileItem item) async {
    if (!_keyHolder.hasKey) {
      throw Exception('Vault is locked.');
    }

    final vaultDir = await _getVaultDirectory();
    final diskFile = File(p.join(vaultDir.path, item.relativePath));

    if (!diskFile.existsSync()) {
      throw Exception('Encrypted file not found on disk.');
    }

    final encryptedBytes = await diskFile.readAsBytes();
    final clearBytes = await AesGcmHelper.decryptBytes(
      packedBytes: encryptedBytes,
      derivedKey: _keyHolder.derivedKey!,
    );

    return clearBytes;
  }

  Future<void> exportAndOpenFile(VaultFileItem item) async {
    final clearBytes = await getDecryptedBytes(item);
    final tempDir = await getTemporaryDirectory();
    final fileName = item.displayName;
    final tempFile = File(p.join(tempDir.path, fileName));
    await tempFile.writeAsBytes(clearBytes, flush: true);

    await OpenFile.open(tempFile.path);
  }

  Future<void> deleteVaultFile(VaultFileItem item) async {
    try {
      final vaultDir = await _getVaultDirectory();
      final diskFile = File(p.join(vaultDir.path, item.relativePath));
      if (diskFile.existsSync()) {
        diskFile.deleteSync();
      }
      await _dao.deleteVaultFile(item.id);

      state.whenData((items) {
        state = AsyncValue.data(items.where((f) => f.id != item.id).toList());
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void purgeMemory() {
    state = const AsyncValue.data([]);
  }

  String _guessMimeType(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.md':
        return 'text/markdown';
      case '.json':
        return 'application/json';
      case '.csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }
}
