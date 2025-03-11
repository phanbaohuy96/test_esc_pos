import 'dart:async';

abstract class IUsbDeviceInfo {
  Future sendData(List<int> bytes);
}

abstract class PrintingServiceInterface {
  FutureOr<bool> printSocket({
    required String host,
    required int port,
    required List<int> bytes,
  });

  FutureOr<bool> printUSB({
    required IUsbDeviceInfo device,
    required List<int> bytes,
  });

  FutureOr<List<IUsbDeviceInfo>> getUsbDevices();
}
