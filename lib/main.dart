import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'providers/test_provider.dart';
import 'providers/session_provider.dart';
import 'providers/result_provider.dart';
import 'views/upload_screen.dart';
import 'services/database/sqlite_service.dart';

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
      ],
      child: MaterialApp(
        title: 'Neithra Practice',
        theme: AppTheme.theme,
        home: const UploadScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
