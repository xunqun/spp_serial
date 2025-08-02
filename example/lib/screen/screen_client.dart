import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spp_serial/model/connect_state.dart';
import 'package:spp_serial/protocol/packet_client.dart';
import 'package:spp_serial_example/utils/preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';


import 'screen_connected_client.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  bool isScanning = false;
  StreamSubscription<bool>? _scanSub;
  StreamSubscription<ClientConnectState>? _connSub;

  @override
  void initState() {
    super.initState();
    _scanSub =PacketClient.get().scanStateStream.listen((scanning) {
      setState(() {
        isScanning = scanning;
      });
    });

    _connSub = PacketClient.get().connectStateStream.listen((connectState) {
      if (connectState == ClientConnectState.CONNECTED) {
        // Navigate to the connected client screen
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ConnectedClientScreen()));

      } else {

      }
    });
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    String lastDeviceId = Preferences.get().lastDeviceId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const Text(
                'This is the client screen.',
              ),
              if(lastDeviceId.isNotEmpty) ElevatedButton(onPressed: (){
                PacketClient.get().connect(lastDeviceId);
              }, child: Text("try last device")),
              ElevatedButton(
                onPressed: () {
                  // Add your client-specific functionality here
                  if(isScanning) {
                    PacketClient.get().stopScan();
                  } else {
                    PacketClient.get().scan();
                  }
                },
                child: Text( isScanning ? 'stop' : 'Search for devices'),
              ),
              Expanded(child: StreamBuilder<List<Map<String, String?>>>(
                stream: PacketClient.get().scanResultSteam,
                initialData: [],
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No devices found'));
                  }
                  final devices = snapshot.data!;
                  var validDevices = findCandidateDevices(devices);
                  return ListView.builder(itemBuilder: (context, index) {
                    // Replace with your device list
                    var name  = validDevices[index]['name'] == null || validDevices[index]['name'] == '' ? 'NoName Device' : validDevices[index]['name'];
                    return ListTile(
                      title: Text(name),
                      trailing: Text(validDevices[index]['type'] ?? ''),
                      onTap: () {
                        // Handle device selection
                        var address = validDevices[index]['address'];
                        PacketClient.get().connect(address);
                        Preferences.get().lastDeviceId = address;
                      },
                    );
                  }, itemCount: validDevices.length,);
                }
              )),
            ],
          ),
        ),
      ),
    );
  }

  findCandidateDevices(List<Map<String, String?>> devices) {
    // fileter out device's UUIDs contains SERVICE_UUID
    // const SERVICE_UUID = '00001101-0000-1000-8000-00805F9B34FB';
    // return devices.where((device) {
    //   final uuids = device['uuids']?.split(',') ?? [];
    //   return uuids.any((uuid) => uuid.toLowerCase() == SERVICE_UUID.toLowerCase());
    // }).toList();

    // fileter out devices that are no name
    devices = devices.where((device) {
      final name = device['name']?.trim() ?? '';
      return name.isNotEmpty && name != 'NoName Device';
    }).toList();
    return devices;
  }
}
