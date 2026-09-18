import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/view_models/auth_view_model.dart';
import 'features/auth/views/login_screen.dart';
import 'features/chat/view_models/chat_view_model.dart';
import 'features/home/views/main_navigation_screen.dart';
import 'features/lost_found/view_models/lost_found_view_model.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase across platforms
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully for CampusFound.');
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }
  runApp(const CampusFoundApp());
}

class CampusFoundApp extends StatelessWidget {
  const CampusFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => LostFoundViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authVM, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: authVM.isAuthenticated
                ? const MainNavigationScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
