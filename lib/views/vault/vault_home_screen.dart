import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/vault_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vault_provider.dart';
import '../generator/password_generator_screen.dart';
import '../security/security_audit_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/vault_card.dart';
import '../widgets/vault_logo.dart';
import 'vault_detail_screen.dart';
import 'vault_editor_screen.dart';

class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VaultProvider>().loadItems();
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCategoryPicker(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            0,
            16,
            0,
            MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.whatToSaveTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildCategoryAddTile(
                ctx,
                l10n.categoryDisplayName(VaultCategory.login),
                l10n.categoryDescription(VaultCategory.login),
                Icons.vpn_key_rounded,
                AppColors.primary,
                VaultCategory.login,
              ),
              _buildCategoryAddTile(
                ctx,
                l10n.categoryDisplayName(VaultCategory.card),
                l10n.categoryDescription(VaultCategory.card),
                Icons.credit_card_rounded,
                AppColors.success,
                VaultCategory.card,
              ),
              _buildCategoryAddTile(
                ctx,
                l10n.categoryDisplayName(VaultCategory.note),
                l10n.categoryDescription(VaultCategory.note),
                Icons.description_rounded,
                AppColors.warning,
                VaultCategory.note,
              ),
              _buildCategoryAddTile(
                ctx,
                l10n.categoryDisplayName(VaultCategory.identity),
                l10n.categoryDescription(VaultCategory.identity),
                Icons.badge_rounded,
                AppColors.info,
                VaultCategory.identity,
              ),
              _buildCategoryAddTile(
                ctx,
                l10n.categoryDisplayName(VaultCategory.apiKey),
                l10n.categoryDescription(VaultCategory.apiKey),
                Icons.terminal_rounded,
                AppColors.dangerLight,
                VaultCategory.apiKey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryAddTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VaultCategory category,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VaultEditorScreen(preselectedCategory: category),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultProvider = context.watch<VaultProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final l10n = context.l10n;
    final filteredItems = vaultProvider.filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const VaultLogo(size: 28),
            const SizedBox(width: 10),
            Text(l10n.appName),
          ],
        ),
        actions: [
          // Security Audit Icon with badge
          IconButton(
            tooltip: l10n.securityAuditTooltip,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.health_and_safety_outlined),
                if (vaultProvider.weakItems.isNotEmpty ||
                    vaultProvider.reusedPasswordsMap.isNotEmpty)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const SecurityAuditScreen(),
                ),
              );
            },
          ),
          // Password Generator Tool
          IconButton(
            tooltip: l10n.passwordGeneratorTooltip,
            icon: const Icon(Icons.auto_fix_high_rounded),
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const PasswordGeneratorScreen(),
                ),
              );
            },
          ),
          // Settings
          IconButton(
            tooltip: l10n.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          // Lock Vault Button
          IconButton(
            tooltip: l10n.lockNowTooltip,
            icon: const Icon(Icons.lock_outline_rounded, color: AppColors.dangerLight),
            onPressed: () {
              authProvider.lock();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => vaultProvider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            vaultProvider.setSearchQuery('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Horizontal Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(l10n.allCategoryFilter),
                    selected: vaultProvider.selectedCategory == null &&
                        !vaultProvider.favoritesOnly,
                    onSelected: (_) {
                      vaultProvider.setCategory(null);
                      if (vaultProvider.favoritesOnly) {
                        vaultProvider.toggleFavoritesOnly();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: vaultProvider.favoritesOnly
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(l10n.favoritesFilter),
                      ],
                    ),
                    selected: vaultProvider.favoritesOnly,
                    onSelected: (_) => vaultProvider.toggleFavoritesOnly(),
                  ),
                  const SizedBox(width: 8),
                  ...VaultCategory.values.map((cat) {
                    final isSelected = vaultProvider.selectedCategory == cat &&
                        !vaultProvider.favoritesOnly;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(l10n.categoryShortName(cat)),
                        selected: isSelected,
                        onSelected: (_) {
                          if (vaultProvider.favoritesOnly) {
                            vaultProvider.toggleFavoritesOnly();
                          }
                          vaultProvider.setCategory(isSelected ? null : cat);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Items List
            Expanded(
              child: vaultProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredItems.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              32,
                              32,
                              32,
                              MediaQuery.of(context).padding.bottom + 88,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(
                                    Icons.lock_open_rounded,
                                    size: 32,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  vaultProvider.items.isEmpty
                                      ? l10n.emptyVaultTitle
                                      : l10n.noSearchResultsTitle,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  vaultProvider.items.isEmpty
                                      ? l10n.emptyVaultSubtitle
                                      : l10n.noSearchResultsSubtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                if (vaultProvider.items.isEmpty) ...[
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddCategoryPicker(context),
                                    icon: const Icon(Icons.add_rounded),
                                    label: Text(l10n.addItemButton),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            MediaQuery.of(context).padding.bottom + 88,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return VaultCard(
                              item: item,
                              clipboardClearSeconds:
                                  settingsProvider.settings.clipboardClearSeconds,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => VaultDetailScreen(itemId: item.id),
                                  ),
                                );
                              },
                              onToggleFavorite: () {
                                vaultProvider.toggleFavorite(item.id);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryPicker(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newItemFab),
      ),
    );
  }
}
