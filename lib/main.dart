import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/auth_service.dart';
import 'core/services/screen_security_service.dart';
import 'core/services/secure_storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/vault_provider.dart';
import 'views/auth/lock_screen.dart';
import 'views/auth/onboarding_screen.dart';
import 'views/vault/vault_home_screen.dart';
import 'views/widgets/privacy_shield.dart';

/// Application entry point for Caveau.
/// 
/// Initializes date formatting localization data, configures system overlay aesthetics,
/// and bootstraps the root application widget tree.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize intl date formatting symbol tables for all 5 supported locales (IT, EN, ES, FR, DE)
  await initializeDateFormatting('it_IT', null);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('es_ES', null);
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('de_DE', null);

  // Configure edge-to-edge dark system navigation and status bar style
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

/// Root widget configuring dependency injection via [MultiProvider].
/// Supports optional constructor parameters to inject mock services during automated testing.
class CaveauRoot extends StatelessWidget {
  final SecureStorageService? storageService;
  final AuthService? authService;
  final ScreenSecurityService? screenSecurityService;

  const CaveauRoot({
    super.key,
    this.storageService,
    this.authService,
    this.screenSecurityService,
  });

  @override
  Widget build(BuildContext context) {
    // Instantiate or fallback to production services
    final effectiveStorage = storageService ?? SecureStorageService();
    final effectiveAuth = authService ?? AuthService(storageService: effectiveStorage);

    return MultiProvider(
      providers: [
        // Authentication state provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: effectiveAuth,
            storageService: effectiveStorage,
          )..checkInitialState(),
        ),
        // User settings & localization provider
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            storageService: effectiveStorage,
          )..loadSettings(),
        ),
        // In-memory vault data provider
        ChangeNotifierProvider(
          create: (_) => VaultProvider(
            storageService: effectiveStorage,
          ),
        ),
      ],
      child: CaveauApp(
        screenSecurityService: screenSecurityService,
      ),
    );
  }
}

/// Main application widget that observes OS lifecycle events ([WidgetsBindingObserver])
/// and screen recording events to enforce auto-lock intervals and activate the [PrivacyShield] overlay.
class CaveauApp extends StatefulWidget {
  final ScreenSecurityService? screenSecurityService;

  const CaveauApp({
    super.key,
    this.screenSecurityService,
  });

  @override
  State<CaveauApp> createState() => _CaveauAppState();
}

class _CaveauAppState extends State<CaveauApp> with WidgetsBindingObserver {
  /// Timestamp recorded when the app transitioned into background/inactive state.
  DateTime? _pausedAt;

  /// Tracks whether the app is currently hidden/backgrounded in the OS task switcher.
  bool _isBackgrounded = false;

  /// Tracks whether screen recording or screen capture is currently detected.
  bool _isScreenCaptureActive = false;

  late final ScreenSecurityService _screenSecurityService;
  StreamSubscription<bool>? _screenCaptureSub;

  @override
  void initState() {
    super.initState();
    // Register lifecycle listener
    WidgetsBinding.instance.addObserver(this);

    _screenSecurityService = widget.screenSecurityService ?? ScreenSecurityService();

    // Check initial screen capture status
    _screenSecurityService.isScreenCaptureActive().then((active) {
      if (mounted && active != _isScreenCaptureActive) {
        setState(() {
          _isScreenCaptureActive = active;
        });
      }
    });

    // Listen to real-time screen capture / recording changes
    _screenCaptureSub = _screenSecurityService.onScreenCaptureChanged.listen((active) {
      if (mounted && active != _isScreenCaptureActive) {
        setState(() {
          _isScreenCaptureActive = active;
        });
      }
    });
  }

  @override
  void dispose() {
    // Unregister lifecycle listener and screen capture subscription
    WidgetsBinding.instance.removeObserver(this);
    _screenCaptureSub?.cancel();
    if (widget.screenSecurityService == null) {
      _screenSecurityService.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final settings = settingsProvider.settings;

    // Handle transitions to background or multitasking inactive mode
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now();
      setState(() {
        _isBackgrounded = true;
      });

      // Immediate auto-lock (autoLockSeconds == 0)
      if (settings.autoLockSeconds == 0 &&
          authProvider.status == AuthStatus.authenticated) {
        authProvider.lock();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Returned to foreground
      setState(() {
        _isBackgrounded = false;
      });

      // Re-check screen capture on resume
      _screenSecurityService.isScreenCaptureActive().then((active) {
        if (mounted && active != _isScreenCaptureActive) {
          setState(() {
            _isScreenCaptureActive = active;
          });
        }
      });

      // Check if elapsed background time exceeds configured auto-lock threshold
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
    final privacyEnabled = settingsProvider.settings.privacyScreenEnabled;

    // Sync native OS FLAG_SECURE / screen protection with settings
    _screenSecurityService.setSecureFlag(privacyEnabled);

    // Determine if privacy shield overlay should obscure screen content
    final shouldShowPrivacyShield = (_isBackgrounded || _isScreenCaptureActive) &&
        privacyEnabled;

    return MaterialApp(
      title: 'Caveau',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: Locale(settingsProvider.settings.languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return PrivacyShield(
          isShieldActive: shouldShowPrivacyShield,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _buildHome(authProvider.status),
    );
  }


  /// Routes to the appropriate screen depending on current [AuthStatus].
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
