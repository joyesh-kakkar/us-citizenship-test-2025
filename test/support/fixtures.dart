import 'dart:convert';
import 'dart:io';

import 'package:civics_test_app/config.dart';
import 'package:civics_test_app/models/question.dart';
import 'package:civics_test_app/models/question_bank.dart';
import 'package:civics_test_app/models/remote_config.dart';

/// Reads the real bundled assets straight from disk, so the tests exercise the
/// data the app actually ships rather than a hand-written stand-in.
Future<String> loadAssetFromDisk(String path) => File(path).readAsString();

Future<QuestionBank> loadRealBank() async {
  final String raw = await loadAssetFromDisk(kQuestionsAssetPath);
  return QuestionBank.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Future<RemoteConfig> loadRealRemoteConfig() async {
  final String raw = await loadAssetFromDisk(kRemoteConfigAssetPath);
  return RemoteConfig.tryParse(raw)!;
}

/// A static question with a known shape, for tests that need full control.
Question staticQuestion({
  int id = 1,
  List<String>? correctAnswers,
  List<String>? distractors,
}) =>
    Question(
      id: id,
      category: 'American Government',
      subcategory: 'System of Government',
      question: 'How many U.S. senators are there?',
      type: 'numeric',
      starred: false,
      answerType: AnswerType.staticAnswer,
      correctAnswers: correctAnswers ?? <String>['One hundred (100)'],
      distractors: distractors ??
          <String>['Fifty (50)', 'Four hundred thirty-five (435)', 'Nine (9)'],
      explanation: 'There are 100 senators.',
    );

Question volatileQuestion({int id = 30, String key = 'speaker'}) => Question(
      id: id,
      category: 'American Government',
      subcategory: 'System of Government',
      question: 'What is the name of the Speaker of the House of Representatives now?',
      type: 'volatile',
      starred: true,
      answerType: AnswerType.volatile,
      correctAnswers: const <String>[],
      distractors: const <String>[],
      explanation: 'This answer changes.',
      remoteConfigKey: key,
    );

Question variesByStateQuestion({int id = 62}) => Question(
      id: id,
      category: 'American Government',
      subcategory: 'System of Government',
      question: 'What is the capital of your state?',
      type: 'varies',
      starred: false,
      answerType: AnswerType.variesByState,
      correctAnswers: const <String>[],
      distractors: const <String>[],
      explanation: "Answer with your state's capital.",
      stateField: 'capital',
      distractorStrategy: 'otherStateCapitals',
    );

RemoteConfig configWith({
  String key = 'speaker',
  List<String> correct = const <String>['Mike Johnson'],
  List<String> distractors = const <String>[
    'Nancy Pelosi',
    'Kevin McCarthy',
    'Hakeem Jeffries',
  ],
}) =>
    RemoteConfig(
      version: 'test',
      updatedAt: 'test',
      answers: <String, RemoteAnswerSet>{
        key: RemoteAnswerSet(correct: correct, distractors: distractors),
      },
    );
