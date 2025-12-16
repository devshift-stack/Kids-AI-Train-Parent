import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/parent_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/pin_provider.dart';
import 'providers/onboarding_provider.dart';
import 'screens/auth/pin_lock_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialisieren
  await Firebase.initializeApp();

  // Status bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: ParentApp()));
}

class ParentApp extends StatelessWidget {
  const ParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids AI Parent Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ParentTheme.dark,
      home: const AppRoot(),
    );
  }
}

/// Root Widget das Onboarding, Auth-State und PIN-Lock verwaltet
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);
    final authState = ref.watch(authStateProvider);
    final pinState = ref.watch(pinUnlockStateProvider);

    // Erst Onboarding prüfen
    return onboardingCompleted.when(
      data: (completed) {
        if (!completed) {
          // Onboarding noch nicht abgeschlossen
          return OnboardingScreen(
            onComplete: () {
              ref.invalidate(onboardingCompletedProvider);
            },
          );
        }

        // Onboarding fertig -> Auth prüfen
        return authState.when(
          data: (user) {
            if (user == null) {
              // Nicht eingeloggt -> Login Screen
              return const LoginScreen();
            }

            // Eingeloggt -> PIN-Check
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

/// Login Screen (Placeholder - kann erweitert werden)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Icon(
                Icons.family_restroom,
                size: 64,
                color: ParentTheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _isLogin ? 'Willkommen zurück!' : 'Konto erstellen',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Melde dich an um deine Kinder zu verwalten'
                    : 'Erstelle ein Konto für das Eltern-Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'E-Mail',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.email, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Passwort',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.lock, color: Colors.white54),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isLogin ? 'Anmelden' : 'Registrieren',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? 'Noch kein Konto? Registrieren'
                        : 'Bereits ein Konto? Anmelden',
                    style: TextStyle(color: ParentTheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Bitte E-Mail und Passwort eingeben';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final result = _isLogin
        ? await authService.signInWithEmail(email, password)
        : await authService.registerWithEmail(email, password);

    setState(() {
      _isLoading = false;
      if (!result.isSuccess) {
        _errorMessage = result.errorMessage;
      }
    });
  }
}
