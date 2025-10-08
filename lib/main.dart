/*
  نویسنده: مهدی بهرام
  https://www.instagram.com/mahdi1bahram/

  شرکت: مخترعین شاتوت الکترونیک
  وبسایت: shahtut.com

  طراحی شده به سفارش شرکت  بهرام کیت 
  وب سایت فروشگاه : bahramkit.com
  https://www.instagram.com/bahramkit/
*/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart'; // برای باز کردن لینک

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
  bool _isConnecting = false;
  bool _isSending = false;
  String receivedMessage = "هنوز پیامی دریافت نشده";
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>?
      _updatesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMqttClient();
  }

  void _initializeMqttClient() {
    final serverUrl = dotenv.env['SERVER_URL'] ?? 'localhost';
    // final user = dotenv.env['USER'];
    // final password = dotenv.env['PASS'];
    final strport = dotenv.env['PORT'];
    client = MqttServerClient(
        serverUrl, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');

    client.port = int.tryParse(strport ?? '') ?? 1883;
    client.keepAlivePeriod = 30;
    client.logging(on: true); // برای دیباگ بهتر روشنش کردم
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = (topic) {
      if (kDebugMode) {
        print('Subscribed to $topic');
      }
    };

    // فعال کردن reconnect اتوماتیک
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    final user = dotenv.env['USER'];
    final password = dotenv.env['PASS'];

    try {
      if (kDebugMode) {
        print('🔄 Attempting to connect to MQTT broker...');
      }
      await client.connect(user, password);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Connection failed: $e');
      }
      setState(() {
        _isConnecting = false;
        _isConnected = false;
      });

      // تلاش مجدد برای اتصال
      _scheduleReconnect();
    }
  }

  void _onConnected() {
    if (kDebugMode) {
      print('✅ Connected to MQTT broker');
    }

    setState(() {
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0; // reset reconnect attempts
    });

    // لغو تایمر reconnect اگر فعال باشد
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // subscribe به topic
    client.subscribe("flutter/topic", MqttQos.atMostOnce);

    // گوش دادن به پیام‌های دریافتی
    _updatesSubscription = client.updates!.listen(_handleIncomingMessages);
  }

  void _handleIncomingMessages(
      List<MqttReceivedMessage<MqttMessage?>>? messages) {
    if (messages == null || messages.isEmpty) return;

    try {
      final MqttPublishMessage recMess =
          messages[0].payload as MqttPublishMessage;
      final bytes = recMess.payload.message;
      final String message = utf8.decode(bytes);

      if (kDebugMode) {
        print('📩 Received message: $message');
      }
      setState(() {
        receivedMessage = message;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing incoming message: $e');
      }
    }
  }

  void _onDisconnected() {
    if (kDebugMode) {
      print('🔌 Disconnected from MQTT');
    }

    setState(() {
      _isConnected = false;
      _isConnecting = false;
    });

    // تلاش مجدد برای اتصال اگر به صورت دستی قطع نشده باشد
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectAttempts++;
    if (kDebugMode) {
      print(
          '🔄 Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts');
    }

    _reconnectTimer = Timer(Duration(seconds: _calculateReconnectDelay()), () {
      if (!_isConnected && !_isConnecting) {
        if (kDebugMode) {
          print(
              '🔄 Executing reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts');
        }
        _connectToMqtt();
      }
    });
  }

  int _calculateReconnectDelay() {
    // exponential backoff: 2, 4, 8, 16, 32 ثانیه
    return _reconnectAttempts <= 1 ? 2 : (1 << _reconnectAttempts);
  }

  Future<void> sendMessage() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اتصال برقرار نیست!')),
      );
      // تلاش برای اتصال مجدد
      _connectToMqtt();
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString('Hello ESP32 from Flutter!');
      client.publishMessage(
          'esp32/topic', MqttQos.exactlyOnce, builder.payload!);
      if (kDebugMode) {
        print('📤 Message sent to ESP32');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ارسال پیام: $e')),
      );
    }

    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isSending = false;
    });
  }

  Future<void> _manualReconnect() async {
    if (_isConnecting) return;

    if (kDebugMode) {
      print('🔄 Manual reconnect requested');
    }
    _reconnectAttempts = 0;
    await _connectToMqtt();
  }

  // تابع برای باز کردن لینک
  Future<void> launchCustomURL(String urlString) async {
    final Uri url = Uri.parse(urlString); // آدرس دلخواه شما
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _updatesSubscription?.cancel();
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ارتباط MQTT بین Flutter و ESP32'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.wifi : Icons.wifi_off),
            onPressed: _manualReconnect,
            tooltip: 'اتصال مجدد',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔹 لوگو در بالا یا وسط صفحه
            Padding(
              padding: const EdgeInsets.only(top: 50.0, bottom: 10.0),
              child: Center(
                child: GestureDetector(
                  onTap: () => launchCustomURL('https://www.bahramkit.com/'),
                  child: Image.asset(
                    'assets/bahramkit logo simple.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only( bottom: 80.0),
              child: Center(
                child: const Text('فروشگاه بهرام کیت '),
              ),
            ),

            // وضعیت اتصال
            _buildConnectionStatus(),
            const SizedBox(height: 20),

            // دکمه ارسال پیام
            ElevatedButton(
              onPressed: _isSending ? null : sendMessage,
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ارسال پیام به ESP32'),
            ),
            const SizedBox(height: 10),

            // دکمه اتصال مجدد
            if (!_isConnected && !_isConnecting)
              ElevatedButton(
                onPressed: _manualReconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('تلاش مجدد برای اتصال'),
              ),

            const SizedBox(height: 30),
            const Text('📥 آخرین پیام دریافتی از ESP32:'),
            const SizedBox(height: 10),
            Text(
              receivedMessage,
              style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),

            // 🔹 متن پایین صفحه با لینک قابل کلیک
            Padding(
              padding: const EdgeInsets.only(top: 150.0, bottom: 20.0),
              child: GestureDetector(
                onTap: () => launchCustomURL('https://shahtut.com/'),
                child: RichText(
                  text: TextSpan(
                    text: 'طراحی شده توسط ',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    children: const [
                      TextSpan(
                        text: 'تیم شاتوت',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (_isConnecting) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 10),
          Text('در حال اتصال... ($_reconnectAttempts/$_maxReconnectAttempts)'),
        ],
      );
    } else if (_isConnected) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi, color: Colors.green),
          const SizedBox(width: 10),
          Text('✅ متصل به سرور MQTT'),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.red),
          const SizedBox(width: 10),
          Text('🔴 قطع ارتباط ($_reconnectAttempts/$_maxReconnectAttempts)'),
        ],
      );
    }
  }
}
