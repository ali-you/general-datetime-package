import 'dart:convert';
import 'dart:io';

void main() {
  final config = File('.dart_tool/package_config.json').absolute;
  final packages =
      (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;
  final entry = packages
      .cast<Map>()
      .singleWhere((package) => package['name'] == 'timezone');
  final packageUri = config.uri.resolve(entry['rootUri'] as String);
  final root = packageUri.path.endsWith('/')
      ? packageUri
      : packageUri.replace(path: '${packageUri.path}/');
  final input =
      File.fromUri(root.resolve('lib/data/latest.dart')).readAsStringSync();
  final revision = RegExp(r'Timezone data version: ([0-9]{4}[a-z]+)')
      .firstMatch(input)
      ?.group(1);
  if (revision == null) {
    throw StateError('Cannot identify bundled IANA data revision');
  }
  File('lib/timezone_revision.dart').writeAsStringSync(
      "// Generated from the resolved timezone package; rerun after pub get.\n"
      "const bundledTimeZoneRevision = 'IANA $revision';\n");
}
