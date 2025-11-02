import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';

class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> {
  List<PtrResourceRecord> services = [];
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    const String name = '_esp32ws._tcp.local';
    final MDnsClient client = MDnsClient(
      rawDatagramSocketFactory: (dynamic host, int port,
              {bool? reuseAddress, bool? reusePort, int? ttl}) =>
          RawDatagramSocket.bind(host, port,
              reuseAddress: true, reusePort: false, ttl: 255),
    );
    await client.start();

    _subscription = client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name)).listen((PtrResourceRecord ptr) {
      if (!services.any((element) => element.domainName == ptr.domainName)) {
        setState(() {
          services.add(ptr);
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovering Devices...'),
      ),
      body: services.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(services[index].domainName),
                  onTap: () {
                    Navigator.pop(context, services[index].domainName);
                  },
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
