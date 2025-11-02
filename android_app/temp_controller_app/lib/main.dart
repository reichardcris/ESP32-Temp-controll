import 'dart:io';
import 'package:flutter/material.dart';
import 'package:temp_controller_app/device_discovery_screen.dart';
import 'package:temp_controller_app/wifi_provisioning_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:multicast_dns/multicast_dns.dart';


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
  int _temperature = 22;
  WebSocketChannel? _channel;
  String? _deviceName;

  void _incrementTemperature() {
    if (_temperature < 30) {
      setState(() {
        _temperature++;
      });
      _channel?.sink.add('temp_up');
    }
  }

  void _decrementTemperature() {
    if (_temperature > 16) {
      setState(() {
        _temperature--;
      });
      _channel?.sink.add('temp_down');
    }
  }

  Future<void> _selectDevice() async {
    final String? selectedService = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeviceDiscoveryScreen()),
    );

    if (selectedService != null) {
       // _connectToDevice(selectedService);
       // For the simplified example, we connect to a hardcoded IP.
       // The default IP for an ESP32 Soft AP is 192.168.4.1
       setState(() {
         _deviceName = "ESP32-Hotspot";
         _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.4.1:8080'));
       });
    }
  }

  Future<void> _connectToDevice(String serviceName) async {
    const String name = '_esp32ws._tcp.local';
    final MDnsClient client = MDnsClient(
      rawDatagramSocketFactory: (dynamic host, int port,
              {bool? reuseAddress, bool? reusePort, int? ttl}) =>
          RawDatagramSocket.bind(host, port,
              reuseAddress: true, reusePort: false, ttl: 255),
    );
    await client.start();

    await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(serviceName))) {
      await for (final IPAddressResourceRecord ip
          in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
        
        final wsUrl = 'ws://${ip.address.address}:${srv.port}';
        setState(() {
           _deviceName = serviceName.replaceAll(".$name", "");
           _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        });
        client.stop();
        return;
      }
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Current Temperature:',
            style: TextStyle(fontSize: 24),
          ),
          Text(
            '$_temperature°C',
            style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_downward),
                iconSize: 80,
                onPressed: _decrementTemperature,
              ),
              const SizedBox(width: 80),
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                iconSize: 80,
                onPressed: _incrementTemperature,
              ),
            ],
          ),
          StreamBuilder(
            stream: _channel?.stream,
            builder: (context, snapshot) {
              return Text(snapshot.hasData ? '${snapshot.data}' : '');
            },
          )
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
