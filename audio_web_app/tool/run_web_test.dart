import 'dart:async';
import 'package:process_run/shell_run.dart';

Future main() async {
  await run('dart pub run test -p chrome');
}
