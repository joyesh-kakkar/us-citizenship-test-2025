import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/favorites_store.dart';
import '../models/question.dart';
import '../models/question_bank.dart';
import 'providers.dart';

final Provider<FavoritesStore> favoritesStoreProvider = Provider<FavoritesStore>(
  (Ref ref) => FavoritesStore(ref.watch(sharedPreferencesProvider)),
);

/// The set of bookmarked question ids, persisted locally.
class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => ref.watch(favoritesStoreProvider).load();

  Future<void> toggle(int questionId) async {
    final Set<int> next = Set<int>.of(state);
    if (!next.add(questionId)) next.remove(questionId);
    state = next;
    await ref.read(favoritesStoreProvider).save(next);
  }

  Future<void> clear() async {
    state = <int>{};
    await ref.read(favoritesStoreProvider).save(<int>{});
  }
}

final NotifierProvider<FavoritesNotifier, Set<int>> favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<int>>(FavoritesNotifier.new);

/// Whether one question is bookmarked. A family so widgets rebuild narrowly.
final isFavoriteProvider =
    Provider.family<bool, int>((Ref ref, int id) => ref.watch(favoritesProvider).contains(id));

/// The favorited questions, in bank (id) order, for the Favorites screen.
final Provider<List<Question>> favoriteQuestionsProvider = Provider<List<Question>>((Ref ref) {
  final Set<int> ids = ref.watch(favoritesProvider);
  final QuestionBank bank = ref.watch(questionBankProvider);
  return bank.questions.where((Question q) => ids.contains(q.id)).toList(growable: false);
});
