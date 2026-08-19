import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_brand_terms.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/language_selector_button.dart';
import '../widgets/vault_logo.dart';

/// First-launch onboarding screen for Caveau.
/// 
/// Guides the user through:
/// - Language selection
/// - Architectural security briefing (100% offline, zero-knowledge, no password recovery)
/// - Legal & transparency disclaimers (GitHub open source & Privacy Policy)
/// - Mandatory user awareness confirmation checkbox
/// - Initial Master PIN creation with matching validation (min 4 characters)
/// - Biometric unlock enablement toggle
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
  bool _disclaimerAccepted = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  /// Opens an external URL (e.g. GitHub repository, Privacy Policy) in the device browser.
  Future<void> _openExternalUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silently ignore browser launch errors
    }
  }

  /// Validates input criteria and initializes the Master PIN and security settings.
  void _submit() async {
    final l10n = context.l10n;
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (!_disclaimerAccepted) {
      setState(() {
        _error = l10n.onboardingDisclaimerCheckbox;
      });
      return;
    }

    if (pin.length < 4) {
      setState(() {
        _error = l10n.minMasterPinError;
      });
      return;
    }

    if (pin != confirm) {
      setState(() {
        _error = l10n.pinsDoNotMatchError;
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
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Language Selector Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  LanguageSelectorButton(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  MediaQuery.of(context).padding.bottom + 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Vault Safe Icon
                    const Center(
                      child: VaultLogo(
                        size: 88,
                        showGlow: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.welcomeToCaveau,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.onboardingSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ============================================================
                    // INFORMATION BRIEFING CARD: ARCHITECTURE, BACKUP, GITHUB & PRIVACY
                    // ============================================================
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.primaryLight,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.onboardingInfoTitle,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 1. 100% Offline & Zero-Knowledge
                          _buildInfoItem(
                            icon: Icons.shield_outlined,
                            iconColor: AppColors.success,
                            title: l10n.onboardingInfoZeroKnowledgeTitle,
                            description: l10n.onboardingInfoZeroKnowledgeDesc,
                          ),
                          const SizedBox(height: 14),

                          // 2. Backup & No Remote Password Recovery
                          _buildInfoItem(
                            icon: Icons.cloud_off_rounded,
                            iconColor: AppColors.warning,
                            title: l10n.onboardingInfoBackupTitle,
                            description: l10n.onboardingInfoBackupDesc,
                          ),
                          const SizedBox(height: 14),

                          // 3. 100% Free & No Hidden Costs
                          _buildInfoItem(
                            icon: Icons.card_giftcard_rounded,
                            iconColor: AppColors.primaryLight,
                            title: l10n.onboardingInfoFreeAppTitle,
                            description: l10n.onboardingInfoFreeAppDesc,
                          ),
                          const SizedBox(height: 14),

                          // 4. Open Source on GitHub
                          _buildInfoItem(
                            icon: Icons.code_rounded,
                            iconColor: AppColors.info,
                            title: l10n.onboardingInfoOpenSourceTitle,
                            description: l10n.onboardingInfoOpenSourceDesc,
                            actionWidget: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                                label: Text(
                                  l10n.openSourceGitHubButton,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () => _openExternalUrl(AppBrandTerms.githubRepoUrl),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 5. Privacy Policy & Terms
                          _buildInfoItem(
                            icon: Icons.policy_outlined,
                            iconColor: AppColors.info,
                            title: l10n.onboardingInfoPrivacyPolicyTitle,
                            description: l10n.onboardingInfoPrivacyPolicyDesc,
                            actionWidget: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                                label: Text(
                                  l10n.viewPrivacyPolicyButton,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () => _openExternalUrl(AppBrandTerms.privacyPolicyUrl),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ============================================================
                    // USER AWARENESS & ACKNOWLEDGEMENT CHECKBOX
                    // ============================================================
                    InkWell(
                      onTap: () => setState(() => _disclaimerAccepted = !_disclaimerAccepted),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _disclaimerAccepted
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _disclaimerAccepted ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _disclaimerAccepted,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) => setState(() => _disclaimerAccepted = val ?? false),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  l10n.onboardingDisclaimerCheckbox,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ============================================================
                    // MASTER PIN CREATION FORM
                    // ============================================================
                    Text(
                      l10n.createMasterPinTitle,
                      style: const TextStyle(
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
                      decoration: InputDecoration(
                        hintText: l10n.confirmMasterPinHint,
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
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

                    // Biometrics toggle switch (if device supports biometric sensors)
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
                            Expanded(
                              child: Text(
                                l10n.enableBiometricSwitch,
                                style: const TextStyle(
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

                    // Initialize Vault action button
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(l10n.initializeVaultButton),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget rendering a single informative tile with icon, title, description, and optional action.
  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    Widget? actionWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              if (actionWidget != null) actionWidget,
            ],
          ),
        ),
      ],
    );
  }
}
