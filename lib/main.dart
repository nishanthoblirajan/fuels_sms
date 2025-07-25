import 'dart:convert';

import 'package:dart_telegram_bot/dart_telegram_bot.dart';
import 'package:dart_telegram_bot/telegram_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fuels_sms/ApplicationConstants.dart';
import 'package:fuels_sms/settings.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter/src/animation/animation.dart' as animation;
void onBackgroundMessage(SmsMessage message) {
  debugPrint("onBackgroundMessage: Received SMS from ${message.address}");
  sendTelegram(message.body, message.address);
}
Future<void> initializeDefaultSettings() async {
  final prefs = await SharedPreferences.getInstance();

  // Check if values already exist
  if (!prefs.containsKey('telegramBotToken')) {
    await prefs.setString('telegramBotToken', '6038774955:AAGokIq7jl_GJjNjr01k5MnZF54O0GfXgR4');
  }

  if (!prefs.containsKey('telegramChatId')) {
    await prefs.setString('telegramChatId', '-1001862858056');
  }

  if (!prefs.containsKey('otpBotToken')) {
    await prefs.setString('otpBotToken', '8112541883:AAHZhrMc7QuVuuTZSWYLvGN7mAbyDdzD8Ls');
  }

  if (!prefs.containsKey('otpGroupId')) {
    await prefs.setString('otpGroupId', '-4810490033');
  }
}
const String telegramBotToken =
    '6038774955:AAGokIq7jl_GJjNjr01k5MnZF54O0GfXgR4';
const int telegramChatId = -1001862858056;

const String otpBotToken = '8112541883:AAHZhrMc7QuVuuTZSWYLvGN7mAbyDdzD8Ls';
const int otpGroupId = -4810490033;

const String odooServerUrl =
    'http://128.199.25.245:8069/api/telegram/message';

Future<Map<String, dynamic>> getSettings() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'telegramBotToken': prefs.getString('telegramBotToken') ?? '',
    'telegramChatId': int.tryParse(prefs.getString('telegramChatId') ?? '') ?? 0,
    'otpBotToken': prefs.getString('otpBotToken') ?? '',
    'otpGroupId': int.tryParse(prefs.getString('otpGroupId') ?? '') ?? 0,
  };
}
Future<void> sendTelegram(String? message, String? sender) async {
  final settings = await getSettings();
  String telegramBotToken = settings['telegramBotToken']!;
  int telegramChatId = settings['telegramChatId']! as int;
  String otpBotToken = settings['otpBotToken']!;
  int otpGroupId = settings['otpGroupId']! as int;



  debugPrint("sendTelegram: Called with sender=$sender, message=$message");
  String preciseMessage = '';

  if (message == null || sender == null) {
    debugPrint("sendTelegram: Null message or sender, aborting");
    return;
  }

  if ((sender.contains('HDFCBK') &&
      message.contains('4143') &&
      message.contains('deposited') &&
      !message.contains('XX0832')) ||
      (sender.contains('CANBNK') &&
          message.contains('363') &&
          message.contains('CREDITED')) ||
      (sender.contains('BPCLIN') && message.contains('Received')) ||
      (sender.contains('BPCLIN') && message.contains('password')) ||
      (sender.contains('STERNA') || sender.contains('ALSRAM')) ||
      (sender.contains('CBSSBI') && message.contains('Credited')) ||
      (sender.contains('SBIINB') && message.contains('transfer')) ||
      (sender.contains('SBIPSG') && message.contains('credited')) ||
      (sender.contains('PHONPE') && message.contains('OTP'))) {
    debugPrint('sendTelegram: Message matches filter criteria');

    Bot(
      token: telegramBotToken,
      onReady: (bot) async {
        debugPrint('sendTelegram: Bot initialized successfully');
        if (sender.contains('HDFCBK') ||
            sender.contains('CANBNK') ||
            sender.contains('CBSSBI') ||
            sender.contains('SBIINB') ||
            sender.contains('SBIPSG') ||
            sender.contains('PHONPE')) {
          preciseMessage =
              message.split('.')[0] + '.' + message.split('.')[1];
          debugPrint('sendTelegram: Formatted preciseMessage=$preciseMessage');
        } else {
          preciseMessage = message;
          debugPrint('sendTelegram: Using full message=$preciseMessage');
        }

        debugPrint('sendTelegram: Sending message to Telegram chat $telegramChatId');
        await bot.sendMessage(
            ChatID(telegramChatId),
            '\nMessage from ' +
                sender.split('-')[1] +
                ':\n\n' +
                preciseMessage);
        debugPrint('sendTelegram: Message sent to Telegram');

        debugPrint('sendTelegram: Sending message to Odoo server');
        await sendToOdooServer(sender.split('-')[1], preciseMessage);
        debugPrint('sendTelegram: Completed');
      },
      onStartFailed: (bot, e, s) {
        debugPrint('sendTelegram: Bot start failed with error=$e, stack=$s');
      },
    );
  } else {
    debugPrint('sendTelegram: Message did not match filter criteria');
  }
  final lowered = message.toLowerCase();
  if (lowered.contains("otp") ||
      lowered.contains("one time") ||
      lowered.contains("password") ||
      lowered.contains("verification code")){
    Bot(
      token: otpBotToken,
      onReady: (bot) async {
        debugPrint('sendTelegram: OTP Bot initialized successfully');

        debugPrint('sendTelegram: Sending OTP message to Telegram chat $telegramChatId');
        await bot.sendMessage(
            ChatID(otpGroupId),
            '\OTP from ' +
                sender +
                ':\n\n' +
                message);
        debugPrint('sendTelegram: OTP Message sent to Telegram');
        debugPrint('sendTelegram: Completed');
      },
      onStartFailed: (bot, e, s) {
        debugPrint('sendTelegram: OTP Bot start failed with error=$e, stack=$s');
      },
    );
  }
}

