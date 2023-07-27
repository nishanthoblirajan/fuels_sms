import 'package:dart_telegram_bot/dart_telegram_bot.dart';
import 'package:dart_telegram_bot/telegram_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:telephony/telephony.dart';

onBackgroundMessage(SmsMessage message) {
  debugPrint("onBackgroundMessage called");

  sendTelegram(message.body, message.address);
}

//support
// 1691651299:AAGyxfnNolH6BP8HcjxtZbYEfo1EKwXVSWc
//-593020411

//real
// 6038774955:AAFDOwlNXxC5AMlH_ZvHhjZj0WEHCEqy9r0
// fuels group-
// -1001862858056
sendTelegram(String? message, String? sender) {
  String preciseMessage = '';
  debugPrint("sendTelegram called");

  if ((sender!.contains('HDFCBK') &&
          message!.contains('4143') &&
          message!.contains('deposited')) ||
      (sender!.contains('CANBNK') &&
          message!.contains('363') &&
          message!.contains('CREDITED')) ||
      (sender!.contains('BPCLIN') && message!.contains('Received')) ||
      (sender!.contains('STERNA'))) {
    Bot(
      token: '6038774955:AAFDOwlNXxC5AMlH_ZvHhjZj0WEHCEqy9r0',
      onReady: (bot) {
        if (sender!.contains('HDFCBK')) {
          preciseMessage =
              message!.split('.')[0] + '.' + message!.split('.')[1];
        } else if (sender!.contains('CANBNK')) {
          preciseMessage =
              message!.split('.')[0] + '.' + message!.split('.')[1];
        } else {
          preciseMessage = message!;
        }
        debugPrint(message.split('.')[1]);
        bot.sendMessage(
            ChatID(-1001862858056),
            '\nMessage from ' +
                sender.split('-')[1] +
                ':\n\n' +
                preciseMessage);
        debugPrint('message sent');
        // bot.start(clean: true).then((value) {
        //   bot.sendMessage(ChatID(-593020411), stringToSend!);
        //   debugPrint('message sent');
        // });
      },
      // Handle start failure
      onStartFailed: (bot, e, s) => print('Start failed'),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fuels SMS Automator',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Fuels SMS Automator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _message = "";

  TextEditingController messageController = TextEditingController();
  TextEditingController senderController = TextEditingController();
  final Telephony telephony = Telephony.instance;
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

// Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.

    final bool? result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      telephony.listenIncomingSms(
          onNewMessage: onMessage, onBackgroundMessage: onBackgroundMessage);
    }
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "SMS Automator",
      notificationText: "SMS automator for Telegram",
      notificationImportance: AndroidNotificationImportance
          .Default, // Default is ic_launcher from folder mipmap
    );
    bool success =
        await FlutterBackground.initialize(androidConfig: androidConfig);
    bool success2 = await FlutterBackground.enableBackgroundExecution();

    if (!mounted) return;
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
            Text(
              'This app will read incoming sms and send to Sowdambiga Fuels Telegram group',
            ),
            TextField(
              controller: senderController,
            ),
            TextField(
              controller: messageController,
            ),
            ElevatedButton(
                onPressed: () {
                  sendTelegram(messageController.text, senderController.text);
                  setState(() {
                    messageController.clear();
                    senderController.clear();
                  });
                },
                child: Text('Send')),
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
                child: Text('Check background process')),
            Center(child: Text("Latest received SMS: $_message")),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
