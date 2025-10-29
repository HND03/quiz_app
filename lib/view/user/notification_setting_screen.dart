import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiz_app/theme/theme.dart';
import 'package:quiz_app/model/notification_service.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  bool _isDailyEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    await NotificationService.requestPermission();
    final isActive = await NotificationService.isDailyScheduled();
    setState(() => _isDailyEnabled = isActive);
  }

  Future<void> _toggleDailyNotification(bool value) async {
    setState(() => _isLoading = true);

    if (value) {
      await NotificationService.scheduleDaily(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Daily reminder set at ${_selectedTime.format(context)} ⏰",
          ),
        ),
      );
    } else {
      await NotificationService.cancelDaily();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Daily notifications turned off.")),
      );
    }

    setState(() {
      _isDailyEnabled = value;
      _isLoading = false;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
      if (_isDailyEnabled) {
        await NotificationService.scheduleDaily(
          hour: picked.hour,
          minute: picked.minute,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Updated daily reminder to ${picked.format(context)} ✅",
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
    isDark ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor =
    isDark ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : AppTheme.primaryColor,
        title: const Text(
          "Notification Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _isLoading
                ? null
                : () async {
              await _toggleDailyNotification(_isDailyEnabled);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Settings saved successfully ✅"),
                ),
              );

              await Future.delayed(const Duration(milliseconds: 800));

              if (mounted) {
                Navigator.pop(context); // 👈 Quay lại ProfileScreen
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 👈 giúp các child full width
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Daily Reminder ---
            _buildSectionCard(
              title: "Daily Reminder",
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded( // 👈 giúp text chiếm phần còn lại, tránh tràn
                    child: Text(
                      "Enable daily notifications",
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isDailyEnabled,
                    onChanged: _isLoading ? null : _toggleDailyNotification,
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Notification Time ---
            _buildSectionCard(
              title: "Notification Time",
              child: Container(
                width: double.infinity, // 👈 ép section full width
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.jm().format(
                              DateTime(0, 0, 0, _selectedTime.hour, _selectedTime.minute),
                            ),
                            style: TextStyle(fontSize: 16, color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Choose when to get your daily study reminder",
                            style: TextStyle(color: secondaryTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: _isLoading ? null : _pickTime,
                      child: const Text("Change"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- Save Button ---
            SizedBox(
              width: double.infinity, // 👈 full width
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading
                    ? null
                    : () async {
                  await _toggleDailyNotification(_isDailyEnabled);

                  // Hiển thị thông báo đã lưu
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Settings saved successfully ✅")),
                  );

                  // Chờ 1 chút để người dùng thấy SnackBar, sau đó quay lại Profile
                  await Future.delayed(const Duration(milliseconds: 800));

                  if (mounted) {
                    Navigator.pop(context); // 👈 Quay về ProfileScreen
                  }
                },

                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save Settings",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
    isDark ? AppTheme.darkCardColor : AppTheme.cardColor;
    final textColor =
    isDark ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
