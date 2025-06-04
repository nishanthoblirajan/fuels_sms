import 'dart:convert';

import 'package:dart_telegram_bot/dart_telegram_bot.dart';
import 'package:dart_telegram_bot/telegram_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fuels_sms/ParseConstants.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:telephony/telephony.dart';

import 'message_history.dart';

void onBackgroundMessage(SmsMessage message) {
  debugPrint("onBackgroundMessage called");

  sendTelegram(message.body, message.address);
}

const String telegramBotToken =
    '6038774955:AAFDOwlNXxC5AMlH_ZvHhjZj0WEHCEqy9r0'; // Replace with your Telegram bot token
const int telegramChatId = -1001862858056; // Replace with your Telegram chat ID
const String odooServerUrl =
    'http://128.199.25.245:8069/api/telegram/message'; // Replace with your Odoo server URL

Future<void> sendTelegram(String? message, String? sender) async {
  String preciseMessage = '';
  debugPrint("sendTelegram called");

  ParseConstants().initParse();

  if ((sender!.contains('HDFCBK') &&
          message!.contains('4143') &&
          message!.contains('deposited') &&
          !(message!.contains('XX0832'))) ||
      (sender!.contains('CANBNK') &&
          message!.contains('363') &&
          message!.contains('CREDITED')) ||
      (sender!.contains('BPCLIN') && message!.contains('Received')) ||
      (sender!.contains('BPCLIN') && message!.contains('password')) ||
      (sender!.contains('STERNA') || sender!.contains('ALSRAM')) ||
      (sender!.contains('CBSSBI') && message!.contains('Credited')) ||
      (sender!.contains('SBIINB') && message!.contains('transfer')) ||
      (sender!.contains('SBIBNK') && message!.contains('echeque')) ||
      (sender!.contains('SBIPSG') && message!.contains('credited')) ||
      (sender.contains('PHONPE') && message!.contains('OTP'))) {
    debugPrint('Called--------');
    debugPrint(
        'Condition: ${(sender!.contains('SBIBNK') && message!.contains('echeque'))}');

    debugPrint(message.toString());
    Bot(
      token: telegramBotToken,
      onReady: (bot) async {
        if (sender!.contains('HDFCBK') ||
            sender!.contains('CANBNK') ||
            sender!.contains('CBSSBI') ||
            sender!.contains('SBIINB') ||
            sender!.contains('SBIPSG') ||
            sender!.contains('PHONPE')) {
          preciseMessage =
              message!.split('.')[0] + '.' + message!.split('.')[1];
        } else {
          preciseMessage = message!;
        }

        bot.sendMessage(
            ChatID(telegramChatId),
            '\nMessage from ' +
                sender.split('-')[1] +
                ':\n\n' +
                preciseMessage);

        var messageToParseDatabase = ParseObject('MessageInfo')
          ..set('From', sender.split('-')[1])
          ..set('Message', preciseMessage);
        var response = await messageToParseDatabase.save();
        if (response.success) {
          messageToParseDatabase = response.results?.first;
          print("Response received successfully");
        } else {
          debugPrint('error--------');
        }

        // Send message to Odoo server
        await sendToOdooServer(sender.split('-')[1], preciseMessage);

        debugPrint('message sent');
      },
      onStartFailed: (bot, e, s) => print('Start failed'),
    );
  }
}

Future<void> sendToOdooServer(String sender, String message) async {
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
    print("Message sent to Odoo server successfully");
  } else {
    print("Failed to send message to Odoo server");
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fuels SMS Automator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Fuels SMS Automator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _message = "";
  bool _scanningEnabled = true;

  TextEditingController messageController = TextEditingController();
  TextEditingController senderController = TextEditingController();
  final Telephony telephony = Telephony.instance;

  var databaseStatus = 'NA';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  onMessage(SmsMessage message) async {
    setState(() {
      _message = message.body ?? "Error reading message body.";
    });
  }

  onSendStatus(SendStatus status) {
    setState(() {
      _message = status == SendStatus.SENT ? "sent" : "delivered";
    });
  }

  Future<void> initPlatformState() async {
    ParseConstants().initParse().then((result) {
      if (result) {
        print('Database Connected');
        setState(() {
          databaseStatus = 'Connected';
        });
        Fluttertoast.showToast(msg: 'Database connected');
      } else {
        print('Database Error');
        setState(() {
          databaseStatus = 'Not connected';
        });
        Fluttertoast.showToast(msg: 'Database error');
      }
    });

    final bool? result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      telephony.listenIncomingSms(
          onNewMessage: _scanningEnabled ? onMessage : _dummyCallback,
          onBackgroundMessage: onBackgroundMessage);
    }
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Zaptr Automator",
      notificationText: "Your own personal automator",
      notificationImportance: AndroidNotificationImportance.Default,
    );
    bool success =
        await FlutterBackground.initialize(androidConfig: androidConfig);
    print('Background initialization: ${success.toString()}');
    if (success) {
      FlutterBackground.enableBackgroundExecution();
      Fluttertoast.showToast(msg: 'App will run in background');
    }

    if (!mounted) return;
  }

  void _dummyCallback(SmsMessage message) {
    // Dummy callback, does nothing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MessageHistory()));
                },
                child: Text('Message history')),
            Text(
              'This app will read incoming sms and send to Sowdambiga Fuels Telegram group',
            ),
            Text('Database status: ' + databaseStatus),
            TextField(
                controller: senderController,
                decoration: InputDecoration(label: Text('Sender'))),
            TextField(
              controller: messageController,
              decoration: InputDecoration(label: Text('Message')),
            ),
            ElevatedButton(
                onPressed: () {
                  sendTelegram(messageController.text, senderController.text);
                },
                child: Text('Send')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _scanningEnabled = !_scanningEnabled;
                });
              },
              child: Text(_scanningEnabled ? 'Stop Scan' : 'Start Scan'),
            ),
            ElevatedButton(
              onPressed: () {
                bool enabled = FlutterBackground.isBackgroundExecutionEnabled;
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
