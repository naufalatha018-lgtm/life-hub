import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/wallets_dao.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/wallet.dart';

final walletsDaoProvider = Provider<WalletsDao>((ref) => WalletsDao());

final selectedWalletIdProvider = StateProvider<String?>((ref) => null);

class WalletsNotifier extends StateNotifier<AsyncValue<List<Wallet>>> {
  WalletsNotifier(this._dao, [String? userId])
      : _userId = userId ?? 'guest_default',
        super(const AsyncValue.loading()) {
    loadWallets();
  }

  final WalletsDao _dao;
  final String _userId;

  Future<void> loadWallets() async {
    try {
      final rows = await _dao.getAllWallets(_userId);
      if (rows.isEmpty) {
        // Seed default wallet for this specific user with zero balance
        final now = DateTime.now();
        final defaultWallet = Wallet(
          id: 'wallet_${_userId}_default',
          userId: _userId,
          name: 'Rekening Utama',
          iconCodePoint: 57534,
          colorHex: '#0284C7',
          balanceCents: 0,
          isDefault: true,
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        );
        await _dao.insertWallet(defaultWallet.toMap());
        state = AsyncValue.data([defaultWallet]);
        return;
      }
      state = AsyncValue.data(rows.map((r) => Wallet.fromMap(r)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWallet({
    required String name,
    int iconCodePoint = 57534,
    String colorHex = '#0284C7',
  }) async {
    final now = DateTime.now();
    final wallets = state.value ?? [];
    final wallet = Wallet(
      id: 'wallet_${now.microsecondsSinceEpoch}',
      userId: _userId,
      name: name.trim(),
      iconCodePoint: iconCodePoint,
      colorHex: colorHex,
      balanceCents: 0,
      isDefault: wallets.isEmpty,
      sortOrder: wallets.length,
      createdAt: now,
      updatedAt: now,
    );
    await _dao.insertWallet(wallet.toMap());
    await loadWallets();
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _dao.updateWallet(wallet.copyWith(
      userId: _userId,
      updatedAt: DateTime.now(),
    ).toMap());
    await loadWallets();
  }

  Future<void> deleteWallet(String id) async {
    await _dao.deleteWallet(id, _userId);
    await loadWallets();
  }

  Future<void> setDefault(String id) async {
    await _dao.setDefaultWallet(id, _userId);
    await loadWallets();
  }

  Future<void> refreshBalances() async {
    final wallets = state.value ?? [];
    for (final w in wallets) {
      await _dao.recalculateBalance(w.id, _userId);
    }
    await loadWallets();
  }

  Wallet? get defaultWallet {
    final wallets = state.value ?? [];
    try {
      return wallets.firstWhere((w) => w.isDefault);
    } catch (_) {
      return wallets.isNotEmpty ? wallets.first : null;
    }
  }
}

final walletsNotifierProvider =
    StateNotifierProvider<WalletsNotifier, AsyncValue<List<Wallet>>>((ref) {
  final dao = ref.watch(walletsDaoProvider);
  final userId = ref.watch(currentUserIdProvider);
  return WalletsNotifier(dao, userId);
});

final defaultWalletProvider = Provider<Wallet?>((ref) {
  final walletsAsync = ref.watch(walletsNotifierProvider);
  return walletsAsync.maybeWhen(
    data: (wallets) {
      try {
        return wallets.firstWhere((w) => w.isDefault);
      } catch (_) {
        return wallets.isNotEmpty ? wallets.first : null;
      }
    },
    orElse: () => null,
  );
});