Future<void> sendToOdooServer(String sender, String message) async {
  debugPrint('sendToOdooServer: Sending to Odoo with sender=$sender, message=$message');
  final response = await http.post(
    Uri.parse(odooServerUrl),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'sender': sender,
      'message': message,
    }),
  );

  if (response.statusCode == 200) {
    debugPrint("sendToOdooServer: Message sent successfully, response=${response.body}");
  } else {
    debugPrint("sendToOdooServer: Failed with status=${response.statusCode}, response=${response.body}");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('main: Starting application');

  await initializeDefaultSettings();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('MyApp: Building app widget');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(),
      title: 'SMS Automator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'SMS Automator ${ApplicationConstants.version}'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() {
    debugPrint('MyHomePage: Creating state');
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  String _message = "";
  bool _scanningEnabled = true;
  List<String> _logs = []; // List to store terminal logs
  final ScrollController _scrollController = ScrollController(); // Controller for scrolling
  late AnimationController _cursorController; // Controller for blinking cursor
  late animation.Animation<double> _cursorAnimation; // Animation for cursor blinking

  TextEditingController messageController = TextEditingController();
  TextEditingController senderController = TextEditingController();
  final Telephony telephony = Telephony.instance;

  @override
  void initState() {
    debugPrint('MyHomePageState: Initializing state');
    super.initState();
    initPlatformState();
    // Initialize cursor animation
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _cursorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_cursorController);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of the ScrollController
    _cursorController.dispose(); // Dispose of the AnimationController
    super.dispose();
  }

  // Override debugPrint to capture logs and scroll to bottom
  void debugPrint(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String()}] $message');
      if (_logs.length > 100) _logs.removeAt(0); // Limit log size
      // Scroll to the bottom after adding a new log
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
    print(message); // Retain original console output
  }

  onMessage(SmsMessage message) async {
    debugPrint('onMessage: Received SMS with body=${message.body}');
    setState(() {
      _message = message.body ?? "Error reading message body.";
      debugPrint('onMessage: Updated _message=$_message');
    });
  }

  onSendStatus(SendStatus status) {
    debugPrint('onSendStatus: Status received=$status');
    setState(() {
      _message = status == SendStatus.SENT ? "sent" : "delivered";
      debugPrint('onSendStatus: Updated _message=$_message');
    });
  }

  Future<void> initPlatformState() async {
    debugPrint('initPlatformState: Requesting phone and SMS permissions');
    final bool? result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      debugPrint('initPlatformState: Permissions granted, starting SMS listener');
      telephony.listenIncomingSms(
          onNewMessage: _scanningEnabled ? onMessage : _dummyCallback,
          onBackgroundMessage: onBackgroundMessage);
    } else {
      debugPrint('initPlatformState: Permissions denied or null');
    }

    debugPrint('initPlatformState: Initializing background execution');
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Zaptr Automator",
      notificationText: "Your own personal automator",
      notificationImportance: AndroidNotificationImportance.Default,
    );
    bool success =
    await FlutterBackground.initialize(androidConfig: androidConfig);
    debugPrint('initPlatformState: Background initialization success=$success');
    if (success) {
      FlutterBackground.enableBackgroundExecution();
      debugPrint('initPlatformState: Background execution enabled');
      Fluttertoast.showToast(msg: 'App will run in background');
    } else {
      debugPrint('initPlatformState: Background initialization failed');
    }

    if (!mounted) {
      debugPrint('initPlatformState: Widget not mounted, exiting');
      return;
    }
  }

  void _dummyCallback(SmsMessage message) {
    debugPrint('_dummyCallback: Called with message=${message.body}');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MyHomePageState: Building UI');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'This app will read incoming SMS and send to Sowdambiga Fuels Telegram group',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: senderController,
                  decoration: InputDecoration(
                    label: Text('Sender'),
                    labelStyle: TextStyle(color: Colors.cyanAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    label: Text('Message'),
                    labelStyle: TextStyle(color: Colors.cyanAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  debugPrint('Button: Send pressed, sending manual message');
                  sendTelegram(messageController.text, senderController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
                child: Text('Send'),
              ),
              ElevatedButton(
                onPressed: () {
                  debugPrint('Button: Toggling scan, current state=$_scanningEnabled');
                  setState(() {
                    _scanningEnabled = !_scanningEnabled;
                    debugPrint('Button: Scan state changed to $_scanningEnabled');
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
                child: Text(_scanningEnabled ? 'Stop Scan' : 'Start Scan'),
              ),
              ElevatedButton(
                onPressed: () {
                  debugPrint('Button: Check background process pressed');
                  bool enabled = FlutterBackground.isBackgroundExecutionEnabled;
                  debugPrint('Button: Background execution enabled=$enabled');
                  if (enabled) {
                    const snackbar = SnackBar(
                      content: Text('Enabled'),
                      backgroundColor: Colors.cyanAccent,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackbar);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
                child: Text('Check background process'),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Latest received SMS: $_message",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              // Terminal-like view
              Container(
                height: 200,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.black54],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Scan line animation
                    CustomPaint(
                      painter: ScanLinePainter(),
                      child: Container(),
                    ),
                    // Log list
                    ListView.builder(
                      controller: _scrollController,
                      itemCount: _logs.length + 1, // +1 for cursor
                      itemBuilder: (context, index) {
                        if (index == _logs.length) {
                          // Blinking cursor
                          return FadeTransition(
                            opacity: _cursorAnimation,
                            child: Text(
                              '_',
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: 12,
                                color: Colors.cyanAccent,
                                shadows: [
                                  Shadow(
                                    color: Colors.cyanAccent.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Text(
                          _logs[index],
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 12,
                            color: Colors.cyanAccent,
                            shadows: [
                              Shadow(
                                color: Colors.cyanAccent.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        );
                      },
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

// Custom painter for scan line effect
class ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.2)
      ..strokeWidth = 1.0;

    // Draw horizontal scan line
    canvas.drawLine(
      Offset(0, size.height * 0.1),
      Offset(size.width, size.height * 0.1),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}