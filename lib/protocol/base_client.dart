import 'dart:io';

mixin BaseClient {




  void scan();

  void stopScan();

  void connect(String address);

  void disconnect();

  Future<void> sendData(List<int> data);


}