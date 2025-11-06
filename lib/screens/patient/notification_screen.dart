import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _newNotificationsCount = 2;

  final List<NotificationItem> _todayNotifications = [
    NotificationItem(
      id: '1',
      title: 'Appointment Success',
      description: 'Congratulations - your appointment is confirmed! We\'re looking forward to meeting with you.',
      time: '1h',
      icon: Icons.calendar_today,
      iconColor: Colors.green,
      iconBackgroundColor: Colors.green.shade50,
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Schedule Changed',
      description: 'You have successfully changes your appointment with Dr. Joshua Doe. Don\'t forgot to active your reminder',
      time: '1h',
      icon: Icons.calendar_view_month,
      iconColor: Color(0xFF0B2D5B),
      iconBackgroundColor: Color(0xFF0B2D5B),
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Video Call Appointment',
      description: 'We\'ll send you a link to join the call at the booking details, so all you need is a computer or mobile device with a camera and an internet connection.',
      time: '1h',
      icon: Icons.videocam,
      iconColor: Colors.green,
      iconBackgroundColor: Colors.green.shade50,
      isRead: true,
    ),
  ];

  final List<NotificationItem> _yesterdayNotifications = [
    NotificationItem(
      id: '4',
      title: 'Appointment Cancelled',
      description: 'You have successfully cancelled your appointment with Dr. Joshua Doe. 90% the funds will be returned to your account.',
      time: '1d',
      icon: Icons.cancel,
      iconColor: Colors.red,
      iconBackgroundColor: Colors.red.shade50,
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      title: 'New Paypal Added',
      description: 'Your Paypal has been successfully linked with your account.',
      time: '1d',
      icon: Icons.account_balance_wallet,
      iconColor: Color(0xFF0B2D5B),
      iconBackgroundColor: Color(0xFF0B2D5B),
      isRead: true,
    ),
  ];

  void _markTodayAsRead() {
    setState(() {
      for (var notification in _todayNotifications) {
        notification.isRead = true;
      }
      _newNotificationsCount = 0;
    });
  }

  void _markYesterdayAsRead() {
    setState(() {
      for (var notification in _yesterdayNotifications) {
        notification.isRead = true;
      }
    });
  }

  void _deleteNotification(NotificationItem notification) {
    setState(() {
      final bool wasInToday =
          _todayNotifications.any((n) => n.id == notification.id);
      if (wasInToday && !notification.isRead && _newNotificationsCount > 0) {
        _newNotificationsCount = _newNotificationsCount - 1;
      }
      _todayNotifications.removeWhere((n) => n.id == notification.id);
      _yesterdayNotifications.removeWhere((n) => n.id == notification.id);
    });
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today Section
              _buildNotificationSection(
                title: 'TODAY',
                notifications: _todayNotifications,
                onMarkAllRead: _markTodayAsRead,
              ),
              
              const SizedBox(height: 32),
              
              // Yesterday Section
              _buildNotificationSection(
                title: 'YESTERDAY',
                notifications: _yesterdayNotifications,
                onMarkAllRead: _markYesterdayAsRead,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required List<NotificationItem> notifications,
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

  Widget _buildNotificationItem(NotificationItem notification) {
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
                        notification.time,
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
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.isRead,
  });
}
