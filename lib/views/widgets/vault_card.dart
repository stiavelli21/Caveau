import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/clipboard_service.dart';
import '../../models/vault_item.dart';
import '../../providers/vault_provider.dart';
import '../vault/vault_editor_screen.dart';

enum VaultCardAction { copy, edit, delete }

class VaultCard extends StatelessWidget {
  final VaultItem item;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int clipboardClearSeconds;

  const VaultCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onToggleFavorite,
    this.onEdit,
    this.onDelete,
    this.clipboardClearSeconds = 30,
  });

  IconData _getCategoryIcon() {
    switch (item.category) {
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

  Color _getCategoryColor() {
    switch (item.category) {
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

  String _getSubtitle(AppLocalizations l10n) {
    switch (item.category) {
      case VaultCategory.login:
        return item.username ?? item.websiteUrl ?? l10n.noUsername;
      case VaultCategory.card:
        if (item.cardNumber != null && item.cardNumber!.length >= 4) {
          return '•••• ${item.cardNumber!.substring(item.cardNumber!.length - 4)}';
        }
        return item.cardHolder ?? l10n.paymentCardSubtitle;
      case VaultCategory.note:
        if (item.notes != null && item.notes!.isNotEmpty) {
          final firstLine = item.notes!.split('\n').first;
          return firstLine.length > 35 ? '${firstLine.substring(0, 35)}...' : firstLine;
        }
        return l10n.encryptedNoteSubtitle;
      case VaultCategory.identity:
        return item.fullNameOrEmail;
      case VaultCategory.apiKey:
        return l10n.encryptedKeySubtitle;
    }
  }

  String? _getQuickCopyValue() {
    switch (item.category) {
      case VaultCategory.login:
        return item.password;
      case VaultCategory.card:
        return item.cardNumber;
      case VaultCategory.note:
        return item.notes;
      case VaultCategory.identity:
        return item.idNumber ?? item.email;
      case VaultCategory.apiKey:
        return item.apiKeySecret;
    }
  }

  String _getCopyActionTitle(AppLocalizations l10n) {
    switch (item.category) {
      case VaultCategory.login:
        return l10n.copyPassword;
      case VaultCategory.card:
        return l10n.copyCardNumber;
      case VaultCategory.note:
        return l10n.copyNotes;
      case VaultCategory.identity:
        return l10n.copyIdentity;
      case VaultCategory.apiKey:
        return l10n.copyApiKey;
    }
  }

  String _getCopyFeedbackLabel(AppLocalizations l10n) {
    switch (item.category) {
      case VaultCategory.login:
        return l10n.passwordCopiedFeedback;
      case VaultCategory.card:
        return l10n.cardNumberCopiedFeedback;
      case VaultCategory.note:
        return l10n.noteTextCopiedFeedback;
      case VaultCategory.identity:
        return l10n.identityCopiedFeedback;
      case VaultCategory.apiKey:
        return l10n.apiKeyCopiedFeedback;
    }
  }

  void _copy(BuildContext context, String value) {
    final l10n = context.l10n;
    ClipboardService.copyWithAutoClear(value, autoClearSeconds: clipboardClearSeconds);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                clipboardClearSeconds > 0
                    ? '${_getCopyFeedbackLabel(l10n)} (auto-clear in ${clipboardClearSeconds}s)'
                    : _getCopyFeedbackLabel(l10n),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
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

    if (confirmed == true && context.mounted) {
      if (onDelete != null) {
        onDelete!();
      } else {
        await context.read<VaultProvider>().deleteItem(item.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, color: AppColors.dangerLight, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '"${item.title}" - ${l10n.deleteButton}',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor();
    final quickCopyVal = _getQuickCopyValue();
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: catColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: catColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSubtitle(l10n),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Favorite Star
                IconButton(
                  icon: Icon(
                    item.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 22,
                    color: item.isFavorite
                        ? AppColors.warning
                        : AppColors.textMuted,
                  ),
                  tooltip: item.isFavorite ? 'Favorites' : 'Favorites',
                  onPressed: onToggleFavorite,
                ),
                // 3-dots Menu for Copy, Edit, Delete
                PopupMenuButton<VaultCardAction>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Options',
                  color: AppColors.surfaceElevated,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case VaultCardAction.copy:
                        if (quickCopyVal != null && quickCopyVal.isNotEmpty) {
                          _copy(context, quickCopyVal);
                        }
                        break;
                      case VaultCardAction.edit:
                        if (onEdit != null) {
                          onEdit!();
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VaultEditorScreen(initialItem: item),
                            ),
                          );
                        }
                        break;
                      case VaultCardAction.delete:
                        _confirmDelete(context);
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (quickCopyVal != null && quickCopyVal.isNotEmpty)
                      PopupMenuItem(
                        value: VaultCardAction.copy,
                        child: Row(
                          children: [
                            const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryLight),
                            const SizedBox(width: 12),
                            Text(
                              _getCopyActionTitle(l10n),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: VaultCardAction.edit,
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                          const SizedBox(width: 12),
                          Text(
                            l10n.editButton,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: VaultCardAction.delete,
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.dangerLight),
                          const SizedBox(width: 12),
                          Text(
                            l10n.deleteButton,
                            style: const TextStyle(
                              color: AppColors.dangerLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension VaultItemExtension on VaultItem {
  String get fullNameOrEmail {
    if (email != null && email!.isNotEmpty) return email!;
    if (phone != null && phone!.isNotEmpty) return phone!;
    if (idNumber != null && idNumber!.isNotEmpty) return idNumber!;
    return 'Identity Data';
  }
}
