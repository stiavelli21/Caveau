import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/vault_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _obscurePin = true;
  bool _enableBiometrics = true;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _submit() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (pin.length < 4) {
      setState(() {
        _error = 'Il PIN Master deve contenere almeno 4 caratteri o cifre';
      });
      return;
    }

    if (pin != confirm) {
      setState(() {
        _error = 'I PIN inseriti non corrispondono';
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    await authProvider.setupMasterPin(pin);
    await settingsProvider.updateBiometrics(_enableBiometrics);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).padding.bottom + 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Vault Safe Icon
              const Center(
                child: VaultLogo(
                  size: 96,
                  showGlow: true,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Benvenuto in Caveau',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La tua cassaforte crittografata locale per password e dati sensibili.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              // Security info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_clock_rounded,
                      color: AppColors.success,
                      size: 24,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'I tuoi dati vengono crittografati sul dispositivo (Android Keystore / iOS Keychain). Nessun dato lascia mai il telefono.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Master PIN Input
              const Text(
                'Crea il tuo PIN Master',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  letterSpacing: 2,
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
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
                decoration: const InputDecoration(
                  hintText: 'Conferma PIN Master',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Biometrics Switch (if available)
              if (authProvider.isBiometricSupported)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fingerprint_rounded,
                        color: AppColors.primaryLight,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Abilita Sblocco Biometrico (Face ID / Impronta)',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: _enableBiometrics,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => setState(() => _enableBiometrics = val),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              // Submit Button
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Inizializza Caveau Sicuro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
