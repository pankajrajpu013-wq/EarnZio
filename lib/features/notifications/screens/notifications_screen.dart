import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/auth_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<NotificationProvider>(context, listen: false)
          .loadNotifications(authProvider.currentUser!.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return notifProvider.unreadNotifications.isNotEmpty
                  ? TextButton(
                      onPressed: () {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        notifProvider.markAllAsRead(authProvider.currentUser!.uid);
                      },
                      child: const Text('Mark all read'),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notifProvider, _) {
          if (notifProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notifProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: AppTheme.lightGrey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications',
                    style: AppTheme.headingSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When people interact with your posts, you\'ll see it here',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await notifProvider.loadNotifications(authProvider.currentUser!.uid);
            },
            child: ListView.builder(
              itemCount: notifProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notifProvider.notifications[index];
                return _NotificationTile(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final dynamic notification;

  const _NotificationTile({required this.notification});

  IconData _getNotificationIcon() {
    final type = notification.type.toString();
    if (type.contains('like')) return Icons.favorite;
    if (type.contains('comment')) return Icons.comment;
    if (type.contains('follow')) return Icons.person_add;
    if (type.contains('share')) return Icons.share;
    return Icons.notifications;
  }

  Color _getNotificationColor() {
    final type = notification.type.toString();
    if (type.contains('like')) return Colors.red;
    if (type.contains('comment')) return AppTheme.primaryBlue;
    if (type.contains('follow')) return const Color(0xFF4CAF50);
    if (type.contains('share')) return AppTheme.primaryBlue;
    return AppTheme.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead ? AppTheme.white : AppTheme.lightBlue.withOpacity(0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor().withOpacity(0.2),
          child: Icon(
            _getNotificationIcon(),
            color: _getNotificationColor(),
          ),
        ),
        title: Text(
          notification.message,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          _formatTime(notification.createdAt),
          style: AppTheme.bodySmall,
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          if (!notification.isRead) {
            Provider.of<NotificationProvider>(context, listen: false)
                .markAsRead(notification.userId, notification.id);
          }

          if (notification.postId != null) {
            // Navigate to post
          }
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
