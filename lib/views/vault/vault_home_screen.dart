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
import '../widgets/desktop_sidebar.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/vault_card.dart';
import '../widgets/vault_logo.dart';
import 'vault_detail_screen.dart';
import 'vault_editor_screen.dart';

/// Primary dashboard screen displayed once authentication is successful.
/// 
/// Supports:
/// - **Mobile Layout**: Standard portrait single-column list with bottom sheets and full-screen push navigation.
/// - **Desktop / Horizontal Widescreen Layout**: Multi-pane split-view layout featuring a category navigation sidebar,
///   a middle searchable master list, and a real-time detail pane with interactive controls.
class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    // Load decrypted items and persistent settings into memory upon initial load
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

  /// Displays modal bottom sheet allowing the user to select which category of item to create.
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

  /// Helper rendering an individual category option tile in the creation picker.
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
        ).then((_) {
          if (mounted) setState(() {});
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: (ctx) => _buildMobileLayout(ctx),
      desktop: (ctx) => _buildDesktopLayout(ctx),
    );
  }

  // ===========================================================================
  // MOBILE VIEWPORT LAYOUT (Preserved 1:1)
  // ===========================================================================

  Widget _buildMobileLayout(BuildContext context) {
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
          // Security Audit Icon with vulnerability warning badge
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
          // Dedicated Password Generator Tool Shortcut
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
          // App & Security Settings Screen
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
          // Instant Lock Vault Action
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
            // Interactive Search Bar
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

            // Horizontal Filter Chips (All, Favorites, Category Filters)
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

            // Decrypted Items List & Fallback Empty States
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
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newItemFab,
        onPressed: () => _showAddCategoryPicker(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP HORIZONTAL SPLIT-VIEW LAYOUT
  // ===========================================================================

  Widget _buildDesktopLayout(BuildContext context) {
    final vaultProvider = context.watch<VaultProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final l10n = context.l10n;
    final filteredItems = vaultProvider.filteredItems;

    // Check if the selected item still exists in the vault
    final isSelectedItemValid = _selectedItemId != null &&
        vaultProvider.items.any((i) => i.id == _selectedItemId);

    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth >= 1600
        ? 340.0
        : (screenWidth >= 1200 ? 320.0 : 290.0);
    final masterWidth = screenWidth >= 1600
        ? 520.0
        : (screenWidth >= 1200 ? 460.0 : 400.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Navigation & Category Filter Sidebar
          DesktopSidebar(width: sidebarWidth),

          // Middle Master Column: Search & Item List
          SizedBox(
            width: masterWidth,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                children: [
                  // Top Search & Add Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => vaultProvider.setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText: l10n.searchHint,
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        vaultProvider.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _showAddCategoryPicker(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(l10n.addNewItemDesktop),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.border),

                  // Master List
                  Expanded(
                    child: vaultProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredItems.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.search_off_rounded,
                                        size: 40,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        vaultProvider.items.isEmpty
                                            ? l10n.emptyVaultTitle
                                            : l10n.noSearchResultsTitle,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        vaultProvider.items.isEmpty
                                            ? l10n.emptyVaultSubtitle
                                            : l10n.noSearchResultsSubtitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  final isSelected = item.id == _selectedItemId;
                                  return VaultCard(
                                    item: item,
                                    isSelected: isSelected,
                                    clipboardClearSeconds:
                                        settingsProvider.settings.clipboardClearSeconds,
                                    onTap: () {
                                      setState(() {
                                        _selectedItemId = item.id;
                                      });
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
          ),

          // Right Detail Column: Selected Item Detail Pane or Empty Placeholder
          Expanded(
            child: isSelectedItemValid
                ? VaultDetailView(
                    key: ValueKey(_selectedItemId),
                    itemId: _selectedItemId!,
                    isPane: true,
                    onDeleted: () {
                      setState(() {
                        _selectedItemId = null;
                      });
                    },
                    onEdited: () {
                      setState(() {});
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.noItemSelectedPrompt,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.selectItemToViewDetails,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddCategoryPicker(context),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l10n.addItemButton),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
