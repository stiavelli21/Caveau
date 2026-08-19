import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/settings_provider.dart';

class LanguageSelectorButton extends StatelessWidget {
  final bool isCompact;

  const LanguageSelectorButton({
    super.key,
    this.isCompact = false,
  });

  void _showLanguagePicker(BuildContext context) {
    HapticFeedback.selectionClick();
    final settingsProvider = context.read<SettingsProvider>();
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final current = settingsProvider.settings.languageCode;
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              0,
              16,
              0,
              MediaQuery.of(ctx).padding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    l10n.selectLanguageTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const Divider(color: AppColors.border),
                ...AppLocalizations.supportedLanguages.map((lang) {
                  final isSelected = current == lang.code;
                  return ListTile(
                    leading: Text(lang.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(
                      lang.nativeName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: lang.nativeName != lang.englishName
                        ? Text(
                            lang.englishName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          )
                        : null,
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight)
                        : null,
                    onTap: () {
                      settingsProvider.updateLanguage(lang.code);
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final currentLangCode = settingsProvider.settings.languageCode;
    final currentMeta = AppLocalizations.supportedLanguages.firstWhere(
      (l) => l.code == currentLangCode,
      orElse: () => AppLocalizations.supportedLanguages.first,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLanguagePicker(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentMeta.flag,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                currentMeta.code.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
