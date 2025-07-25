import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _telegramBotTokenController = TextEditingController();
  final TextEditingController _telegramChatIdController = TextEditingController();
  final TextEditingController _otpBotTokenController = TextEditingController();
  final TextEditingController _otpGroupIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _telegramBotTokenController.text = prefs.getString('telegramBotToken') ?? '';
    _telegramChatIdController.text = prefs.getString('telegramChatId') ?? '';
    _otpBotTokenController.text = prefs.getString('otpBotToken') ?? '';
    _otpGroupIdController.text = prefs.getString('otpGroupId') ?? '';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('telegramBotToken', _telegramBotTokenController.text.trim());
    await prefs.setString('telegramChatId', _telegramChatIdController.text.trim());
    await prefs.setString('otpBotToken', _otpBotTokenController.text.trim());
    await prefs.setString('otpGroupId', _otpGroupIdController.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings Saved Successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField('Telegram Bot Token', _telegramBotTokenController),
            SizedBox(height: 12),
            _buildTextField('Telegram Chat ID', _telegramChatIdController),
            SizedBox(height: 12),
            _buildTextField('OTP Bot Token', _otpBotTokenController),
            SizedBox(height: 12),
            _buildTextField('OTP Group ID', _otpGroupIdController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              child: Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}
