import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/sms_detection/models/sms_scan_result.dart';
import '../core/theme/app_colors.dart';

class MessageDetailScreen extends StatelessWidget {
  final SmsScanResult message;

  const MessageDetailScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyMessage(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThreatCard(),
            const SizedBox(height: 16),
            _buildMessageCard(context),
            const SizedBox(height: 16),
            _buildSenderCard(context),
            const SizedBox(height: 16),
            if (message.isScam) _buildRuleCard(context),
            if (message.isScam) const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: message.isScam ? AppColors.danger : AppColors.safe,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            message.isScam ? Icons.warning_rounded : Icons.shield_rounded,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            message.isScam ? 'THREAT DETECTED' : 'MESSAGE IS SAFE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message.isScam
                ? 'This message contains suspicious content'
                : 'No threats detected in this message',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.message, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Message Content',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.message,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Received: ${_formatDateTime(message.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Sender Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor:
                    message.isScam ? AppColors.danger : AppColors.safe,
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(
                message.phoneNumber,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                message.isScam ? 'Suspicious sender' : 'No reports found',
                style: TextStyle(
                  color: message.isScam ? AppColors.danger : AppColors.safe,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showSenderOptions(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard(BuildContext context) {
    if (!message.isScam || message.matchedRule == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rule, color: AppColors.danger),
                const SizedBox(width: 8),
                Text(
                  'Threat Analysis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Matched Pattern:',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.matchedRule!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This message contains patterns commonly used in mobile money scams.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message.isScam) ...[
          ElevatedButton.icon(
            onPressed: () => _reportScam(context),
            icon: const Icon(Icons.report),
            label: const Text('Report as Scam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => _blockSender(context),
          icon: const Icon(Icons.block),
          label: Text('Block ${message.phoneNumber}'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _shareMessage(context),
          icon: const Icon(Icons.share),
          label: const Text('Share Message'),
        ),
      ],
    );
  }

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  void _reportScam(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Scam'),
        content: const Text(
            'This will help improve our detection system and protect other users. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitScamReport(context);
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _submitScamReport(BuildContext context) {
    // TODO: Implement scam reporting logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Scam reported successfully. Thank you for helping protect others!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _blockSender(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Sender'),
        content: Text('Block all messages from ${message.phoneNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement blocking logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${message.phoneNumber} has been blocked')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _shareMessage(BuildContext context) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _showSenderOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('View Sender Details'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show sender reputation
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Message History'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show all messages from this sender
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Block Sender'),
            onTap: () {
              Navigator.pop(context);
              _blockSender(context);
            },
          ),
        ],
      ),
    );
  }
}
