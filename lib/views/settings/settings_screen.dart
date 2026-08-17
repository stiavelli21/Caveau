import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vault_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showChangePinDialog(BuildContext context) {
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
            title: const Text('Modifica PIN Master', style: TextStyle(fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPinCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'PIN Attuale'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPinCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nuovo PIN (min. 4 car.)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPinCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Conferma Nuovo PIN'),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final cur = currentPinCtrl.text.trim();
                  final n1 = newPinCtrl.text.trim();
                  final n2 = confirmPinCtrl.text.trim();

                  if (n1.length < 4) {
                    setState(() => error = 'Il nuovo PIN deve avere almeno 4 caratteri');
                    return;
                  }
                  if (n1 != n2) {
                    setState(() => error = 'I nuovi PIN non corrispondono');
                    return;
                  }

                  final auth = context.read<AuthProvider>();
                  final success = await auth.changePin(currentPin: cur, newPin: n1);
                  if (success) {
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN Master aggiornato con successo')),
                      );
                    }
                  } else {
                    setState(() => error = 'Il PIN attuale inserito non è corretto');
                  }
                },
                child: const Text('Aggiorna PIN'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final pwdCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Esporta Backup Cifrato', style: TextStyle(fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Imposta una password per cifrare il file di backup. Ti servirà per il ripristino.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pwdCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password Backup'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final pwd = pwdCtrl.text.trim();
                  if (pwd.length < 6) {
                    setState(() => error = 'La password deve avere almeno 6 caratteri');
                    return;
                  }

                  final vault = context.read<VaultProvider>();
                  final backupPayload = await vault.exportBackup(pwd);

                  if (context.mounted) {
                    Navigator.of(ctx).pop();
                    _showBackupPayloadDialog(context, backupPayload);
                  }
                },
                child: const Text('Genera Backup'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBackupPayloadDialog(BuildContext context, String payload) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Backup Generato', style: TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Copia questa stringa crittografata e conservala in un luogo sicuro:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Chiudi'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: payload));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup copiato negli appunti')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copia'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final payloadCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Ripristina da Backup', style: TextStyle(fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: payloadCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Incolla Dati Backup',
                      hintText: '{"caveau_backup": ...}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pwdCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password del Backup'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final payload = payloadCtrl.text.trim();
                  final pwd = pwdCtrl.text.trim();

                  if (payload.isEmpty || pwd.isEmpty) {
                    setState(() => error = 'Compila tutti i campi');
                    return;
                  }

                  try {
                    final vault = context.read<VaultProvider>();
                    final count = await vault.importBackup(payload, pwd);
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ripristinati $count elementi con successo')),
                      );
                    }
                  } catch (e) {
                    setState(() => error = 'Errore ripristino: password errata o dati non validi');
                  }
                },
                child: const Text('Ripristina'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWipeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Distruggi Tutti i Dati?', style: TextStyle(color: AppColors.danger)),
        content: const Text(
          'Questa azione cancellerà permanentemente tutte le password, credenziali e impostazioni. Non potrà essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final vault = context.read<VaultProvider>();
              final auth = context.read<AuthProvider>();
              await vault.wipeAllData();
              auth.lock();
            },
            child: const Text('Conferma Cancellazione Totale'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final settings = settingsProvider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni di Sicurezza'),
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
          _buildSectionHeader('AUTENTICAZIONE & ACCESSO'),
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
                    title: const Text('Sblocco Biometrico (Face ID / Impronta)',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text('Richiedi biometria per sbloccare il caveau',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    value: settings.biometricsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => settingsProvider.updateBiometrics(val),
                  ),
                  const Divider(color: AppColors.border),
                ],
                ListTile(
                  leading: const Icon(Icons.password_rounded, color: AppColors.primaryLight),
                  title: const Text('Modifica PIN Master',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Cambia il codice di emergenza e sblocco',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => _showChangePinDialog(context),
                ),
                const Divider(color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.timer_outlined, color: AppColors.primaryLight),
                  title: const Text('Blocco Automatico',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    _formatAutoLockLabel(settings.autoLockSeconds),
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
          _buildSectionHeader('PRIVACY & APPUNTI'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Privacy Shield Multitasking',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text(
                    'Sfoca e nasconde l\'anteprima dell\'app nel selettore app',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  value: settings.privacyScreenEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => settingsProvider.updatePrivacyScreen(val),
                ),
                const Divider(color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.content_cut_rounded, color: AppColors.primaryLight),
                  title: const Text('Svuota Appunti Automaticamente',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    _formatClipboardLabel(settings.clipboardClearSeconds),
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
          _buildSectionHeader('BACKUP & RIPRISTINO'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.successLight),
                  title: const Text('Esporta Backup Cifrato',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Salva una copia protetta da password',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => _showExportDialog(context),
                ),
                const Divider(color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: AppColors.info),
                  title: const Text('Ripristina da Backup',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Importa le tue credenziali cifrate',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => _showImportDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionHeader('ZONA DI PERICOLO'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
              title: const Text('Cancella e Azzera Caveau',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
              subtitle: const Text('Rimuove tutti gli elementi e resetta le chiavi',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () => _showWipeDialog(context),
            ),
          ),
          const SizedBox(height: 32),
        ],
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

  String _formatAutoLockLabel(int seconds) {
    if (seconds == 0) return 'Immediatamente all\'uscita';
    if (seconds == 30) return 'Dopo 30 secondi in background';
    if (seconds == 60) return 'Dopo 1 minuto';
    if (seconds == 300) return 'Dopo 5 minuti';
    return '$seconds secondi';
  }

  String _formatClipboardLabel(int seconds) {
    if (seconds == 0) return 'Disabilitato';
    return 'Dopo $seconds secondi';
  }

  void _showAutoLockPicker(BuildContext context, SettingsProvider provider) {
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Timeout Blocco Automatico',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                _buildOptionTile(ctx, 'Immediato', 0, provider.settings.autoLockSeconds, (v) {
                  provider.updateAutoLock(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, '30 secondi', 30, provider.settings.autoLockSeconds, (v) {
                  provider.updateAutoLock(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, '1 minuto', 60, provider.settings.autoLockSeconds, (v) {
                  provider.updateAutoLock(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, '5 minuti', 300, provider.settings.autoLockSeconds, (v) {
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Pulizia Automatica Appunti',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                _buildOptionTile(ctx, 'Disabilitato', 0, provider.settings.clipboardClearSeconds, (v) {
                  provider.updateClipboardClear(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, '15 secondi', 15, provider.settings.clipboardClearSeconds, (v) {
                  provider.updateClipboardClear(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, '30 secondi (Consigliato)', 30, provider.settings.clipboardClearSeconds, (v) {
                  provider.updateClipboardClear(v);
                  Navigator.of(ctx).pop();
                }),
                _buildOptionTile(ctx, '60 secondi', 60, provider.settings.clipboardClearSeconds, (v) {
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
}
