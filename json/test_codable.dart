import 'dart:io';

import 'package:codable/codable.dart';

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

extension type const _$CoordSchema(int _value) {
  static const String nameX = 'x';
  static const String nameY = 'y';
  static const String nameZ = 'z';

  static const int keyX = 0;
  static const int keyY = 1;
  static const int keyZ = 2;

  static final JsonKeyOptions options = JsonKeyOptions.of(const [
    nameX,
    nameY,
    nameZ,
  ]);
}

extension type const _$RootSchema(int _value) {
  static const String nameCoordinates = 'coordinates';
  static const int keyCoordinates = 0;
  static final JsonKeyOptions options = JsonKeyOptions.of(const [
    nameCoordinates,
  ]);
}

Map<String, double> calc(Uint8List bytes) {
  final reader = JsonTokenReader.fromBytes(bytes);
  reader.beginObject();

  double x = 0;
  double y = 0;
  double z = 0;
  int count = 0;

  while (reader.hasNext()) {
    switch (reader.selectName(_$RootSchema.options)) {
      case _$RootSchema.keyCoordinates:
        reader.beginArray();
        while (reader.hasNext()) {
          reader.beginObject();
          double cx = 0;
          double cy = 0;
          double cz = 0;
          while (reader.hasNext()) {
            switch (reader.selectName(_$CoordSchema.options)) {
              case _$CoordSchema.keyX:
                cx = reader.readDouble();
                break;
              case _$CoordSchema.keyY:
                cy = reader.readDouble();
                break;
              case _$CoordSchema.keyZ:
                cz = reader.readDouble();
                break;
              default:
                reader.skipValue();
                break;
            }
          }
          reader.endObject();
          x += cx;
          y += cy;
          z += cz;
          count++;
        }
        reader.endArray();
        break;
      default:
        reader.skipValue();
        break;
    }
  }
  reader.endObject();

  return {'x': x / count, 'y': y / count, 'z': z / count};
}

void main(List<String> args) async {
  final right = {'x': 2.0, 'y': 0.5, 'z': 0.25};
  for (final v in [
    '{"coordinates":[{"x":2.0,"y":0.5,"z":0.25}]}',
    '{"coordinates":[{"y":0.5,"x":2.0,"z":0.25}]}',
  ]) {
    final left = calc(Uint8List.fromList(v.codeUnits));
    if (left['x'] != right['x'] ||
        left['y'] != right['y'] ||
        left['z'] != right['z']) {
      stderr.writeln('$left != $right');
      exit(1);
    }
  }

  final bytes = File('/tmp/1.json').readAsBytesSync();

  await notify('Dart Codable\t${pid}');
  final results = calc(bytes);
  await notify('stop');

  print(results);
}
