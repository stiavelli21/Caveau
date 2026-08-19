import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_brand_terms.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vault_provider.dart';
import '../widgets/swipe_back_wrapper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showLanguagePicker(BuildContext context, SettingsProvider provider) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final current = provider.settings.languageCode;
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
                      provider.updateLanguage(lang.code);
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

  void _showChangePinDialog(BuildContext context) {
    final l10n = context.l10n;
    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            title: Row(
              children: [
                const Icon(Icons.password_rounded, color: AppColors.primaryLight, size: 22),
                const SizedBox(width: 10),
                Text(l10n.changePinDialogTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPinCtrl,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l10n.currentPinFieldLabel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPinCtrl,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l10n.newPinFieldLabel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPinCtrl,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l10n.confirmNewPinFieldLabel),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.cancelButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final cur = currentPinCtrl.text.trim();
                        final n1 = newPinCtrl.text.trim();
                        final n2 = confirmPinCtrl.text.trim();

                        if (n1.length < 4) {
                          setState(() => error = l10n.pinMinCharsError);
                          return;
                        }
                        if (n1 != n2) {
                          setState(() => error = l10n.newPinsDoNotMatchError);
                          return;
                        }

                        final auth = context.read<AuthProvider>();
                        final success = await auth.changePin(currentPin: cur, newPin: n1);
                        if (success) {
                          if (context.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.pinUpdatedSuccess)),
                            );
                          }
                        } else {
                          setState(() => error = l10n.currentPinInvalid);
                        }
                      },
                      child: Text(l10n.saveButton),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final l10n = context.l10n;
    final pwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();
    bool obscurePwd = true;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            title: Row(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: AppColors.successLight, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.exportBackupDialogTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.exportBackupInstructions,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pwdCtrl,
                    obscureText: obscurePwd,
                    decoration: InputDecoration(
                      labelText: l10n.backupPasswordFieldLabel,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePwd ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => obscurePwd = !obscurePwd),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPwdCtrl,
                    obscureText: obscurePwd,
                    decoration: InputDecoration(
                      labelText: l10n.confirmBackupPasswordFieldLabel,
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.cancelButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final pwd = pwdCtrl.text.trim();
                        final confirmPwd = confirmPwdCtrl.text.trim();

                        if (pwd.length < 6) {
                          setState(() => error = l10n.backupPasswordMinCharsError);
                          return;
                        }

                        if (pwd != confirmPwd) {
                          setState(() => error = l10n.backupPasswordsDoNotMatchError);
                          return;
                        }

                        final vault = context.read<VaultProvider>();
                        final backupPayload = await vault.exportBackup(pwd);

                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          _showBackupPayloadDialog(context, backupPayload);
                        }
                      },
                      child: Text(l10n.generateButton),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBackupPayloadDialog(BuildContext context, String payload) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 22),
            const SizedBox(width: 10),
            Text(l10n.backupGeneratedDialogTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.backupCopyWarning,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  payload,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.closeButton),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: payload));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.backupCopiedFeedback)),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(l10n.copyButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final l10n = context.l10n;
    final payloadCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            title: Row(
              children: [
                const Icon(Icons.cloud_download_outlined, color: AppColors.info, size: 22),
                const SizedBox(width: 10),
                Text(l10n.restoreBackupDialogTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: payloadCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.pasteBackupDataLabel,
                      hintText: '{"caveau_backup": ...}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pwdCtrl,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l10n.backupPasswordFieldLabel),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.cancelButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final payload = payloadCtrl.text.trim();
                        final pwd = pwdCtrl.text.trim();

                        if (payload.isEmpty || pwd.isEmpty) {
                          setState(() => error = l10n.fillAllFieldsError);
                          return;
                        }

                        try {
                          final vault = context.read<VaultProvider>();
                          final count = await vault.importBackup(payload, pwd);
                          if (context.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.itemsRestoredSuccess(count))),
                            );
                          }
                        } catch (e) {
                          setState(() => error = l10n.restoreFailedError);
                        }
                      },
                      child: Text(l10n.restoreButton),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWipeDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.wipeAllDataDialogTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.wipeAllDataWarning1,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.wipeAllDataWarning2,
              style: const TextStyle(
                color: AppColors.dangerLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancelButton),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final vault = context.read<VaultProvider>();
                    final auth = context.read<AuthProvider>();
                    await vault.wipeAllData();
                    auth.lock();
                  },
                  child: Text(l10n.wipeAllDataConfirmButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final l10n = context.l10n;
    final settings = settingsProvider.settings;

    final currentMeta = AppLocalizations.supportedLanguages.firstWhere(
      (l) => l.code == settings.languageCode,
      orElse: () => AppLocalizations.supportedLanguages.first,
    );

    return SwipeBackWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsTitle),
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 36,
            ),
            children: [
              // Security Section
              _buildSectionHeader(l10n.sectionAuthAccess),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (authProvider.isBiometricSupported) ...[
                      SwitchListTile(
                        title: Text(l10n.biometricUnlockTileTitle,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(l10n.biometricUnlockTileSubtitle,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        value: settings.biometricsEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => settingsProvider.updateBiometrics(val),
                      ),
                      const Divider(color: AppColors.border),
                    ],
                    ListTile(
                      leading: const Icon(Icons.password_rounded, color: AppColors.primaryLight),
                      title: Text(l10n.changeMasterPinTileTitle,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(l10n.changeMasterPinTileSubtitle,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      onTap: () => _showChangePinDialog(context),
                    ),
                    const Divider(color: AppColors.border),
                    ListTile(
                      leading: const Icon(Icons.timer_outlined, color: AppColors.primaryLight),
                      title: Text(l10n.autoLockTileTitle,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        l10n.formatAutoLock(settings.autoLockSeconds),
                        style: const TextStyle(color: AppColors.primaryLight, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      onTap: () => _showAutoLockPicker(context, settingsProvider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Privacy Section
              _buildSectionHeader(l10n.sectionPrivacyClipboard),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.privacyShieldTileTitle,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        l10n.privacyShieldTileSubtitle,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      value: settings.privacyScreenEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => settingsProvider.updatePrivacyScreen(val),
                    ),
                    const Divider(color: AppColors.border),
                    ListTile(
                      leading: const Icon(Icons.content_cut_rounded, color: AppColors.primaryLight),
                      title: Text(l10n.clearClipboardTileTitle,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        l10n.formatClipboard(settings.clipboardClearSeconds),
                        style: const TextStyle(color: AppColors.primaryLight, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      onTap: () => _showClipboardPicker(context, settingsProvider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Backup Section
              _buildSectionHeader(l10n.sectionBackupRestore),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.successLight.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.successLight),
                      title: Text(l10n.exportBackupTileTitle,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(l10n.exportBackupTileSubtitle,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      onTap: () => _showExportDialog(context),
                    ),
                    const Divider(color: AppColors.border),
                    ListTile(
                      leading: const Icon(Icons.cloud_download_outlined, color: AppColors.info),
                      title: Text(l10n.restoreBackupTileTitle,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(l10n.restoreBackupTileSubtitle,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      onTap: () => _showImportDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Language Section
              _buildSectionHeader(l10n.sectionLanguage),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: Text(currentMeta.flag, style: const TextStyle(fontSize: 22)),
                  title: Text(l10n.languageOptionLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(l10n.languageOptionSubtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentMeta.nativeName,
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                  onTap: () => _showLanguagePicker(context, settingsProvider),
                ),
              ),
              const SizedBox(height: 24),

              // Legal, Privacy & Open Source
              _buildSectionHeader(l10n.sectionLegalAndAbout),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.policy_outlined, color: AppColors.primaryLight),
                      title: Text(l10n.privacyPolicyTileTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(l10n.privacyPolicyTileSubtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 18),
                      onTap: () => _openExternalUrl(AppBrandTerms.privacyPolicyUrl),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.border),
                    ListTile(
                      leading: const Icon(Icons.code_rounded, color: AppColors.info),
                      title: Text(l10n.openSourceTileTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(l10n.openSourceTileSubtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 18),
                      onTap: () => _openExternalUrl(AppBrandTerms.githubRepoUrl),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.border),
                    ListTile(
                      leading: const Icon(Icons.help_outline_rounded, color: AppColors.successLight),
                      title: Text(l10n.backupSecurityGuideTileTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(l10n.backupSecurityGuideTileSubtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      onTap: () => _showSecurityGuideDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Danger Zone
              _buildSectionHeader(l10n.sectionDangerZone),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
                  title: Text(l10n.wipeAllDataTileTitle,
                      style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.wipeAllDataTileSubtitle,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  onTap: () => _showWipeDialog(context),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _showAutoLockPicker(BuildContext context, SettingsProvider provider) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                  child: Text(l10n.autoLockPickerTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                _buildOptionTile(ctx, l10n.autoLockImmediate, 0, provider.settings.autoLockSeconds, (v) {
                  provider.updateAutoLock(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, l10n.autoLock30s, 30, provider.settings.autoLockSeconds, (v) {
                  provider.updateAutoLock(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, l10n.autoLock1m, 60, provider.settings.autoLockSeconds, (v) {
                  provider.updateAutoLock(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, l10n.autoLock5m, 300, provider.settings.autoLockSeconds, (v) {
                  provider.updateAutoLock(v);
                  Navigator.of(ctx).pop();
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClipboardPicker(BuildContext context, SettingsProvider provider) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                  child: Text(l10n.clipboardPickerTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                _buildOptionTile(ctx, l10n.clipboardDisabled, 0, provider.settings.clipboardClearSeconds, (v) {
                  provider.updateClipboardClear(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, l10n.clipboard15s, 15, provider.settings.clipboardClearSeconds, (v) {
                  provider.updateClipboardClear(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, l10n.clipboard30sRecommended, 30, provider.settings.clipboardClearSeconds, (v) {
                  provider.updateClipboardClear(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, l10n.clipboard60s, 60, provider.settings.clipboardClearSeconds, (v) {
                  provider.updateClipboardClear(v);
                  Navigator.of(ctx).pop();
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    String title,
    int value,
    int currentValue,
    ValueChanged<int> onSelect,
  ) {
    final isSelected = value == currentValue;
    return ListTile(
      title: Text(title, style: TextStyle(color: isSelected ? AppColors.primaryLight : AppColors.textPrimary)),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primaryLight) : null,
      onTap: () => onSelect(value),
    );
  }

  Future<void> _openExternalUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showSecurityGuideDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.success, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.backupSecurityGuideDialogTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            l10n.backupSecurityGuideDialogContent,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.45),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.closeButton),
          ),
        ],
      ),
    );
  }
}
