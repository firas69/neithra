import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/session_provider.dart';
import '../providers/test_library_provider.dart';
import 'app_shell.dart';
import 'username_onboarding_screen.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadAppState();
  }

  Future<void> _loadAppState() async {
    await Future.wait([
      context.read<ProfileProvider>().loadProfile(),
      context.read<TestLibraryProvider>().loadTests(),
      context.read<HistoryProvider>().loadHistory(),
      context.read<SessionProvider>().loadSavedSessions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            if (!profileProvider.hasProfile) {
              return const UsernameOnboardingScreen();
            }
            return const AppShell();
          },
        );
      },
    );
  }
}
