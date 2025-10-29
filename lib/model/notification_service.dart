import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static const int _dailyNotificationId = 1001;

  // ✅ Khởi tạo notification
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'daily_channel',
          channelName: 'Daily Notifications',
          channelDescription: 'Reminds you to study every day',
          defaultColor: const Color(0xFF3B82F6),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );
  }

  // ✅ Xin quyền
  static Future<void> requestPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // ✅ Lên lịch thông báo hằng ngày vào giờ và phút cụ thể
  static Future<void> scheduleDaily({
    required int hour,
    required int minute,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _dailyNotificationId,
        channelKey: 'daily_channel',
        title: '📚 Daily Study Reminder',
        body: 'It’s study time! Let’s keep learning 💪',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true, // Lặp lại mỗi ngày
        allowWhileIdle: true,
      ),
    );
  }

  // ❌ Hủy thông báo hằng ngày
  static Future<void> cancelDaily() async {
    await AwesomeNotifications().cancel(_dailyNotificationId);
  }

  // 🔍 Kiểm tra xem daily notification có đang được bật không
  static Future<bool> isDailyScheduled() async {
    final scheduledList =
    await AwesomeNotifications().listScheduledNotifications();
    return scheduledList.any(
          (n) => n.content?.id == _dailyNotificationId,
    );
  }
}
