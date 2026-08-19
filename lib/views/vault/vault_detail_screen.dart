import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/clipboard_service.dart';
import '../../models/vault_item.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vault_provider.dart';
import '../widgets/password_strength_bar.dart';
import 'vault_editor_screen.dart';

class VaultDetailScreen extends StatefulWidget {
  final String itemId;

  const VaultDetailScreen({
    super.key,
    required this.itemId,
  });

  @override
  State<VaultDetailScreen> createState() => _VaultDetailScreenState();
}

class _VaultDetailScreenState extends State<VaultDetailScreen> {
  final Map<String, bool> _obscuredMap = {};

  bool _isObscured(String key) => _obscuredMap[key] ?? true;

  void _toggleObscured(String key) {
    setState(() {
      _obscuredMap[key] = !(_obscuredMap[key] ?? true);
    });
  }

  void _copyField(String label, String value, int autoClearSeconds) {
    final l10n = context.l10n;
    ClipboardService.copyWithAutoClear(value, autoClearSeconds: autoClearSeconds);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                autoClearSeconds > 0
                    ? l10n.fieldCopiedAutoClear(label, autoClearSeconds)
                    : l10n.fieldCopied(label),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
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

  void _delete(VaultItem item) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
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
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.deleteItemTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.deleteItemConfirmMessage(item.title),
          style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
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
                  onPressed: () => Navigator.of(ctx).pop(false),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.deleteButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<VaultProvider>().deleteItem(item.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  IconData _getCategoryIcon(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return Icons.vpn_key_rounded;
      case VaultCategory.card:
        return Icons.credit_card_rounded;
      case VaultCategory.note:
        return Icons.description_rounded;
      case VaultCategory.identity:
        return Icons.badge_rounded;
      case VaultCategory.apiKey:
        return Icons.terminal_rounded;
    }
  }

  Color _getCategoryColor(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return AppColors.primary;
      case VaultCategory.card:
        return AppColors.success;
      case VaultCategory.note:
        return AppColors.warning;
      case VaultCategory.identity:
        return AppColors.info;
      case VaultCategory.apiKey:
        return AppColors.dangerLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultProvider = context.watch<VaultProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final l10n = context.l10n;
    final autoClear = settingsProvider.settings.clipboardClearSeconds;

    final item = vaultProvider.items.firstWhere(
      (i) => i.id == widget.itemId,
      orElse: () => VaultItem(
        id: 'deleted',
        title: l10n.itemDeletedFallback,
        category: VaultCategory.login,
      ),
    );

    if (item.id == 'deleted') {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.itemNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        actions: [
          IconButton(
            icon: Icon(
              item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: item.isFavorite ? AppColors.warning : AppColors.textSecondary,
            ),
            onPressed: () => vaultProvider.toggleFavorite(item.id),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VaultEditorScreen(initialItem: item),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.dangerLight),
            onPressed: () => _delete(item),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).padding.bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(item.category).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getCategoryColor(item.category).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        _getCategoryIcon(item.category),
                        color: _getCategoryColor(item.category),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.categoryDisplayName(item.category),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Card Mockup representation if Category is Card
            if (item.category == VaultCategory.card) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.nfc_rounded, color: Colors.white70, size: 28),
                        Icon(Icons.credit_card_rounded, color: Colors.white, size: 32),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isObscured('card_num')
                          ? (item.cardNumber != null && item.cardNumber!.length >= 4
                              ? '•••• •••• •••• ${item.cardNumber!.substring(item.cardNumber!.length - 4)}'
                              : '•••• •••• •••• ••••')
                          : (item.cardNumber ?? '---- ---- ---- ----'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.cardHolderCardMockup,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (item.cardHolder ?? l10n.cardHolderCardMockup).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.cardExpiryCardMockup,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.cardExpiry ?? '--/--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Sensitive Fields List
            if (item.username != null && item.username!.isNotEmpty)
              _buildFieldTile(
                title: l10n.usernameLabel,
                value: item.username!,
                icon: Icons.person_outline_rounded,
                onCopy: () => _copyField(l10n.usernameLabel, item.username!, autoClear),
              ),

            if (item.password != null && item.password!.isNotEmpty) ...[
              _buildFieldTile(
                title: l10n.passwordLabel,
                value: item.password!,
                icon: Icons.lock_outline_rounded,
                isSecret: true,
                isObscured: _isObscured('password'),
                onToggleObscure: () => _toggleObscured('password'),
                onCopy: () => _copyField(l10n.passwordLabel, item.password!, autoClear),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: PasswordStrengthBar(password: item.password!),
              ),
              const SizedBox(height: 12),
            ],

            if (item.websiteUrl != null && item.websiteUrl!.isNotEmpty)
              _buildFieldTile(
                title: l10n.websiteLabel,
                value: item.websiteUrl!,
                icon: Icons.link_rounded,
                onCopy: () => _copyField(l10n.websiteLabel, item.websiteUrl!, 0),
              ),

            if (item.cardNumber != null && item.cardNumber!.isNotEmpty)
              _buildFieldTile(
                title: l10n.cardNumberLabel,
                value: item.cardNumber!,
                icon: Icons.credit_card_rounded,
                isSecret: true,
                isObscured: _isObscured('card_num'),
                onToggleObscure: () => _toggleObscured('card_num'),
                onCopy: () => _copyField(l10n.cardNumberLabel, item.cardNumber!, autoClear),
              ),

            if (item.cardCvv != null && item.cardCvv!.isNotEmpty)
              _buildFieldTile(
                title: l10n.cardCvvLabel,
                value: item.cardCvv!,
                icon: Icons.security_rounded,
                isSecret: true,
                isObscured: _isObscured('card_cvv'),
                onToggleObscure: () => _toggleObscured('card_cvv'),
                onCopy: () => _copyField(l10n.cardCvvLabel, item.cardCvv!, autoClear),
              ),

            if (item.cardPin != null && item.cardPin!.isNotEmpty)
              _buildFieldTile(
                title: l10n.cardPinLabel,
                value: item.cardPin!,
                icon: Icons.pin_rounded,
                isSecret: true,
                isObscured: _isObscured('card_pin'),
                onToggleObscure: () => _toggleObscured('card_pin'),
                onCopy: () => _copyField(l10n.cardPinLabel, item.cardPin!, autoClear),
              ),

            if (item.email != null && item.email!.isNotEmpty)
              _buildFieldTile(
                title: l10n.emailLabel,
                value: item.email!,
                icon: Icons.email_outlined,
                onCopy: () => _copyField(l10n.emailLabel, item.email!, 0),
              ),

            if (item.phone != null && item.phone!.isNotEmpty)
              _buildFieldTile(
                title: l10n.phoneLabel,
                value: item.phone!,
                icon: Icons.phone_outlined,
                onCopy: () => _copyField(l10n.phoneLabel, item.phone!, 0),
              ),

            if (item.idNumber != null && item.idNumber!.isNotEmpty)
              _buildFieldTile(
                title: l10n.idNumberLabel,
                value: item.idNumber!,
                icon: Icons.badge_outlined,
                onCopy: () => _copyField(l10n.idNumberLabel, item.idNumber!, 0),
              ),

            if (item.apiKeySecret != null && item.apiKeySecret!.isNotEmpty)
              _buildFieldTile(
                title: l10n.apiKeySecretLabel,
                value: item.apiKeySecret!,
                icon: Icons.vpn_key_outlined,
                isSecret: true,
                isObscured: _isObscured('api_key'),
                onToggleObscure: () => _toggleObscured('api_key'),
                onCopy: () => _copyField(l10n.apiKeySecretLabel, item.apiKeySecret!, autoClear),
              ),

            // Custom fields
            for (final cf in item.customFields)
              _buildFieldTile(
                title: cf.label,
                value: cf.value,
                icon: Icons.extension_outlined,
                isSecret: cf.isSecret,
                isObscured: cf.isSecret ? _isObscured(cf.id) : false,
                onToggleObscure: cf.isSecret ? () => _toggleObscured(cf.id) : null,
                onCopy: () => _copyField(cf.label, cf.value, cf.isSecret ? autoClear : 0),
              ),

            // Notes
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
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
                          item.category == VaultCategory.note
                              ? l10n.notesLabel
                              : l10n.notesLabel,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          onPressed: () => _copyField(l10n.notesLabel, item.notes!, autoClear),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      item.notes!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (item.category == VaultCategory.note) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    '- - -',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFieldTile({
    required String title,
    required String value,
    required IconData icon,
    bool isSecret = false,
    bool isObscured = false,
    VoidCallback? onToggleObscure,
    required VoidCallback onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  isSecret && isObscured ? '••••••••••••' : value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: isSecret && !isObscured ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
          if (isSecret && onToggleObscure != null)
            IconButton(
              icon: Icon(
                isObscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          IconButton(
            icon: const Icon(Icons.copy_rounded,
                color: AppColors.textSecondary, size: 20),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
