import 'dart:convert';
import 'dart:io';

Future<void> notify(String msg) async {
  try {
    final socket = await Socket.connect('localhost', 9001);
    socket.write(msg);
    await socket.flush();
    socket.destroy();
  } catch (e) {
    // offline/standalone usage
  }
}

const int strSize = 131072;
const int tries = 8192;

void main() async {
  final b = utf8.encode('a' * strSize);
  final str2 = base64.encode(b);
  final str3 = base64.decode(str2);

  final isJit =
      Platform.executable.endsWith('/dart') ||
      Platform.executable == 'dart' ||
      Platform.executable.endsWith('dart.exe');
  final name = isJit ? 'Dart JIT' : 'Dart';

  await notify('$name\t${pid}');

  int sEncoded = 0;
  final sw1 = Stopwatch()..start();
  for (int i = 0; i < tries; i++) {
    sEncoded += base64.encode(b).length;
  }
  sw1.stop();
  final tEncoded = sw1.elapsedMilliseconds / 1000.0;

  int sDecoded = 0;
  final sw2 = Stopwatch()..start();
  for (int i = 0; i < tries; i++) {
    sDecoded += base64.decode(str2).length;
  }
  sw2.stop();
  final tDecoded = sw2.elapsedMilliseconds / 1000.0;

  await notify('stop');

  final str2Sub = str2.substring(0, 4);
  final str3Sub = utf8.decode(str3.sublist(0, 4));
  final bSub = utf8.decode(b.sublist(0, 4));

  print('encode $bSub... to $str2Sub...: $sEncoded, $tEncoded');
  print('decode $str2Sub... to $str3Sub...: $sDecoded, $tDecoded');
}
