import 'dart:async';
import 'dart:io';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../printing_service_interface.dart';

class UsbDeviceInfo extends IUsbDeviceInfo {
  @override
  Future sendData(List<int> bytes) {
    // TODO: implement sendData
    throw UnimplementedError();
  }
}

class PrintingService extends PrintingServiceInterface {
  @override
  FutureOr<bool> printSocket({
    required String host,
    required int port,
    required List<int> bytes,
  }) async {
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 5),
    );

    final chunked = bytes.splitByLength(250);
    final stream = Stream<List<int>>.fromIterable(chunked);

    // add chunked stream
    await socket.addStream(stream);

    // then disconnect
    await socket.flush();
    await socket.close();
    socket.destroy();
    return true;
  }

  @override
  FutureOr<bool> printUSB({
    required IUsbDeviceInfo device,
    required List<int> bytes,
  }) {
    return false;
  }

  @override
  FutureOr<List<UsbDeviceInfo>> getUsbDevices() {
    // TODO: implement getUsbDevice
    throw UnimplementedError();
  }
}
