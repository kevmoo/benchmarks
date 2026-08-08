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

Map<String, double> calc(String text) {
  final jobj = jsonDecode(text) as Map<String, dynamic>;
  final coordinates = jobj['coordinates'] as List<dynamic>;

  double x = 0;
  double y = 0;
  double z = 0;
  final len = coordinates.length;

  for (int i = 0; i < len; i++) {
    final coord = coordinates[i] as Map<String, dynamic>;
    x += coord['x'] as num;
    y += coord['y'] as num;
    z += coord['z'] as num;
  }

  return {'x': x / len, 'y': y / len, 'z': z / len};
}

void main(List<String> args) async {
  final right = {'x': 2.0, 'y': 0.5, 'z': 0.25};
  for (final v in [
    '{"coordinates":[{"x":2.0,"y":0.5,"z":0.25}]}',
    '{"coordinates":[{"y":0.5,"x":2.0,"z":0.25}]}',
  ]) {
    final left = calc(v);
    if (left['x'] != right['x'] ||
        left['y'] != right['y'] ||
        left['z'] != right['z']) {
      stderr.writeln('$left != $right');
      exit(1);
    }
  }

  final text = File('/tmp/1.json').readAsStringSync();

  await notify('Dart\t${pid}');
  final results = calc(text);
  await notify('stop');

  print(results);
}
