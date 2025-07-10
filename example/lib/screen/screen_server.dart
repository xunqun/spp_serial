import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:spp_serial/model/connect_state.dart';
import 'package:spp_serial/platform/spp_helper.dart';
import 'package:spp_serial/protocol/packet_server.dart';
import 'package:spp_serial_example/screen/screen_connected_server.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {

  late StreamSubscription<Uint8List>? _dataSub;
  late StreamSubscription<ServerConnectState> _connSub;

  Image? image;

  @override
  void initState() {
    WakelockPlus.enable();
    super.initState();

    _connSub = PacketServer.get().connectStateStream.listen(
      (state) {
        if (state == ServerConnectState.CONNECTED) {
          // Server started successfully
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ConnectedServerScreen()));
        }
      },
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    PacketServer.get().stopServer();
    _dataSub?.cancel();
    _connSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              StreamBuilder(
                  stream: PacketServer.get().connectStateStream,
                  initialData: ServerConnectState.STOPPED,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      ServerConnectState? state = snapshot.data;
                      return Text(
                        state?.name ?? 'Unknown state',
                        style: const TextStyle(fontSize: 20),
                      );
                    } else {
                      return const Text(
                        'Waiting for server connection state...',
                        style: TextStyle(fontSize: 20),
                      );
                    }
                  }),
              StreamBuilder(
                  stream: PacketServer.get().connectStateStream,
                  initialData: ServerConnectState.STOPPED,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      ServerConnectState? state = snapshot.data;
                      if (state == ServerConnectState.STOPPED) {
                        return ElevatedButton(
                          onPressed: () {
                            // Add your server-specific functionality here
                            // For example, start listening for connections
                            PacketServer.get().startServer();
                          },
                          child: const Text('Start Server'),
                        );
                      } else if (state == ServerConnectState.STARTING) {
                        return const Text(
                          'Server is waiting for client ...',
                          style: TextStyle(color: Colors.red, fontSize: 20),
                        );
                      } else {
                        return ElevatedButton(
                          onPressed: () {
                            // Add your server-specific functionality here
                            // For example, stop the server
                            PacketServer.get().stopServer();
                          },
                          child: const Text('Stop Server'),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  }),
              StreamBuilder(
                  stream: PacketServer.get().dataStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      Uint8List? data = snapshot.data;
                      String dataString = String.fromCharCodes(data!).trim();
                      return SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: Text(
                          dataString,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    } else {
                      return SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: const Text(
                          'Waiting for data from client...',
                          style: TextStyle(fontSize: 20),
                        ),
                      );
                    }
                  }),
              if(image != null)
                SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: image!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
