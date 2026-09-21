import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot:
      (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final directory = Directory('docs/screenshots');
        await directory.create(recursive: true);
        await File('${directory.path}/$name.png').writeAsBytes(bytes);
        return true;
      },
);
