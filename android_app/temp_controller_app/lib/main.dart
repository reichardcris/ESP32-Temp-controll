import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_oknob/flutter_oldschool_knob.dart';
import 'package:flutter_oknob/widgets/flutter_widget_painter.dart';
import 'package:temp_controller_app/device_discovery_screen.dart';
import 'package:temp_controller_app/wifi_provisioning_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:multicast_dns/multicast_dns.dart';


enum TempSetting { low, medium, highFreeze }


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temperature Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Temperature Control'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isOn = false;
  TempSetting _tempSetting = TempSetting.low;
  WebSocketChannel? _channel;
  String? _deviceName;
  final List<Color> _tempSettingColors = [Colors.black, Colors.blue, Colors.red];

  void _togglePower() {
    setState(() {
      _isOn = !_isOn;
    });
    if (_isOn) {
      _channel?.sink.add('on');
    } else {
      _channel?.sink.add('off');
    }
  }

  void _setTempSetting(TempSetting setting) {
    if (!_isOn) return;
    setState(() {
      _tempSetting = setting;
    });
    switch (setting) {
      case TempSetting.low:
        _channel?.sink.add('temp_low');
        break;
      case TempSetting.medium:
        _channel?.sink.add('temp_medium');
        break;
      case TempSetting.highFreeze:
        _channel?.sink.add('temp_high_freeze');
        break;
    }
  }

  Future<void> _selectDevice() async {
    final String? selectedService = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeviceDiscoveryScreen()),
    );

    if (selectedService != null && mounted) {
      // _connectToDevice(selectedService);
      // For the simplified example, we connect to a hardcoded IP.
      // The default IP for an ESP32 Soft AP is 192.168.4.1
      final channel =
          WebSocketChannel.connect(Uri.parse('ws://192.168.4.1:8080'));
      channel.stream.listen(
        (data) {
          // You can handle incoming data here if needed
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _channel = null;
              _deviceName = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Device disconnected.')),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _channel = null;
              _deviceName = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Connection error: $error')),
            );
          }
        },
      );
      setState(() {
        _deviceName = "ESP32-Hotspot";
        _channel = channel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_deviceName ?? 'No Device'),
      ),
      body: _channel == null ? buildDeviceSelector() : buildTemperatureControls(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WifiProvisioningScreen()),
          );
        },
        child: const Icon(Icons.wifi_tethering),
      ),
    );
  }

  Widget buildDeviceSelector() {
    return Center(
      child: ElevatedButton(
        onPressed: _selectDevice,
        child: const Text('Select a Device'),
      ),
    );
  }

  Widget buildTemperatureControls() {
    
    print("_isOn : $_isOn");

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Temperature Setting:',
            style: TextStyle(fontSize: 24),
          ),
          Text(
            _isOn ? _tempSetting.toString().split('.').last.replaceAll('highFreeze', 'HIGH FREEZE').toUpperCase() : 'Off',
            style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            iconSize: 80,
            color: _isOn ? Colors.green : Colors.red,
            onPressed: _togglePower,
          ),
          const SizedBox(height: 40),
          FlutterOKnob(
            knobvalue: _tempSetting.index.toDouble(),
            knobLabel: Text(_tempSetting.toString().split('.').last.replaceAll('highFreeze', 'HIGH FREEZE').toUpperCase()),
            minValue: 0,
            maxValue: 2,
            showKnobLabels: false,
            size: 300,
            outerRingGradient: const LinearGradient(colors: [Colors.deepPurple, Colors.blue]),
            maxRotationAngle: 180,
            onChanged: (value) {
              if (!_isOn) return;
              int roundedValue = value.round();
              if (roundedValue != _tempSetting.index) {
                _setTempSetting(TempSetting.values[roundedValue]);
              }
            },
            // knobColor: _tempSetting == TempSetting.highFreeze
            //     ? Colors.red
            //     : _tempSetting == TempSetting.medium
            //         ? Colors.blue
            //         : Colors.black,
            markerColor: _tempSettingColors[_tempSetting.index],
            // label: _tempSetting.toString().split('.').last.replaceAll('highFreeze', 'HIGH FREEZE').toUpperCase(),
          ),
          // StreamBuilder(
          //   stream: _channel?.stream,
          //   builder: (context, snapshot) {
          //     return Text(snapshot.hasData ? '${snapshot.data}' : '');
          //   },
          // )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
