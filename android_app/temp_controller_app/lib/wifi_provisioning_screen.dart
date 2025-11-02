import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';


class WifiProvisioningScreen extends StatefulWidget {
  const WifiProvisioningScreen({super.key});

  @override
  State<WifiProvisioningScreen> createState() => _WifiProvisioningScreenState();
}

class _WifiProvisioningScreenState extends State<WifiProvisioningScreen> {
  final String _apSsid = 'ESP32-Temp-Controller';
  List<WiFiAccessPoint> _wifiNetworks = [];
  final TextEditingController _passwordController = TextEditingController();
  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    final canScan = await WiFiScan.instance.canStartScan(askPermissions: true);
    if (canScan != CanStartScan.yes) {
      return;
    }
    await WiFiScan.instance.startScan();
    final result = await WiFiScan.instance.getScannedResults();
    setState(() {
      _wifiNetworks = result;
    });
  }

  Future<void> _provisionESP32() async {
    final selectedWifi = await _showWifiSelectionDialog();
    if (selectedWifi == null) return;

    final ssid = selectedWifi['ssid'];
    final password = selectedWifi['password'];

    if (ssid == null || password == null) return;
    
    // For provisioning, we expect the phone to be connected to the ESP32's AP.
    // We will not programmatically connect to it, but instruct the user to do so.
    
    // Check if we are connected to the ESP32 AP
    final currentSsid = await _networkInfo.getWifiName();
    if (currentSsid != _apSsid) {
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to the ESP32-Temp-Controller Wi-Fi network first.')),
      );
      return;
    }

    _sendCredentialsToESP32(ssid, password);
  }

  Future<Map<String, String>?> _showWifiSelectionDialog() async {
    WiFiAccessPoint? selectedAP;
    return showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Wi-Fi Network'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _wifiNetworks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_wifiNetworks[index].ssid),
                  onTap: () {
                    selectedAP = _wifiNetworks[index];
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      if (selectedAP != null) {
        return _showPasswordDialog(selectedAP!.ssid);
      }
      return null;
    });
  }

  Future<Map<String, String>?> _showPasswordDialog(String ssid) async {
    _passwordController.clear();
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter password for $ssid'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: "Password"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop({'ssid': ssid, 'password': _passwordController.text});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendCredentialsToESP32(String ssid, String password) async {
    var url = Uri.parse('http://192.168.4.1/wifisave');
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {'s': ssid, 'p': password},
      );
       if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credentials sent successfully! ESP32 will restart.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send credentials.')),
        );
      }
    } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending credentials: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Provisioning'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _provisionESP32,
          child: const Text('Start Provisioning'),
        ),
      ),
    );
  }
}
