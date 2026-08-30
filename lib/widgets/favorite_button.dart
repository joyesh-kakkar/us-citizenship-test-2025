import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/favorites_providers.dart';
import '../theme/app_theme.dart';

/// A bookmark toggle for any question. Tapping it flips the favorite state and
/// gives a brief confirmation, so the action is unmistakable for a nervous
/// first-time user.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.questionId, this.compact = false});

  final int questionId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isFav = ref.watch(isFavoriteProvider(questionId));
    final AppSemantics sem = context.sem;

    return IconButton(
      iconSize: 28,
      tooltip: isFav ? 'Remove bookmark' : 'Bookmark this question',
      isSelected: isFav,
      onPressed: () async {
        await ref.read(favoritesProvider.notifier).toggle(questionId);
        if (!context.mounted) return;
        final bool nowFav = ref.read(isFavoriteProvider(questionId));
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(nowFav ? 'Saved to Favorites' : 'Removed from Favorites'),
              duration: const Duration(seconds: 2),
            ),
          );
      },
      icon: Icon(
        isFav ? Icons.bookmark : Icons.bookmark_border,
        color: isFav ? sem.accent : null,
        semanticLabel: isFav ? 'Bookmarked' : 'Not bookmarked',
      ),
    );
  }
}
