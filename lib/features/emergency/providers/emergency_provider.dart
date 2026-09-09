import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/emergency_dao.dart';
import '../models/emergency_card.dart';

final emergencyDaoProvider = Provider<EmergencyDao>((ref) => EmergencyDao());

class EmergencyCardNotifier extends StateNotifier<AsyncValue<EmergencyCard?>> {
  EmergencyCardNotifier(this._dao) : super(const AsyncValue.loading()) {
    loadCard();
  }

  final EmergencyDao _dao;

  Future<void> loadCard() async {
    try {
      final row = await _dao.getCard();
      state = AsyncValue.data(row != null ? EmergencyCard.fromMap(row) : null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveCard(EmergencyCard card) async {
    try {
      await _dao.upsertCard(card.toMap());
      state = AsyncValue.data(card);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearCard() async {
    await _dao.clearCard();
    state = const AsyncValue.data(null);
  }
}

final emergencyCardProvider =
    StateNotifierProvider<EmergencyCardNotifier, AsyncValue<EmergencyCard?>>((ref) {
  return EmergencyCardNotifier(ref.watch(emergencyDaoProvider));
});
