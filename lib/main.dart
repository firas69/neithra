import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'providers/history_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/result_provider.dart';
import 'providers/session_provider.dart';
import 'providers/test_library_provider.dart';
import 'providers/test_provider.dart';
import 'services/database/sqlite_service.dart';
import 'views/app_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SqliteService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TestProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => ResultProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => TestLibraryProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: 'Neithra',
        theme: AppTheme.theme,
        home: const AppBootstrap(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
