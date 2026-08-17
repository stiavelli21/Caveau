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

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _hasAttemptedAutoBiometrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricsIfAllowed();
    });
  }

  void _triggerBiometricsIfAllowed() async {
    if (_hasAttemptedAutoBiometrics) return;
    _hasAttemptedAutoBiometrics = true;

    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    if (authProvider.isBiometricSupported &&
        settingsProvider.settings.biometricsEnabled &&
        !authProvider.isLockedOut) {
      await authProvider.authenticateWithBiometrics();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
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
                    size: 96,
                    showGlow: true,
                  ),
                ),
                const SizedBox(height: 28),
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
                  'Sblocca per accedere alle tue credenziali',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 36),
                // Biometrics Quick Button
                if (authProvider.isBiometricSupported &&
                    settingsProvider.settings.biometricsEnabled &&
                    !authProvider.isLockedOut) ...[
                  OutlinedButton.icon(
                    onPressed: () => authProvider.authenticateWithBiometrics(),
                    icon: const Icon(Icons.fingerprint_rounded, size: 28, color: AppColors.primaryLight),
                    label: const Text(
                      'Sblocca con Biometria / Face ID',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OPPURE USA IL PIN MASTER',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
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
                    prefixIcon: const Icon(Icons.pin_rounded),
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
                ElevatedButton(
                  onPressed: authProvider.isLockedOut ? null : _submitPin,
                  child: const Text('Sblocca Cassaforte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
