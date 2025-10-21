import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/theme/theme.dart';

import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  late TextEditingController _nameController;
  bool _isEditingName = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: user?.displayName ?? "User");
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || user == null) return;

    try {
      await user!.updateDisplayName(newName);
      await user!.reload();

      // Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Display name updated successfully!")),
      );

      // Refresh lại màn hình bằng cách reload toàn bộ ProfileScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update name: $e")));
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Confirm Account Deletion",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this account?\nThis action cannot be undone.",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppTheme.textPrimaryColor),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete Account"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await user.delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account deleted successfully.")),
          );

          // Điều hướng về LoginScreen và xoá hết stack cũ
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete account: ${e.message}")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e")),
        );
      }
    }
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListTile(
        leading: Icon(icon, color: color ?? AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _animationController.forward();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Avatar
            CircleAvatar(
              radius: 45,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 15),

            // Display name + Edit
            _isEditingName
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: "Display Name",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: _updateDisplayName,
                        ),
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user?.displayName ?? "User",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          setState(() => _isEditingName = true);
                        },
                      ),
                    ],
                  ),

            const SizedBox(height: 5),
            Text(
              user?.email ?? "No email",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            const Divider(thickness: 1, indent: 40, endIndent: 40),
            const SizedBox(height: 20),

            // Settings list
            _buildSettingTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.dark_mode_outlined,
              title: "Dark Mode",
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.notifications_outlined,
              title: "Notification Settings",
              onTap: () {},
            ),
            const SizedBox(height: 20),
            const Divider(thickness: 1, indent: 40, endIndent: 40),
            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Logout",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.signOut();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Logged out successfully!")),
                          );

                          // Quay về trang Login bằng cách làm mới AuthWrapper
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Logout failed: $e")),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    onPressed: _confirmDeleteAccount,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text("Delete Account"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
