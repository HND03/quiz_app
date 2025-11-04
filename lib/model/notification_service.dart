import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class NotificationService {
  static const int _dailyNotificationId = 1001;

  // Khóa SharedPreferences
  static const String _keyIsDailyEnabled = 'is_daily_enabled';
  static const String _keyHour = 'daily_hour';
  static const String _keyMinute = 'daily_minute';

  // Tên task cho Workmanager
  static const String _dailyTask = 'daily_notification_task';

  // 🧩 Khởi tạo AwesomeNotifications và Workmanager
  static Future<void> initialize() async {
    // Init notification
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

    // Init workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  // ✅ Request quyền thông báo
  static Future<void> requestPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // ✅ Lên lịch thông báo hằng ngày
  static Future<void> scheduleDaily({
    required int hour,
    required int minute,
  }) async {
    await cancelDaily(); // hủy task cũ nếu có

    final initialDelay = _nextDailyDelay(hour, minute);

    await Workmanager().registerPeriodicTask(
      "daily_task_id",
      _dailyTask,
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      constraints: Constraints(
        requiresBatteryNotLow: false,
        // nếu muốn thêm điều kiện khác: requiresCharging, requiresDeviceIdle, dll.
      ),
    );
    // Lưu setting
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDailyEnabled, true);
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);
  }


  // ❌ Hủy thông báo
  static Future<void> cancelDaily() async {
    await Workmanager().cancelByUniqueName("daily_task_id");

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDailyEnabled, false);
  }

  // 🔍 Kiểm tra trạng thái
  static Future<bool> isDailyScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsDailyEnabled) ?? false;
  }

  // 🔹 Lấy thời gian lưu
  static Future<TimeOfDay> getSavedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_keyHour) ?? 8;
    final minute = prefs.getInt(_keyMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // 🔹 Lưu giờ nhưng không bật thông báo
  static Future<void> saveTimeOnly(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHour, time.hour);
    await prefs.setInt(_keyMinute, time.minute);
  }

  // 🕒 Tính toán thời gian delay đến lần thông báo kế tiếp
  static Duration _nextDailyDelay(int hour, int minute) {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now)) {
      return next.add(const Duration(days: 1)).difference(now);
    }
    return next.difference(now);
  }

  // 🧠 Callback cho Workmanager
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      if (task == _dailyTask) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: _dailyNotificationId,
            channelKey: 'daily_channel',
            title: '📚 Daily Study Reminder',
            body: 'It’s study time! Let’s keep learning 💪',
          ),
        );
      }
      return Future.value(true);
    });
  }
}
