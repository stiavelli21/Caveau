import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/vault_item.dart';
import '../../providers/vault_provider.dart';
import '../vault/vault_editor_screen.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/swipe_back_wrapper.dart';

/// Security health dashboard analyzing stored credentials for vulnerabilities.
/// 
/// Highlights:
/// - Overall security score calculated from entropy metrics and password reuse penalties
/// - Count of total items, weak passwords, and duplicated credentials
/// - Direct remediation action buttons allowing immediate password updates via [VaultEditorScreen]
/// - Responsive 2-column desktop layout vs standard single-column mobile layout
class SecurityAuditScreen extends StatelessWidget {
  const SecurityAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultProvider = context.watch<VaultProvider>();
    final l10n = context.l10n;
    final isDesktop = isDesktopView(context);

    final score = vaultProvider.securityScore;
    final weakItems = vaultProvider.weakItems;
    final reusedMap = vaultProvider.reusedPasswordsMap;
    final totalItems = vaultProvider.items.length;

    // Determine visual status color and description based on audit score
    Color scoreColor;
    String scoreLabel = l10n.securityScoreLabel(score);
    if (score >= 85) {
      scoreColor = AppColors.success;
    } else if (score >= 60) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.danger;
    }

    return SwipeBackWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.securityAuditTitle),
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
                  maxWidth: isDesktop ? 960 : double.infinity,
                ),
                child: isDesktop
                    ? _buildDesktopLayout(
                        context,
                        l10n,
                        score,
                        scoreColor,
                        scoreLabel,
                        totalItems,
                        weakItems,
                        reusedMap,
                      )
                    : _buildMobileLayout(
                        context,
                        l10n,
                        score,
                        scoreColor,
                        scoreLabel,
                        totalItems,
                        weakItems,
                        reusedMap,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations l10n,
    int score,
    Color scoreColor,
    String scoreLabel,
    int totalItems,
    List<VaultItem> weakItems,
    Map<String, List<VaultItem>> reusedMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGaugeCard(score, scoreColor, scoreLabel, l10n),
        const SizedBox(height: 20),
        _buildStatsRow(l10n, totalItems, weakItems, reusedMap),
        const SizedBox(height: 28),
        _buildIssuesSection(context, l10n, weakItems, reusedMap),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppLocalizations l10n,
    int score,
    Color scoreColor,
    String scoreLabel,
    int totalItems,
    List<VaultItem> weakItems,
    Map<String, List<VaultItem>> reusedMap,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Score Gauge & Metrics Summary
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGaugeCard(score, scoreColor, scoreLabel, l10n),
              const SizedBox(height: 20),
              _buildStatsRow(l10n, totalItems, weakItems, reusedMap),
            ],
          ),
        ),
        const SizedBox(width: 28),

        // Right Column: Vulnerability Issues List
        Expanded(
          flex: 6,
          child: _buildIssuesSection(context, l10n, weakItems, reusedMap),
        ),
      ],
    );
  }

  Widget _buildGaugeCard(
    int score,
    Color scoreColor,
    String scoreLabel,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: AppColors.surfaceHighlight,
                  color: scoreColor,
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            scoreLabel,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.auditDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    AppLocalizations l10n,
    int totalItems,
    List<VaultItem> weakItems,
    Map<String, List<VaultItem>> reusedMap,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildStatCard(
              title: l10n.totalItemsStat,
              value: '$totalItems',
              icon: Icons.inventory_2_outlined,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: l10n.weakPasswordsStat,
              value: '${weakItems.length}',
              icon: Icons.warning_amber_rounded,
              color: weakItems.isNotEmpty ? AppColors.danger : AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: l10n.reusedPasswordsStat,
              value: '${reusedMap.length}',
              icon: Icons.copy_rounded,
              color: reusedMap.isNotEmpty ? AppColors.warning : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesSection(
    BuildContext context,
    AppLocalizations l10n,
    List<VaultItem> weakItems,
    Map<String, List<VaultItem>> reusedMap,
  ) {
    if (weakItems.isEmpty && reusedMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.verified_user_rounded,
                color: AppColors.success, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.allPasswordsHealthy,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.allPasswordsHealthySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Weak and Short Passwords Section
        if (weakItems.isNotEmpty) ...[
          Text(
            l10n.weakPasswordsSection,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...weakItems.map((item) => _buildItemAuditTile(
                context,
                item,
                l10n.weakPasswordTileLabel,
                fixLabel: l10n.fixButton,
              )),
          const SizedBox(height: 24),
        ],

        // Reused / Duplicated Passwords Section
        if (reusedMap.isNotEmpty) ...[
          Text(
            l10n.reusedPasswordsSection,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...reusedMap.entries.expand((entry) => entry.value).map(
                (item) => _buildItemAuditTile(
                  context,
                  item,
                  l10n.reusedPasswordTileLabel(reusedMap[item.password]?.length ?? 2),
                  isWarning: true,
                  fixLabel: l10n.fixButton,
                ),
              ),
        ],
      ],
    );
  }

  /// Helper widget rendering a single summary statistic card.
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            softWrap: true,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Helper rendering an individual vulnerable vault item tile with shortcut to edit.
  Widget _buildItemAuditTile(
    BuildContext context,
    VaultItem item,
    String issueLabel, {
    bool isWarning = false,
    required String fixLabel,
  }) {
    final alertColor = isWarning ? AppColors.warning : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: alertColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isWarning ? Icons.content_copy_rounded : Icons.lock_open_rounded,
              color: alertColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  issueLabel,
                  style: TextStyle(
                    color: alertColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VaultEditorScreen(initialItem: item),
                ),
              );
            },
            child: Text(
              fixLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
