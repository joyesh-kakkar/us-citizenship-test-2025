import 'package:in_app_review/in_app_review.dart';

/// Thin wrapper over the native store-review prompt, so callers never touch the
/// plugin directly and tests can substitute a no-op.
class ReviewService {
  const ReviewService();

  /// Requests the in-app review sheet if the platform offers one. Failures are
  /// swallowed: a review prompt is a nicety, never something that can surface
  /// an error to a nervous user mid-celebration.
  Future<void> requestReview() async {
    try {
      final InAppReview review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } on Object {
      // Ignore: unavailable, throttled by the OS, or running on a plain build.
    }
  }

  /// Opens the store listing — used by the explicit "Rate us" action, which
  /// should always do something visible even when the quiet in-app sheet is
  /// throttled.
  Future<void> openStoreListing() async {
    try {
      await InAppReview.instance.openStoreListing();
    } on Object {
      // Ignore on platforms/builds without a store.
    }
  }
}
