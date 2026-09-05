import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/profile_provider.dart';

class UsernameOnboardingScreen extends StatefulWidget {
  const UsernameOnboardingScreen({super.key});

  @override
  State<UsernameOnboardingScreen> createState() =>
      _UsernameOnboardingScreenState();
}

class _UsernameOnboardingScreenState extends State<UsernameOnboardingScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Consumer<ProfileProvider>(
                    builder: (context, profileProvider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.navyBlue,
                            child: Icon(
                              Icons.school_outlined,
                              color: AppColors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome to Neithra',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose a username to personalize your study space.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              errorText: _localError ?? profileProvider.error,
                            ),
                            onSubmitted: (_) => _submit(profileProvider),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Continue'),
                            onPressed: profileProvider.isLoading
                                ? null
                                : () => _submit(profileProvider),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(ProfileProvider profileProvider) async {
    final username = _controller.text.trim();
    if (username.isEmpty) {
      setState(() => _localError = 'Username cannot be empty.');
      return;
    }
    setState(() => _localError = null);
    await profileProvider.createProfile(username);
  }
}
