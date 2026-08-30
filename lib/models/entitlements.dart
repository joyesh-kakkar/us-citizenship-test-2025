import 'package:flutter/foundation.dart';

/// What the current user is allowed to access.
///
/// This MVP is entirely free, so [everythingUnlocked] is always true and
/// [canAccess] ignores a test's `premium` flag. It exists as the single choke
/// point a Phase-2 paywall would change — no screen checks entitlements any
/// other way, so gating becomes a one-file change.
@immutable
class Entitlements {
  const Entitlements({required this.everythingUnlocked});

  /// The free-forever MVP default.
  const Entitlements.free() : everythingUnlocked = true;

  final bool everythingUnlocked;

  /// Whether content flagged [premium] is available. Always true for now.
  bool canAccess({required bool premium}) => everythingUnlocked || !premium;
}
