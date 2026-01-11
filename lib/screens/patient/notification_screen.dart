import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../models/in_app_notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<InAppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }


  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
    });
    final notifications = await NotificationService.getInAppNotifications();
    setState(() {
      _notifications = notifications;
      _loading = false;
    });
  }

  List<InAppNotification> get _todayNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _notifications.where((n) {
      final notificationDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      return notificationDate.isAtSameMomentAs(today);
    }).toList();
  }

  List<InAppNotification> get _yesterdayNotifications {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return _notifications.where((n) {
      final notificationDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      return notificationDate.isAtSameMomentAs(yesterday);
    }).toList();
  }

  int get _newNotificationsCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  Future<void> _markTodayAsRead() async {
    final todayIds = _todayNotifications.map((n) => n.id).toList();
    for (var id in todayIds) {
      await NotificationService.markAsRead(id);
    }
    await _loadNotifications();
  }

  Future<void> _markYesterdayAsRead() async {
    final yesterdayIds = _yesterdayNotifications.map((n) => n.id).toList();
    for (var id in yesterdayIds) {
      await NotificationService.markAsRead(id);
    }
    await _loadNotifications();
  }

  Future<void> _deleteNotification(InAppNotification notification) async {
    await NotificationService.deleteNotification(notification.id);
    await _loadNotifications();
  }

  Future<void> _markAsRead(InAppNotification notification) async {
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
      await _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Notification',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          centerTitle: true,
          actions: [
            if (_newNotificationsCount > 0)
              Container(
                // height: 1,
                // width: 50,
                // margin: const EdgeInsets.only(right: 12),
                // padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2D5B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '$_newNotificationsCount NEW',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today Section
                    if (_todayNotifications.isNotEmpty)
                      _buildNotificationSection(
                        title: 'TODAY',
                        notifications: _todayNotifications,
                        onMarkAllRead: _markTodayAsRead,
                      ),
                    
                    if (_todayNotifications.isNotEmpty && _yesterdayNotifications.isNotEmpty)
                      const SizedBox(height: 32),
                    
                    // Yesterday Section
                    if (_yesterdayNotifications.isNotEmpty)
                      _buildNotificationSection(
                        title: 'YESTERDAY',
                        notifications: _yesterdayNotifications,
                        onMarkAllRead: _markYesterdayAsRead,
                      ),
                    
                    // Empty state
                    if (_notifications.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You\'ll see your appointment notifications here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required List<InAppNotification> notifications,
    required VoidCallback onMarkAllRead,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                fontFamily: 'Lato',
              ),
            ),
            TextButton(
              onPressed: onMarkAllRead,
              child: const Text(
                'Mark all as read',
                style: TextStyle(
                  color: Color(0xFF0B2D5B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Notifications List
        ...notifications.map((notification) => _buildNotificationItem(notification)),
      ],
    );
  }

  Widget _buildNotificationItem(InAppNotification notification) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: const [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _deleteNotification(notification),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead ? Colors.grey.shade200 : Color(0xFF0B2D5B),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification.iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.icon,
                color: notification.iconColor,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: notification.isRead ? Colors.grey.shade700 : Colors.black,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ),
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    notification.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                      fontFamily: 'Lato',
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
}
