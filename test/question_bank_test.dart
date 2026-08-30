import 'dart:convert';

import 'package:civics_test_app/data/question_repository.dart';
import 'package:civics_test_app/models/question.dart';
import 'package:civics_test_app/models/question_bank.dart';
import 'package:civics_test_app/models/scope.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  group('the bundled question bank', () {
    late QuestionBank bank;

    setUp(() async {
      bank = await QuestionRepository(assetLoader: loadAssetFromDisk).load();
    });

    test('contains exactly 128 questions with ids 1 to 128', () {
      expect(bank.questions, hasLength(128));
      expect(
        bank.questions.map((Question q) => q.id).toSet(),
        <int>{for (int i = 1; i <= 128; i++) i},
      );
    });

    test('marks exactly 20 questions as starred', () {
      expect(bank.starredQuestions, hasLength(20));
    });

    test('has 4 volatile and 4 variesByState questions', () {
      List<int> idsOf(AnswerType type) => bank.questions
          .where((Question q) => q.answerType == type)
          .map((Question q) => q.id)
          .toList()
        ..sort();

      expect(idsOf(AnswerType.volatile), <int>[30, 38, 39, 57]);
      expect(idsOf(AnswerType.variesByState), <int>[23, 29, 61, 62]);
      expect(idsOf(AnswerType.staticAnswer), hasLength(120));
    });

    test('gives every volatile question a remote config key', () {
      for (final Question q in bank.questions) {
        if (q.answerType == AnswerType.volatile) {
          expect(q.remoteConfigKey, isNotNull, reason: 'question ${q.id}');
        } else {
          expect(q.remoteConfigKey, isNull, reason: 'question ${q.id}');
        }
      }
    });

    test('gives every variesByState question a state field', () {
      for (final Question q in bank.questions) {
        expect(
          q.stateField != null,
          q.answerType == AnswerType.variesByState,
          reason: 'question ${q.id}',
        );
      }
    });

    test('reads the passing thresholds from meta rather than code', () {
      expect(bank.meta.standard.asked, 20);
      expect(bank.meta.standard.needToPass, 12);
      expect(bank.meta.special6520.asked, 10);
      expect(bank.meta.special6520.needToPass, 6);
      expect(bank.meta.totalQuestions, 128);
      expect(bank.meta.version, '2025');
    });

    test('gives every static question enough distinct distractors', () {
      for (final Question q in bank.questions) {
        if (q.answerType != AnswerType.staticAnswer) continue;
        expect(q.correctAnswers, isNotEmpty, reason: 'question ${q.id}');
        expect(
          q.distractors.map((String d) => d.toLowerCase()).toSet().length,
          greaterThanOrEqualTo(3),
          reason: 'question ${q.id} cannot fill four options',
        );
      }
    });

    test('never lists a correct answer as a distractor', () {
      for (final Question q in bank.questions) {
        final Set<String> correct =
            q.correctAnswers.map((String a) => a.toLowerCase()).toSet();
        final Set<String> wrong =
            q.distractors.map((String d) => d.toLowerCase()).toSet();
        expect(correct.intersection(wrong), isEmpty, reason: 'question ${q.id}');
      }
    });

    test('gives every question an explanation', () {
      for (final Question q in bank.questions) {
        expect(q.explanation.trim(), isNotEmpty, reason: 'question ${q.id}');
      }
    });

    test('groups every question under a category and subcategory', () {
      int counted = 0;
      for (final String category in bank.categories) {
        for (final String subcategory in bank.subcategoriesOf(category)) {
          counted += bank.questionsIn(category, subcategory).length;
        }
      }
      expect(counted, bank.questions.length);
      expect(bank.categories, hasLength(3));
    });

    test('scopes resolve to the right pools', () {
      expect(bank.inScope(StudyScope.all), hasLength(128));
      expect(bank.inScope(StudyScope.starred), hasLength(20));
    });

    test('looks questions up by id', () {
      expect(bank.byId(21)!.question, contains('senators'));
      expect(bank.byId(999), isNull);
      expect(bank.byIds(<int>[1, 999, 2]), hasLength(2));
    });

    test('exposes unmodifiable answer lists', () {
      final Question q = bank.byId(1)!;
      expect(() => q.correctAnswers.add('nope'), throwsUnsupportedError);
      expect(() => q.distractors.add('nope'), throwsUnsupportedError);
    });
  });

  group('validation', () {
    Map<String, dynamic> minimalBank({int count = 2, int starred = 1}) =>
        <String, dynamic>{
          'meta': <String, dynamic>{
            'title': 'Test',
            'version': '2025',
            'totalQuestions': count,
            'passing': <String, dynamic>{
              'standard': <String, dynamic>{'askedUpTo': 2, 'needToPass': 1},
              'special6520': <String, dynamic>{'asked': 1, 'needToPass': 1},
            },
          },
          'questions': <dynamic>[
            for (int i = 1; i <= count; i++)
              <String, dynamic>{
                'id': i,
                'category': 'C',
                'subcategory': 'S',
                'question': 'Q$i',
                'type': 'concept',
                'starred': i <= starred,
                'answerType': 'static',
                'correctAnswers': <String>['A'],
                'distractors': <String>['B', 'C', 'D'],
                'explanation': 'E',
              },
          ],
        };

    test('rejects a bank whose count disagrees with meta', () {
      final Map<String, dynamic> json = minimalBank(count: 2);
      (json['questions'] as List<dynamic>).removeLast();
      expect(() => QuestionBank.fromJson(json), throwsFormatException);
    });

    test('rejects duplicate ids', () {
      final Map<String, dynamic> json = minimalBank(count: 2);
      (json['questions'] as List<dynamic>)[1]['id'] = 1;
      expect(() => QuestionBank.fromJson(json), throwsFormatException);
    });

    test('rejects too few starred questions for a 65/20 run', () {
      final Map<String, dynamic> json = minimalBank(count: 2, starred: 0);
      expect(() => QuestionBank.fromJson(json), throwsFormatException);
    });

    test('rejects an unknown answerType', () {
      final Map<String, dynamic> json = minimalBank();
      (json['questions'] as List<dynamic>)[0]['answerType'] = 'someNewKind';
      expect(() => QuestionBank.fromJson(json), throwsFormatException);
    });

    test('rejects a missing meta block', () {
      expect(
        () => QuestionBank.fromJson(<String, dynamic>{'questions': <dynamic>[]}),
        throwsFormatException,
      );
    });

    test('rejects a question with a missing field', () {
      final Map<String, dynamic> json = minimalBank();
      (json['questions'] as List<dynamic>)[0].remove('explanation');
      expect(() => QuestionBank.fromJson(json), throwsFormatException);
    });

    test('accepts a well-formed minimal bank', () {
      expect(QuestionBank.fromJson(minimalBank()).questions, hasLength(2));
    });

    test('rejects a bank that is not a JSON object', () async {
      final QuestionRepository repo =
          QuestionRepository(assetLoader: (String _) async => jsonEncode(<int>[1, 2]));
      expect(repo.load(), throwsFormatException);
    });
  });
}
