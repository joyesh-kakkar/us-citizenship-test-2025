import 'package:flutter/foundation.dart';

/// How many questions a test run asks and how many must be right to pass.
@immutable
class PassingRule {
  const PassingRule({required this.asked, required this.needToPass});

  final int asked;
  final int needToPass;

  bool passes(int correct) => correct >= needToPass;
}

/// The `meta` block of the question bank. Passing thresholds live here and are
/// never hardcoded elsewhere in the app.
@immutable
class QuizMeta {
  const QuizMeta({
    required this.title,
    required this.source,
    required this.studyGuide,
    required this.version,
    required this.totalQuestions,
    required this.standard,
    required this.special6520,
    required this.special6520Eligibility,
    required this.notes,
  });

  final String title;
  final String source;
  final String studyGuide;
  final String version;
  final int totalQuestions;

  /// The standard test: drawn from all questions.
  final PassingRule standard;

  /// The 65/20 accommodation: drawn from the starred questions.
  final PassingRule special6520;

  final String special6520Eligibility;
  final List<String> notes;

  factory QuizMeta.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> passing =
        (json['passing'] as Map<String, dynamic>?) ??
            (throw const FormatException('meta.passing is missing'));

    PassingRule rule(String key) {
      final Map<String, dynamic>? node = passing[key] as Map<String, dynamic>?;
      if (node == null) {
        throw FormatException('meta.passing.$key is missing');
      }
      // The bank uses "askedUpTo" for the standard test and "asked" for 65/20.
      final Object? asked = node['asked'] ?? node['askedUpTo'];
      final Object? needed = node['needToPass'];
      if (asked is! int || needed is! int) {
        throw FormatException('meta.passing.$key has non-integer thresholds');
      }
      return PassingRule(asked: asked, needToPass: needed);
    }

    return QuizMeta(
      title: json['title'] as String? ?? 'USCIS Civics Test',
      source: json['source'] as String? ?? 'USCIS',
      studyGuide: json['studyGuide'] as String? ?? '',
      version: json['version'] as String? ?? 'unknown',
      totalQuestions: json['totalQuestions'] as int? ??
          (throw const FormatException('meta.totalQuestions is missing')),
      standard: rule('standard'),
      special6520: rule('special6520'),
      special6520Eligibility:
          (passing['special6520'] as Map<String, dynamic>?)?['eligibility'] as String? ?? '',
      notes: <String>[
        ...?(json['notes'] as List<dynamic>?)?.map((dynamic e) => e as String),
      ],
    );
  }
}
