import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Sender',
      debugShowCheckedModeBanner: false,
      // --- پیکربندی برای زبان فارسی و چیدمان راست-به-چپ ---
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // home: MqttScreen(),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MqttScreen(),
      ),
    );
  }
}

class MqttScreen extends StatefulWidget {
  const MqttScreen({super.key});

  @override
  State<MqttScreen> createState() => _MqttScreenState();
}

class _MqttScreenState extends State<MqttScreen> {
  bool _isSending = false;

  Future<void> sendMessage() async {
    setState(() {
      _isSending = true;
    });

    final serverUrl = dotenv.env['SERVER_URL']!;
    final user = dotenv.env['USER'];
    final password = dotenv.env['PASS'];
    
    final client = MqttServerClient(serverUrl, 'flutter_client');
    client.port = 1883;
    client.logging(on: true);

    client.onConnected = () {
      if (kDebugMode) {
        print('Connected to broker');
      }
    };

    client.onDisconnected = () {
      if (kDebugMode) {
        print('Disconnected');
      }
    };

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean();
    client.connectionMessage = connMessage;

    try {
      await client.connect(user, password);
    } catch (e) {
      if (kDebugMode) {
        print('Connection failed: $e');
      }
      client.disconnect();
      setState(() {
        _isSending = false;
      });
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString('Hello ESP32 from Flutter!');
    client.publishMessage('esp32/topic', MqttQos.exactlyOnce, builder.payload!);

    await Future.delayed(Duration(seconds: 2));
    client.disconnect();

    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تست اتصال mqtt به esp32'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isSending ? null : sendMessage,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('ارسال پیام MQTT'),
            ),
            SizedBox(height: 20),
            if (_isSending) Text('در حال ارسال پیام  ...'),
          ],
        ),
      ),
    );
  }
}
