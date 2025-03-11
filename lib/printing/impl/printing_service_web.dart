import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:usb_device/usb_device.dart';

import '../printing_service_interface.dart';

class UsbDeviceInfo extends IUsbDeviceInfo {
  final dynamic pairedDevice;

  UsbDeviceInfo(this.pairedDevice);

  @override
  Future sendData(List<int> bytes) async {
    final UsbDevice usbDevice = UsbDevice();
    // get device's info
    final USBDeviceInfo deviceInfo =
        await usbDevice.getPairedDeviceInfo(pairedDevice);
    await usbDevice.open(pairedDevice);
    await usbDevice.transferOut(
      deviceInfo,
      1,
      Uint8List.fromList(bytes).buffer,
    );
    await usbDevice.close(pairedDevice);
  }

  @override
  String toString() => '$hashCode: $pairedDevice';
}

class PrintingService extends PrintingServiceInterface {
  @override
  FutureOr<bool> printSocket({
    required String host,
    required int port,
    required List<int> bytes,
  }) {
    final url = 'ws://$host:$port'; // Ensure your printer supports WebSockets
    final ws = WebSocket(url);

    final completer = Completer<bool>();

    ws.onOpen.listen((event) {
      ws.send(Uint8List.fromList(bytes)); // Send the bytes
      ws.close();
    });

    ws.onClose.listen((event) => completer.complete(true));
    ws.onError.listen((event) => completer.complete(false));

    return completer.future;
  }

  @override
  FutureOr<bool> printUSB({
    required IUsbDeviceInfo device,
    required List<int> bytes,
  }) async {
    try {
      await device.sendData(bytes);

      print('Print job sent via USB!');
      return true;
    } catch (e) {
      print('WebUSB not supported in this browser');
      return false;
    }
  }

  @override
  FutureOr<List<UsbDeviceInfo>> getUsbDevices() async {
    final UsbDevice usbDevice = UsbDevice();
    final pairedDevices = await usbDevice.pairedDevices;
    print(pairedDevices);
    for (final device in pairedDevices) {
      print(device);
    }

    return [
      ...pairedDevices.map(
        UsbDeviceInfo.new,
      ),
    ];
  }
}
