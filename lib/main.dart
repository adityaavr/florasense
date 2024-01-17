import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/io.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Monitoring System',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.green[800],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
          textTheme: ButtonTextTheme.primary,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shadowColor: Colors.green.shade200,
          elevation: 4,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _channel =
      IOWebSocketChannel.connect('ws://your_esp8266_IP_address:81');

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  Future<void> openWiFiSettings() async {
    if (Platform.isAndroid) {
      const wifiSettingsUrlAndroid = 'android.settings.WIFI_SETTINGS';
      if (await canLaunch(wifiSettingsUrlAndroid)) {
        await launch(wifiSettingsUrlAndroid);
      } else {
        print('Could not launch $wifiSettingsUrlAndroid');
        // Consider showing an alert/dialog to the user.
      }
    } else if (Platform.isIOS) {
      // For iOS, we can try to open the app settings, as there's no direct URL for Wi-Fi settings.
      const appSettingsUrlIOS = 'App-Prefs:';
      if (await canLaunch(appSettingsUrlIOS)) {
        await launch(appSettingsUrlIOS);
      } else {
        print('Could not launch $appSettingsUrlIOS');
        // Consider showing an alert/dialog to the user.
      }
    } else {
      print('Wi-Fi settings not accessible on this platform');
      // Consider showing an alert/dialog to the user.
    }
  }

  void waterPlantsNow() {
    _channel.sink.add('WATER_NOW');
  }

  void setWateringTimer() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      _channel.sink.add('SET_TIMER:${pickedTime.hour}:${pickedTime.minute}');
    }
  }

  void setWateringSchedule() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _channel.sink.add('SET_SCHEDULE:${finalDateTime.toIso8601String()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Plant Monitoring System',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder(
          stream: _channel.stream,
          builder: (context, snapshot) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Live Sensor Data',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 10),
                          Text(
                            snapshot.hasData
                                ? snapshot.data.toString()
                                : 'Waiting for data...',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.water_drop),
                    label: const Text('Water Plants Now'),
                    onPressed: waterPlantsNow,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.green[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.timer),
                    label: const Text('Set Watering Timer'),
                    onPressed: setWateringTimer,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.green[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Set Watering Schedule'),
                    onPressed: setWateringSchedule,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.green[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openWiFiSettings,
        tooltip: 'Open Wi-Fi Settings',
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
