import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SafeArea(
        child: ListView(
          padding: kPagePadding,
          children: <Widget>[
            Text('Maplewood Apps', style: text.labelSmall?.copyWith(
              color: context.sem.accent,
              letterSpacing: 0.12 * 12,
            )),
            const SizedBox(height: 8),
            Text('Privacy Policy', style: text.headlineMedium),
            const SizedBox(height: 4),
            Text('US Citizenship Test 2025 · Effective August 29, 2026',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 24),

            _SummaryBox(
              child: Text(
                'Short version: this app collects no personal data, connects to no servers, and has no accounts. Everything stays on your device.',
                style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 32),

            _Section(
              title: 'What this app does not collect',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('US Citizenship Test 2025 does not collect, store, transmit, or share any personal information. Specifically:', style: text.bodyLarge),
                  const SizedBox(height: 12),
                  ...<String>[
                    'No name, email address, phone number, or identity information',
                    'No location data',
                    'No device identifiers or advertising IDs',
                    'No analytics or usage statistics',
                    'No crash reports sent to any server',
                    'No contacts, photos, microphone, or camera access',
                  ].map((String s) => _Bullet(text: s)),
                ],
              ),
            ),

            _Section(
              title: 'What stays on your device',
              child: Text(
                'Your study progress, quiz results, practice test scores, bookmarked favorites, and app settings are saved locally using your phone\'s standard storage. This data never leaves your device and is deleted if you uninstall the app.',
                style: text.bodyLarge,
              ),
            ),

            _Section(
              title: 'The one optional network request',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Four civics answers change over time — such as who currently holds elected office. If a future version of this app is configured to check for answer updates, it will make a single HTTPS request to fetch a small JSON file with updated answers. This request contains no user data.',
                    style: text.bodyLarge,
                  ),
                  const SizedBox(height: 10),
                  Text('The current version of the app does not make this request.', style: text.bodyLarge),
                ],
              ),
            ),

            _Section(
              title: 'OS-level features',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Two features invoke operating system surfaces:', style: text.bodyLarge),
                  const SizedBox(height: 12),
                  _Bullet(text: 'Rate this app — triggers the standard OS review prompt. No data passes through our systems.'),
                  _Bullet(text: 'Share this app — opens your phone\'s share sheet. We do not see what you share or with whom.'),
                ],
              ),
            ),

            _Section(
              title: 'Children',
              child: Text(
                'This app is not directed at children under 13 and does not knowingly collect data from anyone.',
                style: text.bodyLarge,
              ),
            ),

            _Section(
              title: 'Changes to this policy',
              child: Text(
                'If we ever add a feature that changes how data is handled, we will update this policy before releasing that version.',
                style: text.bodyLarge,
              ),
            ),

            _Section(
              title: 'Contact',
              child: Text('Questions? Email us at hello@maplewoodapps.com', style: text.bodyLarge),
            ),

            const SizedBox(height: 32),
            Text(
              'US Citizenship Test 2025 is made by Maplewood Apps and is not affiliated with, endorsed by, or associated with the U.S. Citizenship and Immigration Services (USCIS) or any government agency.',
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(left: BorderSide(color: context.sem.accent, width: 4)),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
      ),
      child: child,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Divider(height: 40),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: context.sem.accent.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
