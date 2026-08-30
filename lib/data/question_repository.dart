import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../config.dart';
import '../models/question_bank.dart';

/// Reads a text asset. Injectable so tests can run without a Flutter binding.
typedef AssetLoader = Future<String> Function(String path);

/// Loads the bundled question bank exactly once, at startup.
class QuestionRepository {
  QuestionRepository({AssetLoader? assetLoader})
      : _loadAsset = assetLoader ?? rootBundle.loadString;

  final AssetLoader _loadAsset;

  /// Throws [FormatException] if the bundled JSON is malformed or violates the
  /// bank's own invariants — a build-time problem, never a user-facing one.
  Future<QuestionBank> load() async {
    final String raw = await _loadAsset(kQuestionsAssetPath);
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Question bank is not a JSON object');
    }
    return QuestionBank.fromJson(decoded);
  }
}
