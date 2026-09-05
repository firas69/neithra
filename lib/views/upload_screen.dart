import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/session_snapshot_model.dart';
import '../models/test_model.dart';
import '../providers/session_provider.dart';
import '../providers/test_provider.dart';
import '../services/json_parser_service.dart';
import '../widgets/custom_button.dart';
import 'practice_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _jsonController = TextEditingController();
  bool _showJsonInput = false;
  TestMode _selectedMode = TestMode.practice;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final testProvider = context.read<TestProvider>();
    final sessionProvider = context.read<SessionProvider>();

    if (await testProvider.hasSavedTest()) {
      await testProvider.loadSavedTest();
      if (testProvider.currentTest != null) {
        _selectedMode = testProvider.currentTest!.defaultMode;
      }
    }
    await sessionProvider.loadSavedSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Neithra Practice')),
      body: Consumer2<TestProvider, SessionProvider>(
        builder: (context, testProvider, sessionProvider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildMainColumn(testProvider)),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 360,
                                child: _buildSavedSessions(sessionProvider),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildMainColumn(testProvider),
                              const SizedBox(height: 16),
                              _buildSavedSessions(sessionProvider),
                            ],
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMainColumn(TestProvider testProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        if (testProvider.hasTest)
          _buildCurrentTest(testProvider)
        else
          _buildUploadOptions(testProvider),
        if (_showJsonInput) ...[
          const SizedBox(height: 16),
          _buildJsonInput(testProvider),
        ],
        const SizedBox(height: 16),
        _buildSampleCard(testProvider),
        if (testProvider.error != null) ...[
          const SizedBox(height: 16),
          _buildErrorCard(testProvider.error!),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return _Panel(
      child: Row(
        children: [
          const Icon(
            Icons.school_outlined,
            color: AppColors.darkGold,
            size: 42,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate. Practice. Review. Improve.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Load a structured test, resume saved work, or focus on weak areas after review.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTest(TestProvider testProvider) {
    final test = testProvider.currentTest!;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  test.title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(test.description),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: '${test.questionCount} questions'),
              _InfoChip(
                label: _formatDuration(test.effectiveEstimatedDuration),
              ),
              _InfoChip(label: test.difficulty.name),
              if (test.topic.isNotEmpty) _InfoChip(label: test.topic),
            ],
          ),
          const SizedBox(height: 18),
          SegmentedButton<TestMode>(
            segments: const [
              ButtonSegment(value: TestMode.practice, label: Text('Practice')),
              ButtonSegment(value: TestMode.exam, label: Text('Exam')),
            ],
            selected: {
              _selectedMode == TestMode.weaknessPractice
                  ? TestMode.practice
                  : _selectedMode,
            },
            onSelectionChanged: (selection) {
              setState(() => _selectedMode = selection.first);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Start',
                  icon: Icons.play_arrow,
                  onPressed: () => _startPractice(_selectedMode),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Replace',
                  backgroundColor: AppColors.silver,
                  textColor: AppColors.darkGray,
                  icon: Icons.refresh,
                  onPressed: testProvider.clearTest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOptions(TestProvider testProvider) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Load Test Data',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Upload JSON File',
            icon: Icons.upload_file,
            onPressed: () => _pickJsonFile(testProvider),
            isLoading: testProvider.isLoading,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Paste JSON Content',
            icon: Icons.content_paste,
            backgroundColor: AppColors.lightNavy,
            onPressed: () => setState(() => _showJsonInput = !_showJsonInput),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonInput(TestProvider testProvider) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paste JSON', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          TextFormField(
            controller: _jsonController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Paste a test JSON object...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Load',
                  onPressed: () => _loadJsonFromText(testProvider),
                  isLoading: testProvider.isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  backgroundColor: AppColors.silver,
                  textColor: AppColors.darkGray,
                  onPressed: () => setState(() => _showJsonInput = false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedSessions(SessionProvider sessionProvider) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'In Progress',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 20),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: sessionProvider.loadSavedSessions,
              ),
            ],
          ),
          if (sessionProvider.savedSessions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('No saved sessions yet.'),
            )
          else
            ...sessionProvider.savedSessions.map(_buildSavedSessionTile),
        ],
      ),
    );
  }

  Widget _buildSavedSessionTile(SessionSummary session) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightSilver),
        ),
        child: ListTile(
          title: Text(session.testTitle),
          subtitle: Text(
            '${session.answeredQuestions}/${session.totalQuestions} answered - '
            '${_formatDuration(session.elapsedTime)}',
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'Resume',
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _resumeSession(session.id),
              ),
              IconButton(
                tooltip: 'Discard',
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    context.read<SessionProvider>().discardSession(session.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSampleCard(TestProvider testProvider) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, color: AppColors.darkGold),
              const SizedBox(width: 8),
              Text(
                'Sample Assessment',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.darkGold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Includes single, multiple, true/false, matching, ordering, numerical, scenario, and code questions.',
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Load Sample',
            backgroundColor: AppColors.darkGold,
            icon: Icons.science,
            onPressed: () => _loadSampleData(testProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return _Panel(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(error, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickJsonFile(TestProvider testProvider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await testProvider.loadTestFromJson(await file.readAsString());
        if (testProvider.currentTest != null) {
          setState(() => _selectedMode = testProvider.currentTest!.defaultMode);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error reading file: $e');
    }
  }

  Future<void> _loadJsonFromText(TestProvider testProvider) async {
    if (_jsonController.text.trim().isEmpty) {
      _showErrorSnackBar('Please paste JSON content first');
      return;
    }

    await testProvider.loadTestFromJson(_jsonController.text);
    if (testProvider.hasTest) {
      _jsonController.clear();
      setState(() {
        _showJsonInput = false;
        _selectedMode = testProvider.currentTest!.defaultMode;
      });
    }
  }

  Future<void> _loadSampleData(TestProvider testProvider) async {
    await testProvider.loadTestFromJson(JsonParserService.getSampleJson());
    if (testProvider.currentTest != null) {
      setState(() => _selectedMode = testProvider.currentTest!.defaultMode);
    }
  }

  Future<void> _startPractice(TestMode mode) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PracticeScreen(mode: mode)),
    );
    if (!mounted) return;
    await context.read<SessionProvider>().loadSavedSessions();
  }

  Future<void> _resumeSession(String sessionId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeScreen(resumeSessionId: sessionId),
      ),
    );
    if (!mounted) return;
    await context.read<SessionProvider>().loadSavedSessions();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightSilver),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.lightGray,
      side: const BorderSide(color: AppColors.lightSilver),
    );
  }
}
