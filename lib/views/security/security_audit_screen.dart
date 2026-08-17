import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/vault_item.dart';
import '../../providers/vault_provider.dart';
import '../vault/vault_editor_screen.dart';

class SecurityAuditScreen extends StatelessWidget {
  const SecurityAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultProvider = context.watch<VaultProvider>();
    final score = vaultProvider.securityScore;
    final weakItems = vaultProvider.weakItems;
    final reusedMap = vaultProvider.reusedPasswordsMap;
    final totalItems = vaultProvider.items.length;

    Color scoreColor;
    String scoreLabel;
    if (score >= 85) {
      scoreColor = AppColors.success;
      scoreLabel = 'Ottimo Stato di Sicurezza';
    } else if (score >= 60) {
      scoreColor = AppColors.warning;
      scoreLabel = 'Sicurezza Moderata';
    } else {
      scoreColor = AppColors.danger;
      scoreLabel = 'Attenzione: Sicurezza a Rischio';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Audit'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).padding.bottom + 36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score Banner
            Container(
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
                    'Analisi basata su robustezza, entropia e riutilizzo delle password salvate.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Elementi Totali',
                    value: '$totalItems',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Password Deboli',
                    value: '${weakItems.length}',
                    icon: Icons.warning_amber_rounded,
                    color: weakItems.isNotEmpty ? AppColors.danger : AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Riutilizzate',
                    value: '${reusedMap.length}',
                    icon: Icons.copy_rounded,
                    color: reusedMap.isNotEmpty ? AppColors.warning : AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Weak passwords list
            if (weakItems.isNotEmpty) ...[
              const Text(
                'Password Deboli o Troppo Brevi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...weakItems.map((item) => _buildItemAuditTile(context, item, 'Password debole')),
              const SizedBox(height: 24),
            ],

            // Reused passwords list
            if (reusedMap.isNotEmpty) ...[
              const Text(
                'Password Riutilizzate in più account',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Usare la stessa password per account multipli è un grave rischio di sicurezza.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ...reusedMap.entries.expand((entry) => entry.value).map(
                    (item) => _buildItemAuditTile(
                      context,
                      item,
                      'Password condivisa con altri account',
                      isWarning: true,
                    ),
                  ),
              const SizedBox(height: 24),
            ],

            if (weakItems.isEmpty && reusedMap.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        color: AppColors.success, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Tutte le tue password sono uniche e robuste!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemAuditTile(
    BuildContext context,
    VaultItem item,
    String issueReason, {
    bool isWarning = false,
  }) {
    final color = isWarning ? AppColors.warning : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  issueReason,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              backgroundColor: AppColors.surfaceElevated,
              foregroundColor: AppColors.primaryLight,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VaultEditorScreen(initialItem: item),
                ),
              );
            },
            child: const Text('Aggiorna', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
