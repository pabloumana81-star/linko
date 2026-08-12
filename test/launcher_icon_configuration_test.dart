import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android launcher uses LinkO adaptive, round and monochrome resources',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final adaptive = File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      ).readAsStringSync();
      final round = File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
      ).readAsStringSync();
      final colors = File(
        'android/app/src/main/res/values/launcher_icon.xml',
      ).readAsStringSync();

      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
      expect(
        manifest,
        contains('android:roundIcon="@mipmap/ic_launcher_round"'),
      );
      for (final xml in [adaptive, round]) {
        expect(xml, contains('<adaptive-icon'));
        expect(xml, contains('@color/ic_launcher_background'));
        expect(xml, contains('@drawable/ic_launcher_foreground'));
        expect(xml, contains('@drawable/ic_launcher_monochrome'));
      }
      expect(colors, contains('#CCFBF1'));
      expect(
        File(
          'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
        ).lengthSync(),
        greaterThan(0),
      );
    },
  );

  test('iOS AppIcon catalog contains every required device asset', () {
    final directory = Directory(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    );
    final catalog =
        jsonDecode(File('${directory.path}/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    final images = catalog['images'] as List<dynamic>;
    expect(images, hasLength(19));

    for (final entry in images.cast<Map<String, dynamic>>()) {
      final file = File('${directory.path}/${entry['filename']}');
      expect(file.existsSync(), isTrue, reason: file.path);
      expect(file.lengthSync(), greaterThan(0), reason: file.path);
    }
    expect(
      File('${directory.path}/Icon-App-1024x1024@1x.png').lengthSync(),
      greaterThan(10 * 1024),
    );
  });
}
