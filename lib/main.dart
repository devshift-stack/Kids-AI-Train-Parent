import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/theme/parent_theme.dart';
import 'services/notification_service.dart';
import 'providers/pin_provider.dart';
import 'providers/onboarding_provider.dart';
import 'screens/auth/pin_lock_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // EasyLocalization initialisieren
  await EasyLocalization.ensureInitialized();

  // Firebase initialisieren
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase Messaging Background Handler registrieren
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Anonymous Auth (automatisch)
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  // Push Notifications initialisieren
  await NotificationService().initialize();

  // Status bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
        Locale('tr'),
        Locale('bs'),
        Locale('sr'),
        Locale('hr'),
      ],
      path: 'assets/locales',
      fallbackLocale: const Locale('de'),
      child: const ProviderScope(child: ParentApp()),
    ),
  );
}

class ParentApp extends StatelessWidget {
  const ParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids AI Parent Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ParentTheme.dark,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const AppRoot(),
    );
  }
}

/// Root Widget: Onboarding → PIN → Dashboard
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);
    final pinState = ref.watch(pinUnlockStateProvider);

    // Erst Onboarding prüfen
    return onboardingCompleted.when(
      data: (completed) {
        if (!completed) {
          return OnboardingScreen(
            onComplete: () {
              ref.invalidate(onboardingCompletedProvider);
            },
          );
        }

        // Onboarding fertig → PIN prüfen
        switch (pinState) {
          case PinUnlockState.loading:
            return const LoadingScreen();
          case PinUnlockState.locked:
            return const PinLockScreen();
          case PinUnlockState.unlocked:
          case PinUnlockState.noPinSet:
            return const DashboardScreen();
        }
      },
      loading: () => const LoadingScreen(),
      error: (error, _) => ErrorScreen(message: error.toString()),
    );
  }
}

/// Loading Screen
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Error Screen
class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Ein Fehler ist aufgetreten',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
