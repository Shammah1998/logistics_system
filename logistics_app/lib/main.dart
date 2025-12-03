import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistics_app/core/config/app_config.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/presentation/routes/app_router.dart';
import 'package:logistics_app/presentation/pages/login/login_page.dart';
import 'package:logistics_app/presentation/pages/home/home_page.dart';
import 'package:logistics_app/presentation/providers/auth_provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🌐 API Base URL: ${AppConfig.apiBaseUrl}');

  runApp(
    const ProviderScope(
      child: LogisticsApp(),
    ),
  );
}

class LogisticsApp extends ConsumerWidget {
  const LogisticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Test Driver',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: authState.isAuthenticated ? const HomePage() : const LoginPage(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
