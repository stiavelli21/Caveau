import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/vault_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../generator/password_generator_screen.dart';
import '../security/security_audit_screen.dart';
import '../settings/settings_screen.dart';
import 'language_selector_button.dart';
import 'vault_logo.dart';

/// Navigation and category filtering sidebar designed specifically for desktop viewports.
class DesktopSidebar extends StatelessWidget {
  /// Custom width for the sidebar. Defaults to 320.0.
  final double width;

  const DesktopSidebar({
    super.key,
    this.width = 320.0,
  });

  @override
  Widget build(BuildContext context) {
    final vaultProvider = context.watch<VaultProvider>();
    final authProvider = context.watch<AuthProvider>();
    final l10n = context.l10n;

    final selectedCategory = vaultProvider.selectedCategory;
    final isFavoritesOnly = vaultProvider.favoritesOnly;
    final isAllSelected = selectedCategory == null && !isFavoritesOnly;

    final items = vaultProvider.items;
    final totalCount = items.length;
    final favoritesCount = items.where((i) => i.isFavorite).length;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App Header & Branding
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                const VaultLogo(size: 32, showGlow: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.appName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const LanguageSelectorButton(),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Categories & Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                // "All Items" Navigation Tile
                _buildNavTile(
                  icon: Icons.all_inbox_rounded,
                  title: l10n.allCategoryFilter,
                  count: totalCount,
                  isSelected: isAllSelected,
                  accentColor: AppColors.primary,
                  onTap: () {
                    vaultProvider.setCategory(null);
                    if (vaultProvider.favoritesOnly) {
                      vaultProvider.toggleFavoritesOnly();
                    }
                  },
                ),
                const SizedBox(height: 4),

                // "Favorites" Navigation Tile
                _buildNavTile(
                  icon: Icons.star_rounded,
                  title: l10n.favoritesFilter,
                  count: favoritesCount,
                  isSelected: isFavoritesOnly,
                  accentColor: AppColors.warning,
                  onTap: () {
                    if (!vaultProvider.favoritesOnly) {
                      vaultProvider.toggleFavoritesOnly();
                    }
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Divider(height: 1, color: AppColors.border),
                ),

                // Category Navigation Tiles
                ...VaultCategory.values.map((cat) {
                  final catCount = items.where((i) => i.category == cat).length;
                  final isSelected = selectedCategory == cat && !isFavoritesOnly;
                  final (icon, color) = _getCategoryDetails(cat);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildNavTile(
                      icon: icon,
                      title: l10n.categoryDisplayName(cat),
                      count: catCount,
                      isSelected: isSelected,
                      accentColor: color,
                      onTap: () {
                        if (vaultProvider.favoritesOnly) {
                          vaultProvider.toggleFavoritesOnly();
                        }
                        vaultProvider.setCategory(cat);
                      },
                    ),
                  );
                }),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Divider(height: 1, color: AppColors.border),
                ),

                // Security Audit Shortcut Tile
                _buildActionTile(
                  icon: Icons.health_and_safety_outlined,
                  title: l10n.securityAuditTitle,
                  badgeText: (vaultProvider.weakItems.isNotEmpty ||
                          vaultProvider.reusedPasswordsMap.isNotEmpty)
                      ? '!'
                      : null,
                  badgeColor: AppColors.danger,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const SecurityAuditScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),

                // Password Generator Shortcut Tile
                _buildActionTile(
                  icon: Icons.auto_fix_high_rounded,
                  title: l10n.passwordGeneratorTitle,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const PasswordGeneratorScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),

                // Settings Shortcut Tile
                _buildActionTile(
                  icon: Icons.settings_outlined,
                  title: l10n.settingsTitle,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom Lock Vault Button
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35)),
                backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.lock_outline_rounded, color: AppColors.dangerLight, size: 18),
              label: Text(
                l10n.lockVaultAction,
                style: const TextStyle(
                  color: AppColors.dangerLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              onPressed: () => authProvider.lock(),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper rendering an individual category/filter navigation tile.
  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required int count,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: accentColor.withValues(alpha: 0.35))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? accentColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.25)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? accentColor : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper rendering action shortcut tiles (Audit, Generator, Settings).
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns icon and theme color for each category.
  (IconData, Color) _getCategoryDetails(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return (Icons.vpn_key_rounded, AppColors.primary);
      case VaultCategory.card:
        return (Icons.credit_card_rounded, AppColors.success);
      case VaultCategory.note:
        return (Icons.description_rounded, AppColors.warning);
      case VaultCategory.identity:
        return (Icons.badge_rounded, AppColors.info);
      case VaultCategory.apiKey:
        return (Icons.terminal_rounded, AppColors.dangerLight);
    }
  }
}
