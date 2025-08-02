import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static Preferences? instance ;
  final String keyLastDeviceId = 'lastDeviceId';
  SharedPreferences? _prefs;

  static Preferences get() {
    instance ??= Preferences._internal();
    return instance!;
  }

  Preferences._internal() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get lastDeviceId {
    return _prefs?.getString(keyLastDeviceId) ?? '';
  }

  set lastDeviceId(String deviceId) {
    _prefs?.setString(keyLastDeviceId, deviceId);
  }
}