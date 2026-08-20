import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/utils/password_generator.dart';
import '../widgets/password_strength_bar.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/swipe_back_wrapper.dart';

/// Dedicated utility screen for generating and evaluating cryptographically strong passwords.
/// 
/// Supports:
/// - Adjustable length slider (8 to 48 characters)
/// - Toggleable character sets (uppercase, lowercase, numbers, symbols)
/// - Ambiguous character exclusion (Il1O0)
/// - Real-time password strength meter and entropy calculation
/// - Direct clipboard copy with auto-clear
/// - Responsive 2-column layout on desktop, single-column on mobile
/// - Optional [onPasswordSelected] callback when invoked as a picker from the Vault editor
class PasswordGeneratorScreen extends StatefulWidget {
  /// Optional callback invoked when the user selects the generated password for a form.
  final ValueChanged<String>? onPasswordSelected;

  /// Creates a [PasswordGeneratorScreen] instance.
  const PasswordGeneratorScreen({
    super.key,
    this.onPasswordSelected,
  });

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  int _length = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _excludeAmbiguous = false;

  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  /// Regenerates the password string using current settings.
  void _regenerate() {
    final pwd = PasswordGenerator.generate(
      length: _length,
      includeUppercase: _includeUppercase,
      includeLowercase: _includeLowercase,
      includeNumbers: _includeNumbers,
      includeSymbols: _includeSymbols,
      excludeAmbiguous: _excludeAmbiguous,
    );
    setState(() {
      _generatedPassword = pwd;
    });
  }

  /// Copies the generated password to the clipboard with a 30-second auto-clear timer.
  void _copy() {
    final l10n = context.l10n;
    ClipboardService.copyWithAutoClear(_generatedPassword, autoClearSeconds: 30);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Text(
              l10n.fieldCopiedAutoClear(l10n.passwordLabel, 30),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDesktop = isDesktopView(context);

    return SwipeBackWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.passwordGeneratorTitle),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 36,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 900 : double.infinity,
                ),
                child: isDesktop
                    ? _buildDesktopLayout(context, l10n)
                    : _buildMobileLayout(context, l10n),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPasswordDisplayCard(context),
        const SizedBox(height: 28),
        _buildSliderCard(context, l10n),
        const SizedBox(height: 16),
        _buildToggleCard(l10n),
        const SizedBox(height: 24),
        _buildActionButton(l10n),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Password Display & Actions
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPasswordDisplayCard(context),
              const SizedBox(height: 24),
              _buildActionButton(l10n),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Right Column: Controls & Toggles
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSliderCard(context, l10n),
              const SizedBox(height: 16),
              _buildToggleCard(l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordDisplayCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  _generatedPassword,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.primaryLight, size: 26),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _regenerate();
                },
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    color: AppColors.textSecondary, size: 24),
                onPressed: _copy,
              ),
            ],
          ),
          const SizedBox(height: 10),
          PasswordStrengthBar(password: _generatedPassword),
        ],
      ),
    );
  }

  Widget _buildSliderCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.lengthSliderLabel,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(
                  '$_length',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              thumbColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceHighlight,
            ),
            child: Slider(
              value: _length.toDouble(),
              min: 8,
              max: 48,
              divisions: 40,
              onChanged: (val) {
                setState(() => _length = val.round());
                _regenerate();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildToggleTile(
            title: l10n.uppercaseOption,
            value: _includeUppercase,
            onChanged: (val) {
              setState(() => _includeUppercase = val);
              _regenerate();
            },
          ),
          const Divider(color: AppColors.border),
          _buildToggleTile(
            title: l10n.lowercaseOption,
            value: _includeLowercase,
            onChanged: (val) {
              setState(() => _includeLowercase = val);
              _regenerate();
            },
          ),
          const Divider(color: AppColors.border),
          _buildToggleTile(
            title: l10n.numbersOption,
            value: _includeNumbers,
            onChanged: (val) {
              setState(() => _includeNumbers = val);
              _regenerate();
            },
          ),
          const Divider(color: AppColors.border),
          _buildToggleTile(
            title: l10n.symbolsOption,
            value: _includeSymbols,
            onChanged: (val) {
              setState(() => _includeSymbols = val);
              _regenerate();
            },
          ),
          const Divider(color: AppColors.border),
          _buildToggleTile(
            title: l10n.excludeAmbiguousOption,
            subtitle: l10n.excludeAmbiguousSubtitle,
            value: _excludeAmbiguous,
            onChanged: (val) {
              setState(() => _excludeAmbiguous = val);
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(AppLocalizations l10n) {
    if (widget.onPasswordSelected != null) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () {
          widget.onPasswordSelected!(_generatedPassword);
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.check_rounded),
        label: Text(l10n.usePasswordButton),
      );
    }
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: _copy,
      icon: const Icon(Icons.copy_rounded),
      label: Text(l10n.copyPassword),
    );
  }

  /// Helper rendering an individual character-set switch tile.
  Widget _buildToggleTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
