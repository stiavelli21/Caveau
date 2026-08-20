import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/language_selector_button.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/vault_logo.dart';

/// Screen displayed when the vault is locked.
///
/// Provides:
/// - Language selector button in the top bar for instant multilingual switching
/// - Responsive adaptation (centered cyber-dark card on desktop, full-screen on mobile)
/// - **Biometrics-first flow on mobile**: if biometrics are enabled the prompt fires
///   automatically, but a "Use PIN instead" button lets the user skip biometrics
///   for that single unlock session (biometrics remain enabled in settings).
/// - Fallback Master PIN text input with show/hide toggle and keyboard Enter support
/// - Anti-brute-force lockout messaging and countdown display
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _isAuthenticating = false;

  /// When `true` the user has explicitly chosen to skip biometrics for this
  /// unlock session and the PIN form is shown directly instead of the
  /// biometrics-first UI. Does NOT affect the biometrics setting.
  bool _biometricsSkipped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-trigger biometric prompt after initial frame layout if biometrics are enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricsIfAllowed();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app comes back to foreground, reset the skip flag so biometrics
    // are prompted again (good UX: every re-lock cycle tries biometrics first).
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        context.read<AuthProvider>().refreshLockoutState();
      }
      if (_biometricsSkipped) {
        setState(() => _biometricsSkipped = false);
      }
      _triggerBiometricsIfAllowed();
    }
  }

  /// Triggers biometric authentication if enabled in settings and supported by hardware.
  /// If [isManual] is false, silently fails without popping intrusive error banners.
  /// Does nothing if the user has skipped biometrics for this session.
  Future<void> _triggerBiometricsIfAllowed({bool isManual = false}) async {
    if (_isAuthenticating || !mounted) return;
    if (isDesktopView(context)) return;
    if (_biometricsSkipped) return;

    // Do not trigger biometrics automatically when the app is inactive, paused, or backgrounded
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!isManual && lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    if (authProvider.isBiometricSupported &&
        settingsProvider.settings.biometricsEnabled &&
        !authProvider.isLockedOut &&
        authProvider.status == AuthStatus.locked) {
      _isAuthenticating = true;
      try {
        await authProvider.authenticateWithBiometrics(silentFail: !isManual);
      } finally {
        if (mounted) {
          _isAuthenticating = false;
        }
      }
    }
  }

  /// Called when the user taps "Use PIN instead".
  /// Skips biometrics only for this session without touching settings.
  void _skipBiometrics() {
    setState(() => _biometricsSkipped = true);
    // Give focus to the PIN field after the frame updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  /// Verifies the entered Master PIN.
  void _submitPin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLockedOut) return;

    final success = await authProvider.authenticateWithPin(pin);
    if (!success) {
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final l10n = context.l10n;
    final isDesktop = isDesktopView(context);

    // Biometrics are available and the user hasn't skipped them for this session
    final canUseBiometrics = authProvider.isBiometricSupported &&
        settingsProvider.settings.biometricsEnabled &&
        !authProvider.isLockedOut &&
        !isDesktop;

    // Show the biometrics-first UI when biometrics are usable and not skipped
    final showBiometricsFirst = canUseBiometrics && !_biometricsSkipped;

    final errorMessage = authProvider.getLocalizedErrorMessage(l10n);

    Widget formContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Glowing Vault Safe Icon
        Center(
          child: VaultLogo(
            size: isDesktop ? 96 : 88,
            showGlow: true,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.vaultProtectedTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.enterMasterPinPrompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),

        if (showBiometricsFirst) ...[
          // ─── BIOMETRICS-FIRST UI ─────────────────────────────────────
          // Large fingerprint / face icon as the primary CTA
          Center(
            child: InkWell(
              onTap: () => _triggerBiometricsIfAllowed(isManual: true),
              borderRadius: BorderRadius.circular(60),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  size: 52,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Error message for biometric failures
          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: AppColors.dangerLight,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 4),

          // Primary biometric button
          ElevatedButton.icon(
            onPressed: () => _triggerBiometricsIfAllowed(isManual: true),
            icon: const Icon(Icons.fingerprint_rounded, size: 20),
            label: Text(l10n.unlockWithBiometricsButton),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 14),

          // Secondary: skip biometrics → show PIN for this session
          TextButton(
            onPressed: _skipBiometrics,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(
              l10n.usePinInsteadButton,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ] else ...[
          // ─── PIN FORM UI ─────────────────────────────────────────────
          // PIN Input Field
          TextField(
            controller: _pinController,
            obscureText: _obscurePin,
            autofocus: false,
            keyboardType: TextInputType.text,
            enabled: !authProvider.isLockedOut,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitPin(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              letterSpacing: 3,
            ),
            decoration: InputDecoration(
              hintText: l10n.insertMasterPinHint,
              prefixIcon: const Icon(Icons.password_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePin = !_obscurePin),
              ),
            ),
          ),

          // Error message container
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: AppColors.dangerLight,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Primary Unlock Button (PIN)
          ElevatedButton(
            onPressed: authProvider.isLockedOut ? null : _submitPin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.unlockVaultButton),
          ),

          // Go back to biometrics button (if supported and not locked out)
          if (canUseBiometrics && _biometricsSkipped) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _biometricsSkipped = false);
                _triggerBiometricsIfAllowed(isManual: true);
              },
              icon: const Icon(
                Icons.fingerprint_rounded,
                size: 22,
                color: AppColors.primaryLight,
              ),
              label: Text(
                l10n.unlockWithBiometricsButton,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ],
    );

    if (isDesktop) {
      formContent = Container(
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: formContent,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header with Language Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  LanguageSelectorButton(),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    28,
                    8,
                    28,
                    MediaQuery.of(context).padding.bottom + 28,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 460 : double.infinity,
                    ),
                    child: formContent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
