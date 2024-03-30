import 'package:encrypt/encrypt.dart' as enc;
import 'package:encrypt/encrypt.dart';

class ApplicationConstants {
  static const int updateFrequency = 2;
  static const String botToken =
      '6038774955:AAFDOwlNXxC5AMlH_ZvHhjZj0WEHCEqy9r0';
  static const String keyParseApplicationId = "myappID";
  static const String keyParseMasterKey = "mymasterKey";
  static const String keyParseServerUrl =
      "https://sfuelsdev.com/parse-server/parse";

//  static const String keyParseServerUrl = "http://sowdambigajewellers.com/parse-server/";
//  static const String keyParseServerUrl = "http://134.209.150.23:1337/parse";
//  static const String keyParseServerUrl = "https://sowdambigajewellers.com/parse-server/parse";
//  static const String keyParseServerUrl = "https://zaptrdev.com/parse-server/parse";
  static const String version = 'v1.0.8';
  static const String passcode = '1221';

  //getting the gramRate from the JewelleryOp class from the parse server on gram rate updates
  static const String objectIDForGramRate = '5moQ9OOJDN';
  String decryptGeneratedCode(String scanned) {
    final key = enc.Key.fromUtf8('my 32 length key................');
    final iv = IV.fromLength(16);

    final encrypter = Encrypter(AES(key));

    // final encrypted = encrypter.encrypt(scanned, iv: iv);
    final decrypted = encrypter.decrypt(Encrypted.fromBase64(scanned), iv: iv);

    print(decrypted); // Lorem ipsum dolor sit amet, consectetur adipiscing elit
    // print(encrypted.base64); // R4PxiU3h8YoIRqVowBXm36ZcCeNeZ4s1OvVBT

    scanned = decrypted;
    return scanned;
  }
//  parse-dashboard --dev --appId myappID --masterKey mymasterKey --serverURL "https://sfuelsdev.com/parse-server/parse" --appName JewelOp
}
