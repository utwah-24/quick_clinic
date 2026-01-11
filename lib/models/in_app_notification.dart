import 'package:flutter/material.dart';

class InAppNotification {
  // Helper method to get IconData from code point, using const when possible
  static IconData _getIconFromCode(int codePoint) {
    // Map common icon codes to const IconData instances
    switch (codePoint) {
      case 0xe7f7: // Icons.notifications
        return Icons.notifications;
      case 0xe0ca: // Icons.calendar_today
        return Icons.calendar_today;
      case 0xe0b0: // Icons.check_circle
        return Icons.check_circle;
      case 0xe14c: // Icons.error
        return Icons.error;
      case 0xe000: // Icons.info
        return Icons.info;
      default:
        // For unknown icons, fall back to a const default to avoid tree-shaking issues
        // Consider adding more cases above for commonly used icons
        return Icons.notifications;
    }
  }
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  bool isRead;
  final String? appointmentId; // Link to appointment if notification is related

  InAppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.isRead = false,
    this.appointmentId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'iconCode': icon.codePoint,
        'iconColor': iconColor.value,
        'iconBackgroundColor': iconBackgroundColor.value,
        'isRead': isRead,
        'appointmentId': appointmentId,
      };

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    final iconCode = json['iconCode'] as int?;
    return InAppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      icon: iconCode != null ? _getIconFromCode(iconCode) : Icons.notifications,
      iconColor: Color(json['iconColor'] ?? Colors.blue.value),
      iconBackgroundColor: Color(json['iconBackgroundColor'] ?? Colors.blue.shade50.value),
      isRead: json['isRead'] ?? false,
      appointmentId: json['appointmentId']?.toString(),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return '1d';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${difference.inDays ~/ 7}w';
    }
  }
}
