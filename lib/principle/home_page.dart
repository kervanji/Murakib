import 'package:flutter/material.dart';
import 'package:murakib_vip/principle/rule_page.dart';
import 'package:murakib_vip/principle/send_notification_page.dart'; // Replace with your actual notification page
import 'package:murakib_vip/principle/messages_page.dart'; // Replace with your actual messages page
import 'package:murakib_vip/principle/admin_contact_page.dart'; // Replace with your actual admin contact page
import 'package:murakib_vip/login/login_screen.dart'; // Import your LoginScreen
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class HomePage extends StatelessWidget {
  final String principalUsername;
  const HomePage({super.key, required this.principalUsername});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          'HOME',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // Clear saved credentials
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Navigate to Login Screen
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (route) => false, // This will remove all routes from the stack
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Navigate to settings page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Settings')),
                    body: const Center(child: Text('Settings Page')),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notification Box
            GestureDetector(
              onTap: () {
                // Navigate to Notification Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SendNotificationPage(
                            principalUsername: principalUsername,
                          )),
                );
              },
              child: _buildFeatureBox(
                icon: Icons.notifications_active_outlined,
                title: "Notifications",
              ),
            ),
            const SizedBox(height: 20),

            // Rules Box
            GestureDetector(
              onTap: () {
                // Navigate to Rule Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RulePage(
                      principalUsername: principalUsername,
                    ),
                  ),
                );
              },
              child: _buildFeatureBox(
                icon: Icons.rule_folder_outlined,
                title: "Rules",
              ),
            ),
            const SizedBox(height: 20),

            // Messages Button
            ElevatedButton(
              onPressed: () {
                // Navigate to Messages Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagesPage(
                      principalUsername: principalUsername,
                    ),
                  ),
                );
              },
              style: _buttonStyle(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Messages',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Send Message to Admin Button
            ElevatedButton(
              onPressed: () {
                // Navigate to Admin Contact Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminContactPage(
                      principalUsername: principalUsername,
                    ),
                  ),
                );
              },
              style: _buttonStyle(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Send Message to Admin',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFFDF1E5), // Matches beige background
    );
  }

  // Helper Method to Build Feature Boxes
  Widget _buildFeatureBox({required IconData icon, required String title}) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFFEE6A6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Icon(icon, size: 50, color: Colors.black87),
          const SizedBox(width: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Button Style
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
