import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/services/admin_service.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/header_section.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminService>(
      builder: (context, adminService, _) {
        final stats = adminService.statistics;
        return SingleChildScrollView(
          child: Column(
            children: [
              HeaderSection(
                title: 'Dashboard Admin',
                subtitle: 'Vue d\'ensemble de la plateforme DRAMUS',
              ),
              Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatisticsGrid(context, stats),
                    SizedBox(height: AppSpacing.xxl),
                    _buildChartsSection(context, adminService),
                    SizedBox(height: AppSpacing.xxl),
                    _buildManagementSection(context),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsGrid(BuildContext context, AdminStatistics stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.lg,
      mainAxisSpacing: AppSpacing.lg,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        _buildStatCard(
          context,
          title: 'Annonces totales',
          value: '${stats.totalListings}',
          icon: Icons.apartment,
          color: DramusColors.primaryTeal,
        ),
        _buildStatCard(
          context,
          title: 'Utilisateurs',
          value: '${stats.totalUsers}',
          icon: Icons.people,
          color: DramusColors.deepTeal,
        ),
        _buildStatCard(
          context,
          title: 'Agents',
          value: '${stats.totalAgents}',
          icon: Icons.person_outline,
          color: DramusColors.saleGreen,
        ),
        _buildStatCard(
          context,
          title: 'Agences',
          value: '${stats.totalAgencies}',
          icon: Icons.business,
          color: DramusColors.premiumYellow,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DramusColors.secondaryText,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, AdminService adminService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyse',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.lg),
        _buildSimpleChart(
          context,
          title: 'Ventes mensuelles',
          data: adminService.getSalesData(),
          color: DramusColors.saleGreen,
        ),
        SizedBox(height: AppSpacing.xxl),
        _buildSimpleChart(
          context,
          title: 'Distribution par type',
          data: adminService
              .getPropertyTypeDistribution()
              .map((e) => MapEntry(e.key, e.value.toInt()))
              .toList(),
          color: DramusColors.primaryTeal,
        ),
        SizedBox(height: AppSpacing.xxl),
        _buildSimpleChart(
          context,
          title: 'Utilisateurs par région',
          data: adminService.getUserActivity(),
          color: DramusColors.deepTeal,
        ),
      ],
    );
  }

  Widget _buildSimpleChart(
    BuildContext context, {
    required String title,
    required List<MapEntry<String, int>> data,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: DramusColors.border),
      ),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: AppSpacing.lg),
            Column(
              children: data
                  .map(
                    (entry) => Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Stack(
                                children: [
                                  Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: DramusColors.lightBackground,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: entry.value /
                                        data
                                            .reduce((a, b) => MapEntry(
                                                  '',
                                                  a.value > b.value
                                                      ? a.value
                                                      : b.value,
                                                ))
                                            .value,
                                    child: Container(
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.sm,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: AppSpacing.sm,
                                        ),
                                        child: Text(
                                          '${entry.value}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color:
                                                    color.computeLuminance() >
                                                            0.5
                                                        ? DramusColors.darkText
                                                        : DramusColors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestion',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.lg),
        _buildManagementCard(
          context,
          icon: Icons.home_outlined,
          title: 'Gérer les annonces',
          subtitle: '2,847 annonces actives',
          color: DramusColors.primaryTeal,
        ),
        SizedBox(height: AppSpacing.lg),
        _buildManagementCard(
          context,
          icon: Icons.people_outline,
          title: 'Gérer les utilisateurs',
          subtitle: '5,420 utilisateurs',
          color: DramusColors.deepTeal,
        ),
        SizedBox(height: AppSpacing.lg),
        _buildManagementCard(
          context,
          icon: Icons.flag_outlined,
          title: 'Signalements',
          subtitle: '12 signalements en attente',
          color: DramusColors.notificationRed,
        ),
        SizedBox(height: AppSpacing.lg),
        _buildManagementCard(
          context,
          icon: Icons.settings_outlined,
          title: 'Paramètres',
          subtitle: 'Configuration de la plateforme',
          color: DramusColors.premiumYellow,
        ),
      ],
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: DramusColors.border),
      ),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DramusColors.secondaryText,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: DramusColors.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
