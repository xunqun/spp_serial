import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:spp_serial/model/connect_state.dart';
import 'package:spp_serial/model/packet.dart';
import 'package:spp_serial/protocol/factory_client_packet.dart';
import 'package:spp_serial/protocol/packet_server.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ConnectedServerScreen extends StatefulWidget {
  const ConnectedServerScreen({super.key});

  @override
  State<ConnectedServerScreen> createState() => _ConnectedServerScreenState();
}

class _ConnectedServerScreenState extends State<ConnectedServerScreen> {

  TextEditingController controller = TextEditingController();
  StreamSubscription? connStateSub;
  StreamSubscription? _dataSub;
  ClientPacketFactory? _sender;
  int progress = 0;
  int imageDeltaTime = 0;
  bool busy = false;
  List<String> imageList = [
    'assets/image/1.jpg',
    'assets/image/2.jpg',
    'assets/image/3.jpg',
    'assets/image/4.jpg',
    'assets/image/5.jpg',
    'assets/image/6.jpg',
    'assets/image/7.jpg',
    'assets/image/8.jpg',
    'assets/image/9.jpg',
    'assets/image/10.jpg',
  ];
  List<String> naviList = [
    'assets/image/1_1.jpg',
    'assets/image/1_2.jpg',
    'assets/image/1_3.jpg',
    'assets/image/1_4.jpg',
    'assets/image/1_5.jpg',
    'assets/image/1_6.jpg',
    'assets/image/1_7.jpg',
    'assets/image/1_8.jpg',
    'assets/image/1_9.jpg',
    'assets/image/1_10.jpg',
  ];

  @override
  void initState() {
    WakelockPlus.enable();
    // listen to connect state changes
    connStateSub = PacketServer.get().connectStateStream.listen((connectState) {
      if (connectState == ServerConnectState.STOPPED) {
        // Navigate back to the client screen when disconnected
        Navigator.pop(context);
      }
    });
    _dataSub = PacketServer.get().dataStream.listen((data) {
      _sender?.handleResendRequest(data);
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    connStateSub?.cancel();
    _dataSub?.cancel();
    PacketServer.get().disconnect();

    WakelockPlus.disable();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context); // Close the connected client screen
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: StreamBuilder<Uint8List>(
                      stream: PacketServer.get().dataStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          Uint8List? data = snapshot.data;
                          String dataString = String.fromCharCodes(data!).trim();
                          return Text(dataString,
                              style: const TextStyle(fontSize: 20));
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        return Text('');
                      }),
                ),
                const SizedBox(height: 20),
                Text('Packet Size $packetSize bytes'),
                Slider(
                  value: packetSize.toDouble(),
                  min: 128,
                  max: 970,
                  label: 'Packet Size: $packetSize bytes',
                  onChanged: (value) {
                    setState(() {
                      packetSize = value.toInt();
                    });
                  },
                ),
                const SizedBox(height: 20),
                Text('Packet Interval $packetInterval ms'),
                Slider(
                  value: packetInterval.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 9,
                  label: 'Packet Interval: $packetInterval ms',
                  onChanged: (value) {
                    setState(() {
                      packetInterval = value.toInt();
                    });
                  },
                ),
                // image button with asset image
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var image in imageList)
                        IconButton(
                          onPressed: () {
                            // Handle sending image
                            setState(() {
                              busy = true;
                            });
                            sendImagePacket(image);
                            setState(() {
                              busy = false;
                            });
                          },
                          icon: Image.asset(
                            image,
                            width: 50,
                            height: 50,
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton.icon( onPressed: busy ? null : () async {
                  // send all images
                  setState(() {
                    busy = true;
                  });
                  for (var image in imageList) {
                    await sendImagePacket(image);
                  }
                  setState(() {
                    busy = false;
                  });
                }, icon: Icon(Icons.numbers), label: Text('Send all images'),),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var image in naviList)
                        IconButton(
                          onPressed: () {
                            // Handle sending image
                            setState(() {
                              busy = true;
                            });
                            sendImagePacket(image);
                            setState(() {
                              busy = false;
                            });
                          },
                          icon: Image.asset(
                            image,
                            width: 50,
                            height: 50,
                          ),
                        ),
                    ],
                  ),
                ),

                ElevatedButton.icon( onPressed: busy ? null : () async {
                  // send all images
                  setState(() {
                    busy = true;
                  });
                  for (var image in naviList) {
                    await sendImagePacket(image);
                  }
                  setState(() {
                    busy = false;
                  });
                }, icon: Icon(Icons.local_shipping_outlined), label: Text('Send all images'),),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(value: progress / 100),
                      const SizedBox(width: 16),
                      Text('$imageDeltaTime ms', style: const TextStyle(fontSize: 28, color: Colors.blue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendImagePacket(String image) async{
    var start = DateTime.now().millisecondsSinceEpoch;
    var packetSender = await ClientPacketFactory.fromAsset(0, image);
    _sender = packetSender;
    List<List<int>> packets = packetSender.getPackets();
    int count = 0;
    for (var packet in packets) {
      await PacketServer.get().sendData(packet);
      count++;
      setState(() {
        progress = (count / packets.length * 100).toInt();
      });
      await Future.delayed(Duration(milliseconds: packetInterval));
    }
    setState(() {
      imageDeltaTime = DateTime.now().millisecondsSinceEpoch - start;
    });


  }
}
