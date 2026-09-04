import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';
import '../models/question_bank.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import 'study_questions_screen.dart';

/// Free-text search across all 128 questions.
///
/// Study is four levels deep, so someone who half-remembers a question has no
/// way to reach it without knowing its category. This is that way.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // The user tapped Search: put the keyboard up rather than making them tap
    // the field as well.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final QuestionBank bank = ref.watch(questionBankProvider);
    final ThemeData theme = Theme.of(context);
    final String query = _query.trim();
    final List<Question> results = bank.search(query);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          style: theme.textTheme.titleMedium,
          decoration: InputDecoration(
            hintText: 'Search all ${bank.questions.length} questions',
            border: InputBorder.none,
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear',
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                      _focus.requestFocus();
                    },
                  ),
          ),
          onChanged: (String v) => setState(() => _query = v),
        ),
      ),
      body: SafeArea(
        child: query.isEmpty
            ? _Hint(total: bank.questions.length)
            : results.isEmpty
                ? _NoResults(query: query)
                : ListView.separated(
                    padding: kPagePadding,
                    itemCount: results.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            results.length == 1
                                ? '1 question found'
                                : '${results.length} questions found',
                            style: theme.textTheme.bodyMedium,
                          ),
                        );
                      }
                      return _ResultRow(question: results[index - 1]);
                    },
                  ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StudyDetailScreen(questionId: question.id),
          ),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTapTarget + 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${question.subcategory} · Question ${question.id}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(question.question, style: theme.textTheme.bodyLarge),
                    if (question.correctAnswers.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        question.correctAnswers.first,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 28, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(28),
      children: <Widget>[
        const SizedBox(height: 20),
        Icon(Icons.search, size: 56, color: context.sem.muted),
        const SizedBox(height: 16),
        Text(
          'Type a word or two',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Searches the question, the official answers and the explanation across '
          'all $total questions. Try "Speaker", "1787", or "amendment".',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(28),
      children: <Widget>[
        const SizedBox(height: 20),
        Icon(Icons.search_off, size: 56, color: context.sem.muted),
        const SizedBox(height: 16),
        Text(
          'Nothing matches “$query”',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Try fewer words, or a different one — every word you type has to match.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
