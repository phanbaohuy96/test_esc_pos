import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'printing/printing_service.dart';
import 'printing/printing_service_interface.dart';

enum PrintMode { usb, network }

class TextPrinter extends StatefulWidget {
  const TextPrinter({super.key});

  @override
  State<TextPrinter> createState() => _TextPrinterState();
}

class _TextPrinterState extends State<TextPrinter> {
  late TextEditingController printAddressCtrl = TextEditingController();
  final usbDevices = ValueNotifier<List<IUsbDeviceInfo>>([]);
  IUsbDeviceInfo? usbDevice;

  late PrintMode mode = PrintMode.usb;

  @override
  void dispose() {
    printAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generator for esc printer'),
        actions: [
          DropdownButton(
            value: mode,
            items: PrintMode.values
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              mode = v!;
            }),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (mode == PrintMode.usb) ...[
              ElevatedButton(
                onPressed: () {
                  PrintingService().getUsbDevices();
                },
                child: const Text('Get Usb devices'),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ValueListenableBuilder<List<IUsbDeviceInfo>>(
                  valueListenable: usbDevices,
                  builder: (context, devices, child) => devices.isEmpty
                      ? child!
                      : ListView.builder(
                          itemBuilder: (context, index) => InkWell(
                            onTap: () {
                              setState(() {
                                usbDevice = devices[index];
                              });
                            },
                            child: Row(
                              children: [
                                if (devices[index] == usbDevice) ...[
                                  const Icon(Icons.check),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                ],
                                Text(
                                  devices[index].toString(),
                                ),
                              ],
                            ),
                          ),
                        ),
                  child: const Center(
                    child: Text('No usb devices found!'),
                  ),
                ),
              ),
            ],
            if (mode == PrintMode.network) ...[
              TextFormField(
                controller: printAddressCtrl,
                decoration:
                    const InputDecoration(label: Text('Printer Address')),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ElevatedButton(
                    onPressed: (mode == PrintMode.usb
                            ? usbDevice != null
                            : printAddressCtrl.text.isNotEmpty)
                        ? generate
                        : null,
                    child: const Text('generate'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: (mode == PrintMode.usb
                            ? usbDevice != null
                            : printAddressCtrl.text.isNotEmpty)
                        ? printText
                        : null,
                    child: const Text('print text'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: (mode == PrintMode.usb
                            ? usbDevice != null
                            : printAddressCtrl.text.isNotEmpty)
                        ? printColumns
                        : null,
                    child: const Text('print columns'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: (mode == PrintMode.usb
                            ? usbDevice != null
                            : printAddressCtrl.text.isNotEmpty)
                        ? printImage
                        : null,
                    child: const Text('print image'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  generate() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
      'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ',
    );
    bytes += generator.text(
      'Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
      styles: const PosStyles(codeTable: 'CP1252'),
    );
    bytes += generator.text(
      'Special 2: blåbærgrød',
      styles: const PosStyles(codeTable: 'CP1252'),
    );

    bytes += generator.text('Bold text', styles: const PosStyles(bold: true));
    bytes +=
        generator.text('Reverse text', styles: const PosStyles(reverse: true));
    bytes += generator.text(
      'Underlined text',
      styles: const PosStyles(underline: true),
      linesAfter: 1,
    );
    bytes += generator.text(
      'Align left',
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      'Align center',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Align right',
      styles: const PosStyles(align: PosAlign.right),
      linesAfter: 1,
    );

    bytes += generator.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);

    bytes += generator.text(
      'Text size 200%',
      styles: const PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    // Print image:
    final ByteData data = await rootBundle.load('assets/images/logo.png');
    final Uint8List imgBytes = data.buffer.asUint8List();
    final img.Image image = img.decodeImage(imgBytes)!;

    /// bytes += generator.image(image);
    // Print image using an alternative (obsolette) command
    bytes += generator.imageRaster(image);

    // Print barcode
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    bytes += generator.barcode(Barcode.upcA(barData));

    // Print mixed (chinese + latin) text. Only for printers supporting Kanji mode
    generator.text(
      'hello ! 中文字 # world @ éphémère &',
      styles: const PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
      containsChinese: true,
    );

    bytes += generator.feed(2);
    bytes += generator.cut();
  }

  printText() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
      'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ',
    );
    bytes += generator.text(
      'Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
      styles: const PosStyles(codeTable: 'CP1252'),
    );
    bytes += generator.text(
      'Special 2: blåbærgrød',
      styles: const PosStyles(codeTable: 'CP1252'),
    );

    bytes += generator.text('Bold text', styles: const PosStyles(bold: true));
    bytes +=
        generator.text('Reverse text', styles: const PosStyles(reverse: true));
    bytes += generator.text(
      'Underlined text',
      styles: const PosStyles(underline: true),
      linesAfter: 1,
    );
    bytes += generator.text(
      'Align left',
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      'Align center',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Align right',
      styles: const PosStyles(align: PosAlign.right),
      linesAfter: 1,
    );

    bytes += generator.feed(2);
    bytes += generator.cut();

    ///
    debugPrint('start print ====================');

    await printBytes(bytes);
  }

  printColumns() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
      'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ',
    );
    bytes += generator.text(
      'Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
      styles: const PosStyles(codeTable: 'CP1252'),
    );
    bytes += generator.text(
      'Special 2: blåbærgrød',
      styles: const PosStyles(codeTable: 'CP1252'),
    );

    bytes += generator.text('Bold text', styles: const PosStyles(bold: true));
    bytes +=
        generator.text('Reverse text', styles: const PosStyles(reverse: true));
    bytes += generator.text(
      'Underlined text',
      styles: const PosStyles(underline: true),
      linesAfter: 1,
    );
    bytes += generator.text(
      'Align left',
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      'Align center',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Align right',
      styles: const PosStyles(align: PosAlign.right),
      linesAfter: 1,
    );

    bytes += generator.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);

    bytes += generator.feed(2);
    bytes += generator.cut();

    ///
    debugPrint('start print ====================');

    await printBytes(bytes);
  }

  printImage() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Print image:
    final ByteData data = await rootBundle.load('assets/images/logo.png');
    final Uint8List imgBytes = data.buffer.asUint8List();
    final img.Image image = img.decodeImage(imgBytes)!;

    // Print image using an alternative (obsolette) command
    // okay
    final ratio = image.width / image.height;
    bytes += generator.imageRaster(
      img.copyResize(
        image,
        width: 297 * 2,
        height: (image.height * ratio).toInt(),
      ),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();

    ///
    debugPrint('start print ====================');

    await printBytes(bytes);
  }

  Future printBytes(List<int> bytes) async {
    final service = PrintingService();
    try {
      if (mode == PrintMode.usb) {
        service.printUSB(
          device: usbDevice!,
          bytes: bytes,
        );
      } else {
        service.printSocket(
          host: printAddressCtrl.text,
          port: 9100,
          bytes: bytes,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
