import 'dart:io';
import 'dart:typed_data';

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

List<Float64List> mmInit(int n) {
  return List<Float64List>.generate(n, (_) => Float64List(n));
}

List<Float64List> mmGen(int n, double seed) {
  final tmp = seed / n / n;
  final m = mmInit(n);
  for (int i = 0; i < n; ++i) {
    final row = m[i];
    for (int j = 0; j < n; ++j) {
      row[j] = tmp * (i - j) * (i + j);
    }
  }
  return m;
}

List<Float64List> mmMul(int n, List<Float64List> a, List<Float64List> b) {
  final m = mmInit(n);
  final c = mmInit(n);

  // Transpose matrix b into c for optimal cache performance
  for (int i = 0; i < n; ++i) {
    final rowB = b[i];
    for (int j = 0; j < n; ++j) {
      c[j][i] = rowB[j];
    }
  }

  for (int i = 0; i < n; ++i) {
    final p = a[i];
    final q = m[i];
    for (int j = 0; j < n; ++j) {
      double t = 0.0;
      final r = c[j];
      for (int k = 0; k < n; ++k) {
        t += p[k] * r[k];
      }
      q[j] = t;
    }
  }
  return m;
}

double calc(int n) {
  n = n ~/ 2 * 2;
  final a = mmGen(n, 1.0);
  final b = mmGen(n, 2.0);
  final m = mmMul(n, a, b);
  return m[n ~/ 2][n ~/ 2];
}

void main(List<String> args) async {
  final n = args.isNotEmpty ? int.parse(args[0]) : 100;

  final left = calc(101);
  final right = -18.67;
  if ((left - right).abs() > 0.1) {
    stderr.writeln('$left != $right');
    exit(1);
  }

  await notify('Dart\t${pid}');
  final results = calc(n);
  await notify('stop');

  print(results);
}
