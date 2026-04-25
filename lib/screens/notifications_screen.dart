import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/services/notification_service.dart';
import 'package:dramus/models/notification_model.dart';
import 'package:dramus/theme.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationService>(context, listen: false)
          .fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DramusColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: DramusColors.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: DramusColors.white,
        foregroundColor: DramusColors.darkText,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tout marquer comme lu',
            onPressed: () {
              Provider.of<NotificationService>(context, listen: false)
                  .markAllAsRead();
            },
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          if (notificationService.isLoading &&
              notificationService.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationService.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64,
                      color: DramusColors.secondaryText.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune notification',
                    style: TextStyle(
                      fontSize: 18,
                      color: DramusColors.secondaryText,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notificationService.fetchNotifications(),
            child: ListView.separated(
              itemCount: notificationService.notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notificationService.notifications[index];
                return Dismissible(
                  key: Key(notification.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    notificationService.deleteNotification(notification.id);
                  },
                  child: NotificationTile(notification: notification),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead
          ? DramusColors.white
          : DramusColors.primaryTeal.withOpacity(0.05),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            Provider.of<NotificationService>(context, listen: false)
                .markAsRead(notification.id);
          }
          // TODO: Navigate based on notification type/data
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DramusColors.primaryTeal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: DramusColors.primaryTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DramusColors.secondaryText,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm', 'fr')
                          .format(notification.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DramusColors.secondaryText,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: DramusColors.notificationRed,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
