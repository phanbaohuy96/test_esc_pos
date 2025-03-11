import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScannerTest extends StatefulWidget {
  const ScannerTest({super.key});

  @override
  State<ScannerTest> createState() => _ScannerTestState();
}

class _ScannerTestState extends State<ScannerTest> {
  final keydownList = ValueNotifier<List<KeyDownEvent>>([]);
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        // print(event);
        if (event is KeyDownEvent) {
          keydownList.value = [
            event,
            ...keydownList.value,
          ];
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Test scanner'),
        ),
        body: ValueListenableBuilder<List<KeyDownEvent>>(
          valueListenable: keydownList,
          builder: (context, value, child) {
            if (value.isEmpty) {
              return const Center(
                child: Text('Press any key or using the Scanner device'),
              );
            }
            final lenght = value.length;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                return Text(
                  [
                    '${(lenght - index).toString().padLeft(3)}: ',
                    'Character: ${value[index].character}',
                    'LogicalKeyID: ${value[index].logicalKey.keyId}',
                    'KeyLabel: ${value[index].logicalKey.keyLabel}',
                  ].join(' - '),
                );
              },
              itemCount: lenght,
            );
          },
        ),
      ),
    );
  }
}
