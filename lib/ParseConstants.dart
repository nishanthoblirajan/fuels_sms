import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

import 'ApplicationConstants.dart';

class ParseConstants {
  Future<bool> initParse() async {
    await Parse().initialize(
      ApplicationConstants.keyParseApplicationId,
      ApplicationConstants.keyParseServerUrl,
      masterKey: ApplicationConstants.keyParseMasterKey,
    );
    var response = await Parse().healthCheck();
    print('response is ${response.toString()}');
    if (response.success) {
      print('Parse Initialised');
      return true;
    } else {
      print('Parse Initialisation failed');
      print('Response is ${response.result.toString()}');
      return false;
    }
  }

  Widget getDatabaseStatus() {
    return FutureBuilder(
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return new Text('Not Available');
          case ConnectionState.waiting:
            return new Center(child: Text('Loading...'));
          case ConnectionState.active:
            return new Text('');
          case ConnectionState.done:
            if (snapshot.hasError) {
              return new Text(
                'No data Available',
                style: TextStyle(color: Colors.red),
              );
            } else {
              if (snapshot.data) {
                return Text('Database Connected');
              } else {
                return Text('Database Not Connected');
              }
            }
            break;
          default:
            return Text('');
        }
      },
      future: initParse(),
    );
  }

  String timeFromDateTime(DateTime dateTime) {
    return DateFormat("Hm").format(dateTime.toLocal());
//    return '';
  }

  bool getBooleanResponse(ParseResponse response) {
    bool returnBoolean = false;
    if (response.success) {
      print('ParseConstant returnString is ${response.toString()}');
      returnBoolean = true;
    } else {
      Fluttertoast.showToast(msg: 'Error code: ${response.statusCode}');
      print('ParseConstant returnString is ${response.statusCode}');

      returnBoolean = false;
    }
    return returnBoolean;
  }

  //Used for generating data in the dashboard of the app
  Widget totalList(List<ParseObject> parseList) {
    return Text('${parseList.length}',
        style: new TextStyle(fontSize: 20.0, color: Colors.white));
  }

  String todayDateString() {
    var now = DateTime.now();
    return DateFormat("dd-MM-yyyy").format(now.toLocal());
    // return '23-04-2021';
  }

  String todayDateAndTime() {
    var now = DateTime.now();
    return DateFormat("dd-MM-yyyy hh:mm:ss").format(now.toLocal());
    // return '23-04-2021';
  }

  emailPassword(String email) async {
    String username = 'hello@zaptrtech.in';
    String password = 'Poos1994';

    final smtpServer =
        SmtpServer('zaptrtech.in', username: username, password: password);
    // Use the SmtpServer class to configure an SMTP server:
    // final smtpServer = SmtpServer('smtp.domain.com');
    // See the named arguments of SmtpServer for further configuration
    // options.

    // Create our message.
    final message = Message()
      ..from = Address(username, 'ZAPTR')
      ..recipients.add(email)
      ..subject = 'Hi, you requested for the password ${todayDateAndTime()}'
      ..text = 'The password is ${passwordUsingDate()}'
      ..html = "<h1>Password</h1>\n<p>${passwordUsingDate()}</p>";

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      Fluttertoast.showToast(msg: 'Message sent');
    } on MailerException catch (e) {
      print('Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }

  String passwordUsingDate() {
    var now = DateTime.now();
    String day = DateFormat("dd").format(now.toLocal());
    String month = DateFormat("MM").format(now.toLocal());

    num passwordNum = num.parse(day + month) * 5678;
    return passwordNum.toString();

    // return '23-04-2021';
  }

  String dateFromDateTime(DateTime dateTime) {
    // return DateFormat("dd-MM-yyyy hh:mm:ss").format(dateTime.toLocal());
    return DateFormat("dd-MM-yyyy").format(dateTime.toLocal());
  }
}
