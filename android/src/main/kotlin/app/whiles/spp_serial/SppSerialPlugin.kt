package app.whiles.spp_serial

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.annotation.RequiresPermission
import androidx.core.app.ActivityCompat
import androidx.lifecycle.LifecycleOwner
import app.whiles.spp_serial.constant.ClientConnectState
import app.whiles.spp_serial.constant.ServerConnectState
import app.whiles.spp_serial.manager.ClientManager
import app.whiles.spp_serial.manager.ServerManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** SppSerialPlugin */
class SppSerialPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private var activity: Activity? = null
  private var methodChannel: MethodChannel? = null
  private var bluetoothManager: BluetoothManager? = null
  private var bluetoothAdapter: BluetoothAdapter? = null
  var imServer = false
  private val discoveredDevices: MutableList<HashMap<String, String>> = mutableListOf()

  private val receiver = object : android.content.BroadcastReceiver() {
    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    override fun onReceive(context: Context, intent: Intent) {
      val action = intent.action
      if (BluetoothDevice.ACTION_FOUND == action) {
        // Discovery has found a device
        val device: BluetoothDevice =
          intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)!!
        // Do something with the discovered device
        var map = hashMapOf<String, String>(
          "name" to device.name,
          "address" to device.address,
          "type" to when (device.type) {
            BluetoothDevice.DEVICE_TYPE_CLASSIC -> "Classic"
            BluetoothDevice.DEVICE_TYPE_LE -> "LE"
            BluetoothDevice.DEVICE_TYPE_DUAL -> "Dual"
            else -> "Unknown"
          }
        )
        discoveredDevices.add(map);
        sendScanResults(discoveredDevices)
      } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED == action) {
        // Discovery has finished
        // You can notify the user or update the UI here
        sendScanResults(discoveredDevices)
        ClientManager.get()._scanStateLive.postValue(false)
        sendClientScanState(false)
      } else if (BluetoothAdapter.ACTION_DISCOVERY_STARTED == action) {
        // Discovery has started
        discoveredDevices.clear() // Clear previous scan results
        ClientManager.get()._scanStateLive.postValue(true)
        sendClientScanState(true)
      }
    }
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel= MethodChannel(flutterPluginBinding.binaryMessenger, "channel.whiles.app/bluetooth")
    methodChannel!!.setMethodCallHandler(this)
  }

  @RequiresApi(Build.VERSION_CODES.M)
  @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
  override fun onMethodCall(call: MethodCall, result: Result) {

    if (activity == null) {
      return
    }

    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${Build.VERSION.RELEASE}")
      }
      "scan" -> {
        if (ActivityCompat.checkSelfPermission(
            activity as Context,
            Manifest.permission.BLUETOOTH_SCAN
          ) == PackageManager.PERMISSION_GRANTED
        ) {
          bluetoothAdapter?.startDiscovery()
          result.success(null)
        } else {
          result.error("PERMISSION_DENIED", "Bluetooth scan permission denied", null)
        }
        discoveredDevices.clear()
        sendScanResults(discoveredDevices)
      }
      "stopScan" -> {
        if (ActivityCompat.checkSelfPermission(
            activity as Context,
            Manifest.permission.BLUETOOTH_SCAN
          ) == PackageManager.PERMISSION_GRANTED
        ) {
          bluetoothAdapter?.cancelDiscovery()
          result.success(null)
        } else {
          result.error("PERMISSION_DENIED", "Bluetooth scan permission denied", null)
        }
      }
      "connectAsClient" -> {
        imServer = false
        val deviceId: String = call.argument<String>("deviceId") ?: ""
        if (deviceId.isEmpty()) {
          result.error("INVALID_ARGUMENT", "Device ID is required", null)

        } else if (bluetoothAdapter?.isEnabled == false) {
          val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
          activity!!.startActivityForResult(enableBtIntent, 1)
        } else {
          ClientManager.get().init(bluetoothManager!!)
          ClientManager.get().connectAsClient(deviceId)
          result.success(null)
        }
      }
      "connectAsServer" -> {
        imServer = true
        val manager = bluetoothManager ?: activity!!.getSystemService(BluetoothManager::class.java)
        val adapter = manager.adapter
        if (adapter?.isEnabled == false) {
          val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
          activity!!.startActivityForResult(enableBtIntent, 1)
        } else {
          val requestCode = 1
          val discoverableIntent =
            Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
              putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
            }
          activity!!.startActivityForResult(discoverableIntent, requestCode)
          ServerManager.get().startServer()
          result.success(null)
        }
      }
      "serverStop" -> {
        imServer = false
        ServerManager.get().stopServer()
        result.success(null)
      }
      "disconnect" -> {
        ClientManager.get().disconnect()
        result.success(null)
      }
      "sendData" -> {
        val data = call.argument<ByteArray>("data")
        if (data != null) {
          result.success(null)
          ClientManager.get().sendDataToServer(data)
        } else {
          result.error("INVALID_ARGUMENT", "Data argument is required", null)
        }
      }
      "serverSendData" -> {
        if (!imServer) {
          result.error("NOT_SERVER", "This method can only be called when connected as a server", null)

        } else {
          val data = call.argument<ByteArray>("data")
          if (data != null) {
            result.success(null)
            ServerManager.get().sendData(data)
          } else {
            result.error("INVALID_ARGUMENT", "Data argument is required", null)
          }
        }
      }
      else -> {
        result.notImplemented()
      }

    }

  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel!!.setMethodCallHandler(null)
  }

  // ActivityAware 实现
  @RequiresApi(Build.VERSION_CODES.M)
  @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    attachToActivity(binding.activity)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    detachFromActivity()
  }

  @RequiresApi(Build.VERSION_CODES.M)
  @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    attachToActivity(binding.activity)
  }

  override fun onDetachedFromActivity() {
    detachFromActivity()
  }

  @RequiresApi(Build.VERSION_CODES.M)
  @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
  fun attachToActivity(activity: Activity) {
    this.activity = activity
    bluetoothManager = activity.getSystemService(BluetoothManager::class.java)
    bluetoothAdapter = bluetoothManager?.adapter
    register()
    if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
      // Bluetooth is not supported or not enabled
      val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
      this.activity?.startActivityForResult(enableBtIntent, 1)
    }
  }

  fun detachFromActivity() {
    this.activity = null
    unregister()
  }

  private fun register() {
    this.activity?.registerReceiver(receiver, IntentFilter(BluetoothDevice.ACTION_FOUND))
    this.activity?.registerReceiver(receiver, IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED))
    this.activity?.registerReceiver(receiver, IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_STARTED))

    ClientManager.get().connStateLive.observe(this.activity!! as LifecycleOwner) {
      if (it != null) {
        when (it) {
          ClientConnectState.CONNECTED -> {
            sendClientConnectState(ClientConnectState.CONNECTED.name)
          }
          ClientConnectState.CONNECTING -> {
            sendClientConnectState(ClientConnectState.CONNECTING.name)
          }
          ClientConnectState.IDLE -> {
            sendClientConnectState(ClientConnectState.IDLE.name)
          }
        }
      }
    }



    ServerManager.get().serverConnectStateLive.observe(this.activity as LifecycleOwner){
      if (it != null) {
        when (it) {
          ServerConnectState.CONNECTED -> {
            sendServerConnectState(ServerConnectState.CONNECTED.name)
          }
          ServerConnectState.STARTING -> {
            sendServerConnectState(ServerConnectState.STARTING.name)
          }
          ServerConnectState.STOPPED -> {
            sendServerConnectState(ServerConnectState.STOPPED.name)
          }
        }
      }
    }

    ClientManager.get().receivedDataLive.observe(this.activity as LifecycleOwner) { data ->
      if (data != null) {
        sendClientReceivedData(data)
      }
    }

    ServerManager.get().receivedDataLive.observe(this.activity as LifecycleOwner) { data ->
      if (data != null) {
        sendServerReceivedData(data)
      }
    }
  }


  fun unregister(){
    activity?.unregisterReceiver(receiver)
    ClientManager.get().connStateLive.removeObservers(this.activity!! as LifecycleOwner)
    ServerManager.get().serverConnectStateLive.removeObservers(this.activity!! as LifecycleOwner)
    ClientManager.get().receivedDataLive.removeObservers(this.activity!! as LifecycleOwner)
    ServerManager.get().receivedDataLive.removeObservers(this.activity!! as LifecycleOwner)
  }

  // Send method call to Flutter
  fun sendScanResults(list: List<Map<String, String>>) {
    methodChannel?.invokeMethod("scanResults", list)
  }

  fun sendClientConnectState(state: String) {
    methodChannel?.invokeMethod("clientConnectState", state)
  }

  fun sendClientScanState(state: Boolean) {
    methodChannel?.invokeMethod("clientScanState", state)
  }

  fun sendServerConnectState(state: String) {
    methodChannel?.invokeMethod("serverConnectState", state)
  }

  fun sendServerReceivedData(data: ByteArray) {
    methodChannel?.invokeMethod("serverReceivedData", data)
  }

  fun sendClientReceivedData(data: ByteArray) {
    methodChannel?.invokeMethod("clientReceivedData", data)
  }
}
