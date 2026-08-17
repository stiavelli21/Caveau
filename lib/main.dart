import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/secure_storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/vault_provider.dart';
import 'views/auth/lock_screen.dart';
import 'views/auth/onboarding_screen.dart';
import 'views/vault/vault_home_screen.dart';
import 'views/widgets/privacy_shield.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza i dati di localizzazione delle date
  await initializeDateFormatting('it_IT', null);

  // Dark navigation & status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const CaveauRoot());
}

class CaveauRoot extends StatelessWidget {
  final SecureStorageService? storageService;
  final AuthService? authService;

  const CaveauRoot({
    super.key,
    this.storageService,
    this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStorage = storageService ?? SecureStorageService();
    final effectiveAuth = authService ?? AuthService(storageService: effectiveStorage);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: effectiveAuth,
            storageService: effectiveStorage,
          )..checkInitialState(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            storageService: effectiveStorage,
          )..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => VaultProvider(
            storageService: effectiveStorage,
          ),
        ),
      ],
      child: const CaveauApp(),
    );
  }
}

class CaveauApp extends StatefulWidget {
  const CaveauApp({super.key});

  @override
  State<CaveauApp> createState() => _CaveauAppState();
}

class _CaveauAppState extends State<CaveauApp> with WidgetsBindingObserver {
  DateTime? _pausedAt;
  bool _isBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final settings = settingsProvider.settings;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now();
      setState(() {
        _isBackgrounded = true;
      });

      // Immediate auto-lock
      if (settings.autoLockSeconds == 0 &&
          authProvider.status == AuthStatus.authenticated) {
        authProvider.lock();
      }
    } else if (state == AppLifecycleState.resumed) {
      setState(() {
        _isBackgrounded = false;
      });

      if (_pausedAt != null &&
          authProvider.status == AuthStatus.authenticated &&
          settings.autoLockSeconds > 0) {
        final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
        if (elapsed >= settings.autoLockSeconds) {
          authProvider.lock();
        }
      }
      _pausedAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final shouldShowPrivacyShield = _isBackgrounded &&
        settingsProvider.settings.privacyScreenEnabled;

    return MaterialApp(
      title: 'Caveau',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return PrivacyShield(
          isShieldActive: shouldShowPrivacyShield,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _buildHome(authProvider.status),
    );
  }

  Widget _buildHome(AuthStatus status) {
    switch (status) {
      case AuthStatus.initial:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.setupRequired:
        return const OnboardingScreen();
      case AuthStatus.locked:
        return const LockScreen();
      case AuthStatus.authenticated:
        return const VaultHomeScreen();
    }
  }
}
