import 'dart:async';
import 'package:process_run/shell_run.dart';

Future main() async {
  print('Serving `web_dev` on http://localhost:8060/menu/index.html');
  while (true) {
    try {
      await run('webdev serve example:8060 --auto=refresh --hostname 0.0.0.0');
    } catch (e) {
      print('restarting $e');
    }
  }
}
