import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/question_repository.dart';
import 'data/remote_config_service.dart';
import 'models/question_bank.dart';
import 'state/providers.dart';

/// Startup does only local work: read preferences, parse the bundled question
/// bank, and resolve the locally available answer config (cached, else
/// bundled). All of it is fast and none of it can fail for lack of a network,
/// so the first screen the user sees is the real one — never a spinner and
/// never an error.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final QuestionBank bank = await QuestionRepository().load();
  final RemoteConfigState remoteConfig =
      await RemoteConfigService(prefs: prefs).loadLocal();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        questionBankProvider.overrideWithValue(bank),
        initialRemoteConfigProvider.overrideWithValue(remoteConfig),
      ],
      child: const CivicsTestApp(),
    ),
  );
}
