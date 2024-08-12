import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/login_screen.dart';

void main() {
  print('ey');
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    print('el weso');
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _notificationSent = false;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _startPolling();
  }

  void _initializeNotifications() {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _startPolling() {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _checkForNewEntries(timer);
    });
  }

  Future<void> _checkForNewEntries(Timer timer) async {
    if (_notificationSent) {
      timer.cancel();
      return;
    }

    final url = 'https://apiglobex.tecno-prog.com/api/v1/business/notifications';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode({
        // Reemplaza esto con los parámetros necesarios para tu API
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Decoded data: $data');

      if (data['status'] == true && data['data'].isNotEmpty) {
        final matricula = data['data'][0]['cmatricula'];
        await _showNotification('Nuevo registro', 'Se ha registrado un nuevo contrato con la matrícula: $matricula');

        // Solicitud adicional para actualizar el estado de la notificación
        final updateUrl = 'https://apiglobex.tecno-prog.com/api/v1/business/notifications/update';
        final updateResponse = await http.post(
          Uri.parse(updateUrl),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8'
          },
          body: jsonEncode({
            
          }),
        );

        print('Update response status: ${updateResponse.statusCode}');
        print('Update response body: ${updateResponse.body}');

      }
    } else {
      print('Error al consultar la API: ${response.statusCode}');
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'description',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );

    print('Mostrar notificación: $title - $body');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Broker Rein Mobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(), // Cambia esto a tu pantalla de inicio si es necesario
    );
  }
}
