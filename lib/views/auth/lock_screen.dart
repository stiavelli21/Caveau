import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/vault_logo.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    if (state == AppLifecycleState.resumed) {
      _triggerBiometricsIfAllowed();
    }
  }

  Future<void> _triggerBiometricsIfAllowed({bool isManual = false}) async {
    if (_isAuthenticating || !mounted) return;

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

  void _submitPin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.authenticateWithPin(pin);
    if (!success) {
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final canUseBiometrics = authProvider.isBiometricSupported &&
        settingsProvider.settings.biometricsEnabled &&
        !authProvider.isLockedOut;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              28,
              24,
              28,
              MediaQuery.of(context).padding.bottom + 28,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glowing Vault Safe Icon
                const Center(
                  child: VaultLogo(
                    size: 88,
                    showGlow: true,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Caveau Protetto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inserisci il PIN Master per accedere',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // PIN Input Field
                TextField(
                  controller: _pinController,
                  obscureText: _obscurePin,
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
                    hintText: 'Inserisci PIN Master',
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

                // Error message
                if (authProvider.errorMessage != null) ...[
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
                            authProvider.errorMessage!,
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
                  child: const Text('Sblocca Cassaforte'),
                ),

                // Retry Biometrics Action Button (if supported and enabled)
                if (canUseBiometrics) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _triggerBiometricsIfAllowed(isManual: true),
                    icon: const Icon(
                      Icons.fingerprint_rounded,
                      size: 22,
                      color: AppColors.primaryLight,
                    ),
                    label: const Text(
                      'Sblocca con Biometria / Face ID',
                      style: TextStyle(
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
            ),
          ),
        ),
      ),
    );
  }
}

