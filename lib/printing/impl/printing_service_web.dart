import 'dart:async';
import 'dart:html';
import 'dart:js_util';
import 'dart:typed_data';

import 'package:usb_device/usb_device.dart' as usb_device;

import '../../usb_thermal_printer_web/usb_thermal_printer_web.dart';
import '../printing_service_interface.dart';

class USBDeviceInfo {
  final int usbVersionMajor;
  final int usbVersionMinor;
  final int usbVersionSubMinor;
  final int deviceClass;
  final int deviceSubClass;
  final int deviceProtocol;
  final int vendorId;
  final int productId;
  final int deviceVersionMajor;
  final int deviceVersionMinor;
  final int deviceVersionSubMinor;
  final String manufacturerName;
  final String productName;
  final String serialNumber;
  final bool opened;

  USBDeviceInfo(
    this.usbVersionMajor,
    this.usbVersionMinor,
    this.usbVersionSubMinor,
    this.deviceClass,
    this.deviceSubClass,
    this.deviceProtocol,
    this.vendorId,
    this.productId,
    this.deviceVersionMajor,
    this.deviceVersionMinor,
    this.deviceVersionSubMinor,
    this.manufacturerName,
    this.productName,
    this.serialNumber,
    this.opened,
  );

  static USBDeviceInfo fromDeviceJS(dynamic pairedDevice) {
    return USBDeviceInfo(
      getProperty(pairedDevice, 'usbVersionMajor'),
      getProperty(pairedDevice, 'usbVersionMinor'),
      getProperty(pairedDevice, 'usbVersionSubminor'),
      getProperty(pairedDevice, 'deviceClass'),
      getProperty(pairedDevice, 'deviceSubclass'),
      getProperty(pairedDevice, 'deviceProtocol'),
      getProperty(pairedDevice, 'vendorId'),
      getProperty(pairedDevice, 'productId'),
      getProperty(pairedDevice, 'deviceVersionMajor'),
      getProperty(pairedDevice, 'deviceVersionMinor'),
      getProperty(pairedDevice, 'deviceVersionSubminor'),
      getProperty(pairedDevice, 'manufacturerName'),
      getProperty(pairedDevice, 'productName'),
      getProperty(pairedDevice, 'serialNumber'),
      getProperty(pairedDevice, 'opened'),
    );
  }

  @override
  String toString() {
    return '''USBDeviceInfo(
    usbVersionMajor: $usbVersionMajor, 
    usbVersionMinor: $usbVersionMinor, 
    usbVersionSubMinor: $usbVersionSubMinor, 
    deviceClass: $deviceClass, 
    deviceSubClass: $deviceSubClass, 
    deviceProtocol: $deviceProtocol, 
    vendorId: $vendorId, 
    productId: $productId, 
    deviceVersionMajor: $deviceVersionMajor, 
    deviceVersionMinor: $deviceVersionMinor, 
    deviceVersionSubMinor: $deviceVersionSubMinor, 
    manufacturerName: $manufacturerName, 
    productName: $productName, 
    serialNumber: $serialNumber, 
    opened: $opened
  )''';
  }
}

class UsbDeviceInfo extends IUsbDeviceInfo {
  final dynamic pairedDevice;
  final USBDeviceInfo info;

  UsbDeviceInfo(this.pairedDevice)
      : info = USBDeviceInfo.fromDeviceJS(pairedDevice);

  @override
  Future sendData(List<int> bytes) async {
    final _printer = WebThermalPrinter();
    await _printer.pairDevice(
      vendorId: info.vendorId,
      productId: info.productId,
    );
    await _printer.printBytes(bytes);
    await _printer.closePrinter();
    // final usbDevice = usb_device.UsbDevice();
    // await usbDevice.open(pairedDevice);

    // const interfaceNumber = 0;
    // const endpointNumber = 1;
    // await usbDevice.claimInterface(pairedDevice, interfaceNumber);
    // final List<usb_device.USBConfiguration> availableConfigurations =
    //     await usbDevice.getAvailableConfigurations(pairedDevice);

    // print(info);
    // print(availableConfigurations);
    // final buffer = Uint8List.fromList([
    //   ...bytes,
    //   0x0A, // Line feed
    // ]).buffer;
    // await usbDevice.transferOut(
    //   usbDevice,
    //   endpointNumber,
    //   buffer,
    // );
    // await usbDevice.close(pairedDevice);
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
      ws
        ..send(Uint8List.fromList(bytes))
        ..close();
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
    } catch (e, stackTrace) {
      print(
        'WebUSB not supported in this browser: $e ',
      );
      print(stackTrace);
      return false;
    }
  }

  @override
  FutureOr<List<UsbDeviceInfo>> getUsbDevices() async {
    final usbDevice = usb_device.UsbDevice();
    print(await usbDevice.isSupported());

    final pairedDevices = await usbDevice.pairedDevices;
    if (pairedDevices.isEmpty) {
      final pairedDevice = await usbDevice.requestDevices([]);
      pairedDevices.add(pairedDevice);
    }
    for (final device in pairedDevices) {
      print(device.runtimeType);
      print(getPairedDeviceInfo(device));
    }

    return [
      ...pairedDevices.map(
        UsbDeviceInfo.new,
      ),
    ];
  }

  Map<String, dynamic> getPairedDeviceInfo(pairedDevice) {
    try {
      return <String, dynamic>{
        'usbVersionMajor': getProperty(pairedDevice, 'usbVersionMajor'),
        'usbVersionMinor': getProperty(pairedDevice, 'usbVersionMinor'),
        'usbVersionSubminor': getProperty(pairedDevice, 'usbVersionSubminor'),
        'deviceClass': getProperty(pairedDevice, 'deviceClass'),
        'deviceSubclass': getProperty(pairedDevice, 'deviceSubclass'),
        'deviceProtocol': getProperty(pairedDevice, 'deviceProtocol'),
        'vendorId': getProperty(pairedDevice, 'vendorId'),
        'productId': getProperty(pairedDevice, 'productId'),
        'deviceVersionMajor': getProperty(pairedDevice, 'deviceVersionMajor'),
        'deviceVersionMinor': getProperty(pairedDevice, 'deviceVersionMinor'),
        'deviceVersionSubminor':
            getProperty(pairedDevice, 'deviceVersionSubminor'),
        'manufacturerName': getProperty(pairedDevice, 'manufacturerName'),
        'productName': getProperty(pairedDevice, 'productName'),
        'serialNumber': getProperty(pairedDevice, 'serialNumber'),
        'opened': getProperty(pairedDevice, 'opened'),
      };
    } catch (e) {
      return <String, dynamic>{'Error:': 'Failed to get paired device info.'};
    }
  }
}
