import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../data/remote_config_service.dart';
import 'privacy_policy_screen.dart';
import '../models/question_bank.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/scope_toggle.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _checking = false;

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    final RefreshOutcome outcome =
        await ref.read(remoteConfigProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _checking = false);

    final String message = switch (outcome) {
      RefreshOutcome.updated => 'Answers updated.',
      RefreshOutcome.unchanged => 'Your answers are already up to date.',
      RefreshOutcome.notConfigured =>
        'No update address is set up in this build, so the app uses the answers it came with.',
      RefreshOutcome.unavailable =>
        "Couldn't check right now. The app keeps working with the answers it already has.",
    };
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 5)));
  }

  Future<void> _shareApp() async {
    await Share.share(
      'I'"'"'m studying for the U.S. citizenship civics test with this app. '
      'It'"'"'s free and works offline.',
      subject: 'US Citizenship Test 2025',
    );
  }

  Future<void> _rateApp() async {
    await ref.read(reviewServiceProvider).requestReview();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Thanks for your support!')));
  }

  Future<void> _confirmReset() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Start over?'),
        content: const Text(
          'This clears which questions you have answered. '
          'The questions themselves stay. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start over'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(progressProvider.notifier).reset();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Progress cleared.')));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final QuestionBank bank = ref.watch(questionBankProvider);
    final RemoteConfigState config = ref.watch(remoteConfigProvider);
    final int quizzable = ref.watch(quizzablePoolProvider).length;
    final int studyOnly = ref.watch(studyOnlyCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: kPagePadding,
          children: <Widget>[
            const ScopeToggle(),
            const SizedBox(height: 28),
            _Section(
              title: 'Appearance',
              children: <Widget>[
                _ThemeChoice(
                  mode: ref.watch(themeModeProvider),
                  onChanged: (ThemeMode m) => ref.read(themeModeProvider.notifier).set(m),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _Section(
              title: 'Answers that change',
              children: <Widget>[
                Text(
                  'A few answers — like who is President — change over time. '
                  'The app comes with answers built in and works without the internet.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _checking ? null : _checkForUpdates,
                  icon: _checking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.refresh, size: 26),
                  label: Text(_checking ? 'Checking…' : 'Check for updates'),
                ),
                const SizedBox(height: 14),
                _InfoRow(label: 'Answer set', value: config.config.version),
                _InfoRow(label: 'Last changed', value: config.config.updatedAt),
                _InfoRow(label: 'Source', value: _sourceLabel(config)),
              ],
            ),
            const SizedBox(height: 28),
            _Section(
              title: 'About the questions',
              children: <Widget>[
                Text(
                  'The questions and their answers come from the official USCIS 2025 civics '
                  'test. Answers are shown here word for word. The wrong options in the quiz '
                  'were written for this app and are not official USCIS material.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                _InfoRow(label: 'Question set', value: bank.meta.version),
                _InfoRow(label: 'Questions', value: '${bank.questions.length}'),
                _InfoRow(label: 'In the quiz', value: '$quizzable'),
                if (studyOnly > 0)
                  _InfoRow(label: 'Study only', value: '$studyOnly'),
                const SizedBox(height: 10),
                if (studyOnly > 0)
                  Text(
                    'Study-only questions are the ones whose answer depends on your state. '
                    'You can read them in Study.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(height: 10),
                Text(bank.meta.source, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text(
                  'The real test is spoken, not multiple choice. This app is practice.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
                  ),
                  icon: const Icon(Icons.privacy_tip_outlined, size: 22),
                  label: const Text('Privacy Policy'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _Section(
              title: 'Enjoying the app?',
              children: <Widget>[
                Text(
                  'It'"'"'s free with no ads. A rating or a share with a friend who is '
                  'studying too really helps.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _rateApp,
                  icon: const Icon(Icons.star_rate_rounded, size: 26),
                  label: const Text('Rate us'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _shareApp,
                  icon: const Icon(Icons.ios_share, size: 24),
                  label: const Text('Share the app'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _Section(
              title: 'Your progress',
              children: <Widget>[
                Text(
                  'Everything you do stays on this phone. Nothing is sent anywhere and '
                  'there is no account.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _confirmReset,
                  icon: const Icon(Icons.restart_alt, size: 26),
                  label: const Text('Start over'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _Section(
              title: 'About this app',
              children: <Widget>[
                Text(
                  'US Citizenship Test 2025 is an independent study aid made by Maplewood Apps. '
                  'It is not affiliated with, endorsed by, or associated with the '
                  'U.S. Citizenship and Immigration Services (USCIS) or any other '
                  'government agency.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'The civics questions and official answers are sourced from the public '
                  'USCIS 2025 civics test materials. All other content — including the '
                  'incorrect quiz options — was created for this app.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _sourceLabel(RemoteConfigState state) => switch (state.source) {
        RemoteConfigSource.bundled => 'Built into the app',
        RemoteConfigSource.cached => 'Downloaded earlier',
        RemoteConfigSource.network => 'Just downloaded',
      };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      // Wrap rather than Row: at large text sizes the value moves onto its
      // own line instead of overflowing.
      child: Wrap(
        spacing: 10,
        runSpacing: 2,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// A three-way theme selector: follow the phone, always light, or always dark.
class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const <ButtonSegment<ThemeMode>>[
        ButtonSegment<ThemeMode>(
          value: ThemeMode.system,
          label: Text('System'),
          icon: Icon(Icons.brightness_auto),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          label: Text('Light'),
          icon: Icon(Icons.light_mode),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          label: Text('Dark'),
          icon: Icon(Icons.dark_mode),
        ),
      ],
      selected: <ThemeMode>{mode},
      onSelectionChanged: (Set<ThemeMode> s) => onChanged(s.first),
    );
  }
}
