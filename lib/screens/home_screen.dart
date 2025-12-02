import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../features/sms_detection/controllers/sms_detection_controller.dart';
import '../features/sms_detection/models/sms_scan_result.dart';
import 'message_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    final controller = context.read<SmsDetectionController>();
    if (!controller.hasPermissions) {
      final granted = await controller.requestPermissions();
      if (granted) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissions granted! Scanning your messages...'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } else {
      // Already have permissions, ensure we're scanning and listening
      if (controller.totalCount == 0) {
        await controller.scanMessages();
      }
      if (!controller.isListening) {
        controller.startRealTimeDetection();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SmsDetectionController>(
        builder: (context, controller, child) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(controller),
              if (controller.state == SmsDetectionState.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (controller.state == SmsDetectionState.error)
                _buildErrorSliver(controller),
              if (!controller.hasPermissions)
                _buildPermissionSliver(controller),
              if (controller.hasPermissions &&
                  controller.state != SmsDetectionState.loading) ...[
                _buildRecentFlaggedMessages(controller),
              ],
            ],
          );
        },
      ),
      floatingActionButton: Consumer<SmsDetectionController>(
        builder: (context, controller, child) {
          if (!controller.hasPermissions) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: controller.state == SmsDetectionState.scanning
                ? null
                : () => controller.scanMessages(),
            icon: controller.state == SmsDetectionState.scanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            label: Text(controller.state == SmsDetectionState.scanning
                ? 'Scanning...'
                : 'Scan Messages'),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(SmsDetectionController controller) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Recent Threats'),
          ],
        ),
        centerTitle: true,
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: controller.isListening
                    ? AppColors.danger
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                controller.isListening ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: controller.hasPermissions
                ? () {
                    if (controller.isListening) {
                      controller.stopRealTimeDetection();
                    } else {
                      controller.startRealTimeDetection();
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFlaggedMessages(SmsDetectionController controller) {
    final flaggedMessages = controller.scamMessages;

    if (flaggedMessages.isEmpty) {
      return _buildEmptyState(controller);
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildFlaggedMessageCard(flaggedMessages[index]),
          childCount: flaggedMessages.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(SmsDetectionController controller) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.safe.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 64,
                color: AppColors.safe,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Threats Detected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.safe,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your messages are protected',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            if (controller.totalCount == 0)
              ElevatedButton.icon(
                onPressed: () => controller.scanMessages(),
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Your Messages'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlaggedMessageCard(SmsScanResult message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.danger.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Threat header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THREAT DETECTED',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        message.phoneNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Message content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Message:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message.message,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                if (message.matchedRule != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.rule_rounded,
                          color: AppColors.danger,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Threat Pattern:',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                message.matchedRule!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showMessageDetails(message),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _reportScam(message),
                        icon: const Icon(Icons.report_outlined, size: 18),
                        label: const Text('Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  void _showMessageDetails(SmsScanResult message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageDetailScreen(message: message),
      ),
    );
  }

  void _reportScam(SmsScanResult message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Scam reported successfully!'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _showMessageDetails(message),
        ),
      ),
    );
  }

  Widget _buildErrorSliver(SmsDetectionController controller) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error: ${controller.errorMessage}',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                controller.clearError();
                _checkPermissions();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSliver(SmsDetectionController controller) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 64, color: AppColors.warning),
            const SizedBox(height: 16),
            const Text('SMS permissions required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Grant SMS access to detect scam messages',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.requestPermissions(),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}
