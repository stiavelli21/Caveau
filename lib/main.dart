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
  final DateTime Function()? clock;

  const CaveauRoot({
    super.key,
    this.storageService,
    this.authService,
    this.screenSecurityService,
    this.clock,
  });

  @override
  Widget build(BuildContext context) {
    // Instantiate or fallback to production services
    final effectiveStorage = storageService ?? SecureStorageService();
    final effectiveAuth = authService ?? AuthService(storageService: effectiveStorage);
    final effectiveClock = clock ?? (() => DateTime.now());

    return MultiProvider(
      providers: [
        // Authentication state provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: effectiveAuth,
            storageService: effectiveStorage,
            clock: effectiveClock,
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
        clock: effectiveClock,
      ),
    );
  }
}

/// Main application widget that observes OS lifecycle events ([WidgetsBindingObserver])
/// and screen recording events to enforce auto-lock intervals and activate the [PrivacyShield] overlay.
class CaveauApp extends StatefulWidget {
  final ScreenSecurityService? screenSecurityService;
  final DateTime Function()? clock;

  const CaveauApp({
    super.key,
    this.screenSecurityService,
    this.clock,
  });

  @override
  State<CaveauApp> createState() => _CaveauAppState();
}

class _CaveauAppState extends State<CaveauApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// Timestamp recorded when the app transitioned into background/inactive state.
  DateTime? _pausedAt;

  /// Timestamp recorded on the last detected user interaction in foreground.
  DateTime? _lastInteractionTime;

  /// Tracks whether the app is currently hidden/backgrounded in the OS task switcher.
  bool _isBackgrounded = false;

  /// Tracks whether screen recording or screen capture is currently detected.
  bool _isScreenCaptureActive = false;

  late final ScreenSecurityService _screenSecurityService;
  StreamSubscription<bool>? _screenCaptureSub;

  /// In-app timer counting down user inactivity while in the foreground.
  Timer? _inactivityTimer;

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
    // Unregister lifecycle listener, inactivity timer, and screen capture subscription
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _screenCaptureSub?.cancel();
    if (widget.screenSecurityService == null) {
      _screenSecurityService.dispose();
    }
    super.dispose();
  }

  /// Tracks the previous AuthStatus to detect fresh unlock events.
  AuthStatus? _lastAuthStatus;

  /// Returns current time using injected [widget.clock] or system [DateTime.now].
  DateTime _getNow() => widget.clock?.call() ?? DateTime.now();

  /// Calculates the effective inactivity timeout in seconds.
  /// When autoLockSeconds == 0 (Immediate), an inactivity threshold of 5 seconds is enforced in foreground.
  int _getEffectiveInactivitySeconds(int autoLockSeconds) {
    if (autoLockSeconds == 0) return 5;
    return autoLockSeconds;
  }

  /// Automatically locks the vault, dismisses open modal dialogs/sheets, and returns to LockScreen.
  void _lockVault() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _pausedAt = null;
    _lastInteractionTime = null;
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    if (authProvider.status == AuthStatus.authenticated) {
      authProvider.lock();
    }
  }

  /// Resets and restarts the inactivity timer for the active session.
  /// If [customDurationSeconds] is provided, sets the timer for that remaining duration.
  void _resetInactivityTimer({int? customDurationSeconds}) {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final autoLockSecs = settingsProvider.settings.autoLockSeconds;

    if (authProvider.status == AuthStatus.authenticated && !_isBackgrounded) {
      _lastInteractionTime = _getNow();
      final timeoutSecs = customDurationSeconds ?? _getEffectiveInactivitySeconds(autoLockSecs);
      _inactivityTimer = Timer(Duration(seconds: timeoutSecs), _lockVault);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final settings = settingsProvider.settings;

    // Handle transitions to background or multitasking inactive mode
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _inactivityTimer?.cancel();
      _inactivityTimer = null;
      setState(() {
        _isBackgrounded = true;
      });

      if (authProvider.status == AuthStatus.authenticated) {
        _pausedAt = _getNow();
        // Immediate auto-lock (autoLockSeconds == 0)
        if (settings.autoLockSeconds == 0) {
          _lockVault();
        }
      }
    } else if (state == AppLifecycleState.inactive) {
      // Inactive is an ephemeral state (e.g. system biometric dialog, notification shade).
      // We obscure screen content for privacy without treating it as app backgrounding.
      setState(() {
        _isBackgrounded = true;
      });
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

      // Check if elapsed background or total inactivity time exceeds auto-lock threshold
      // ONLY if the app was authenticated before going to background (_pausedAt != null).
      if (authProvider.status == AuthStatus.authenticated) {
        if (_pausedAt != null) {
          final now = _getNow();
          if (settings.autoLockSeconds == 0) {
            _lockVault();
          } else {
            final timeout = settings.autoLockSeconds;
            final elapsedInBackground = now.difference(_pausedAt!).inSeconds;
            final elapsedSinceLastActivity = _lastInteractionTime != null
                ? now.difference(_lastInteractionTime!).inSeconds
                : elapsedInBackground;

            if (elapsedInBackground >= timeout ||
                elapsedSinceLastActivity >= timeout) {
              _lockVault();
            } else {
              final remaining = timeout - elapsedSinceLastActivity;
              _resetInactivityTimer(
                customDurationSeconds: remaining > 0 ? remaining : timeout,
              );
            }
          }
        } else {
          // Returning from an ephemeral inactive state (such as biometric prompt)
          if (_inactivityTimer == null || !_inactivityTimer!.isActive) {
            _resetInactivityTimer();
          }
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

    // Detect fresh authentication / unlock transition
    if (authProvider.status == AuthStatus.authenticated &&
        _lastAuthStatus != AuthStatus.authenticated) {
      _pausedAt = null;
      _lastInteractionTime = _getNow();
      _inactivityTimer?.cancel();
      _inactivityTimer = null;
      _resetInactivityTimer();
    } else if (authProvider.status != AuthStatus.authenticated &&
        _lastAuthStatus == AuthStatus.authenticated) {
      _pausedAt = null;
      _lastInteractionTime = null;
      _inactivityTimer?.cancel();
      _inactivityTimer = null;
    }
    _lastAuthStatus = authProvider.status;

    // Manage in-app inactivity auto-lock timer
    if (authProvider.status == AuthStatus.authenticated && !_isBackgrounded) {
      if (_inactivityTimer == null || !_inactivityTimer!.isActive) {
        _resetInactivityTimer();
      }
    } else {
      _inactivityTimer?.cancel();
      _inactivityTimer = null;
    }

    // Sync native OS FLAG_SECURE / screen protection with settings
    _screenSecurityService.setSecureFlag(privacyEnabled);

    // Determine if privacy shield overlay should obscure screen content
    final shouldShowPrivacyShield = (_isBackgrounded || _isScreenCaptureActive) &&
        privacyEnabled;

    return MaterialApp(
      navigatorKey: _navigatorKey,
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
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _resetInactivityTimer(),
          onPointerMove: (_) => _resetInactivityTimer(),
          onPointerHover: (_) => _resetInactivityTimer(),
          onPointerPanZoomUpdate: (_) => _resetInactivityTimer(),
          onPointerSignal: (_) => _resetInactivityTimer(),
          child: Focus(
            onKeyEvent: (node, event) {
              _resetInactivityTimer();
              return KeyEventResult.ignored;
            },
            child: PrivacyShield(
              isShieldActive: shouldShowPrivacyShield,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
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
      case AuthStatus.autoWiped:
        return const _AutoWipeNoticeScreen();
    }
  }
}

/// Full-screen notification displayed when the vault has been auto-wiped
/// after exceeding the maximum allowed failed PIN attempts.
class _AutoWipeNoticeScreen extends StatelessWidget {
  const _AutoWipeNoticeScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Show the notification once, then acknowledge and route to onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final auth = context.read<AuthProvider>();
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF131B2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFEF4444)),
          ),
          title: Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.autoWipeDialogTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            l10n.autoWipeTriggered,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  auth.acknowledgeAutoWipe();
                },
                child: Text(
                  l10n.autoWipeRestartButton,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
