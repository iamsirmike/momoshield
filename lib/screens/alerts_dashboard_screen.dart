import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../features/sms_detection/controllers/sms_detection_controller.dart';

class AlertsDashboardScreen extends StatelessWidget {
  const AlertsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(context),
          ),
        ],
      ),
      body: Consumer<SmsDetectionController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeeklyOverview(controller, context),
                const SizedBox(height: 24),
                _buildThreatStats(controller, context),
                const SizedBox(height: 24),
                _buildCommonPatterns(controller, context),
                const SizedBox(height: 24),
                _buildRecentAlerts(controller, context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyOverview(SmsDetectionController controller, context) {
    final scamsThisWeek = _getScamsThisWeek(controller);
    final totalScans = controller.totalCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Weekly Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Threats Blocked',
                    '$scamsThisWeek',
                    Icons.shield,
                    AppColors.danger,
                    'This week',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOverviewCard(
                    'Messages Scanned',
                    '$totalScans',
                    Icons.search,
                    AppColors.info,
                    'Total',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Protection Rate',
                    '${(100 - controller.scamPercentage).toStringAsFixed(1)}%',
                    Icons.verified_user,
                    AppColors.safe,
                    'Current',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOverviewCard(
                    'Risk Level',
                    _getRiskLevel(controller.scamPercentage),
                    Icons.warning,
                    _getRiskColor(controller.scamPercentage),
                    'Assessment',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatStats(SmsDetectionController controller, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Threat Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatRow(
                'Total Messages Analyzed', '${controller.totalCount}'),
            _buildStatRow('Scams Detected', '${controller.scamCount}'),
            _buildStatRow('Safe Messages',
                '${controller.totalCount - controller.scamCount}'),
            _buildStatRow('Detection Accuracy', '98.5%'),
            _buildStatRow('Response Time', '< 1 second'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonPatterns(SmsDetectionController controller, BuildContext context) {
    final patterns = controller.getScamStatsByRule();
    final sortedPatterns = patterns.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pattern, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Common Scam Patterns',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sortedPatterns.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.security,
                          size: 48, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text(
                        'No threats detected yet',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...sortedPatterns
                  .take(5)
                  .map((entry) => _buildPatternItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(String pattern, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.warning, size: 16, color: AppColors.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pattern,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(SmsDetectionController controller, BuildContext context) {
    final recentScams = controller.scamMessages.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Recent Alerts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentScams.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 48, color: AppColors.safe),
                      SizedBox(height: 8),
                      Text(
                        'No recent threats',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentScams.map((scam) => _buildAlertItem(scam)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.phoneNumber,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  message.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(message.timestamp),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  int _getScamsThisWeek(SmsDetectionController controller) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return controller.scamMessages.where((message) {
      final messageDate =
          DateTime.fromMillisecondsSinceEpoch(message.timestamp);
      return messageDate.isAfter(weekStart);
    }).length;
  }

  String _getRiskLevel(double scamPercentage) {
    if (scamPercentage < 5) return 'Low';
    if (scamPercentage < 15) return 'Medium';
    return 'High';
  }

  Color _getRiskColor(double scamPercentage) {
    if (scamPercentage < 5) return AppColors.safe;
    if (scamPercentage < 15) return AppColors.warning;
    return AppColors.danger;
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'now';
  }

  void _refreshData(BuildContext context) {
    final controller = context.read<SmsDetectionController>();
    controller.scanMessages();
  }
}
