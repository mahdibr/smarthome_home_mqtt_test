import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Flutter ↔ ESP32',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
  late MqttServerClient client;
  bool _isConnected = false;
  bool _isSending = false;
  String receivedMessage = "هنوز پیامی دریافت نشده";

  @override
  void initState() {
    super.initState();
    connectToMqtt();
  }

  Future<void> connectToMqtt() async {
    final serverUrl = dotenv.env['SERVER_URL'] ?? 'localhost';
    final user = dotenv.env['USER'];
    final password = dotenv.env['PASS'];
    final portStr = dotenv.env['PORT'];

    client = MqttServerClient(
        serverUrl, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    client.port =
        int.tryParse(portStr ?? '') ?? 1883; // تنظیم پورت با مقدار پیش‌فرض
    // client.port = 1883;
    client.keepAlivePeriod = 20;
    client.logging(on: false);
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;

    client.onSubscribed = (topic) {
      if (kDebugMode) {
        print('Subscribed to $topic');
      }
    };

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    try {
      await client.connect(user, password);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Connection failed: $e');
      }
      client.disconnect();
    }
  }

  void onConnected() {
    setState(() {
      _isConnected = true;
    });
    debugPrint('✅ Connected to MQTT broker');

    // --- Subscribe to topic for receiving messages from ESP32 ---
    client.subscribe("flutter/topic", MqttQos.atMostOnce);

    // --- Listen to incoming messages ---
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      // final MqttPublishMessage recMess = messages![0].payload as MqttPublishMessage;
      // final String message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final MqttPublishMessage recMess =
          messages![0].payload as MqttPublishMessage;
      final bytes = recMess.payload.message;

      // استفاده از UTF-8 برای decoding
      final String message = utf8.decode(bytes);

      debugPrint('📩 Received message: $message');
      setState(() {
        receivedMessage = message;
      });
    });
  }

  void onDisconnected() {
    setState(() {
      _isConnected = false;
    });
    debugPrint('🔌 Disconnected from MQTT');
  }

  Future<void> sendMessage() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اتصال برقرار نیست!')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString('Hello ESP32 from Flutter!');
    client.publishMessage('esp32/topic', MqttQos.exactlyOnce, builder.payload!);

    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isSending = false;
    });
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ارتباط MQTT بین Flutter و ESP32'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                _isConnected ? '✅ متصل به سرور MQTT' : '🔴 در انتظار اتصال...'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSending ? null : sendMessage,
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ارسال پیام به ESP32'),
            ),
            const SizedBox(height: 30),
            const Text('📥 آخرین پیام دریافتی از ESP32:'),
            const SizedBox(height: 10),
            Text(
              receivedMessage,
              style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
