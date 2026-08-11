import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/auth_redirect_policy.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/repositories/authentication_repository.dart';

void main() {
  test('production runners use the final LinkO application identity', () {
    final androidGradle = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    final androidActivity = File(
      'android/app/src/main/kotlin/com/linko/app/MainActivity.kt',
    ).readAsStringSync();
    final iosProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final macosConfig = File(
      'macos/Runner/Configs/AppInfo.xcconfig',
    ).readAsStringSync();
    final macosProject = File(
      'macos/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final linuxConfig = File('linux/CMakeLists.txt').readAsStringSync();

    expect(androidGradle, contains('namespace = "com.linko.app"'));
    expect(androidGradle, contains('applicationId = "com.linko.app"'));
    expect(androidActivity, contains('package com.linko.app'));
    expect(iosProject, contains('PRODUCT_BUNDLE_IDENTIFIER = com.linko.app;'));
    expect(
      iosProject,
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.linko.app.RunnerTests;'),
    );
    expect(macosConfig, contains('PRODUCT_BUNDLE_IDENTIFIER = com.linko.app'));
    expect(
      macosProject,
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.linko.app.RunnerTests;'),
    );
    expect(linuxConfig, contains('set(APPLICATION_ID "com.linko.app")'));

    for (final productionFile in [
      androidGradle,
      androidActivity,
      iosProject,
      macosConfig,
      macosProject,
      linuxConfig,
    ]) {
      expect(productionFile, isNot(contains('com.example.linko')));
    }
  });

  test('mobile and desktop runners register the authentication callback', () {
    final android = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final ios = File('ios/Runner/Info.plist').readAsStringSync();
    final macos = File('macos/Runner/Info.plist').readAsStringSync();

    expect(android, contains('android:scheme="io.supabase.linko"'));
    expect(android, contains('android:host="login-callback"'));
    expect(ios, contains('<string>io.supabase.linko</string>'));
    expect(macos, contains('<string>io.supabase.linko</string>'));
    expect(
      File('.env.example').readAsStringSync(),
      contains('AUTH_REDIRECT_URL=io.supabase.linko://login-callback/'),
    );
  });

  test('Android release never uses a debug signing identity', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final ignored = File('android/.gitignore').readAsStringSync();
    final example = File('android/key.properties.example').readAsStringSync();

    expect(gradle, isNot(contains('getByName("debug")')));
    expect(gradle, contains('rootProject.file("key.properties")'));
    expect(gradle, contains('signingConfigs.getByName("release")'));
    expect(ignored, contains('key.properties'));
    expect(ignored, contains('**/*.jks'));
    expect(example, isNot(contains('storePassword=android')));
  });

  test('mobile manifests request no broad media or storage permissions', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final ios = File('ios/Runner/Info.plist').readAsStringSync();

    expect(manifest, contains('android.permission.INTERNET'));
    for (final permission in [
      'READ_EXTERNAL_STORAGE',
      'WRITE_EXTERNAL_STORAGE',
      'READ_MEDIA_IMAGES',
      'CAMERA',
    ]) {
      expect(manifest, isNot(contains(permission)));
    }
    expect(ios, isNot(contains('NSPhotoLibraryUsageDescription')));
    expect(ios, isNot(contains('NSCameraUsageDescription')));
  });

  test('native callback only accepts the exact LinkO scheme and host', () {
    expect(
      () => AuthRedirectPolicy.validate(
        'io.supabase.linko://login-callback/',
        AuthRedirectTarget.native,
      ),
      returnsNormally,
    );
    for (final unsafe in [
      'https://externo.example/callback',
      'io.supabase.linko://otro-host/',
      'io.supabase.linko://login-callback/?access_token=secret',
      'otro.esquema://login-callback/',
    ]) {
      expect(
        () => AuthRedirectPolicy.validate(unsafe, AuthRedirectTarget.native),
        throwsA(isA<AuthenticationLaunchException>()),
      );
    }
  });

  test('web callback accepts only a clean current origin', () {
    expect(
      () => AuthRedirectPolicy.validate(
        'http://localhost:7357',
        AuthRedirectTarget.web,
      ),
      returnsNormally,
    );
    expect(
      () => AuthRedirectPolicy.validate(
        'http://127.0.0.1:7357',
        AuthRedirectTarget.web,
      ),
      returnsNormally,
    );
    expect(
      () => AuthRedirectPolicy.validate(
        'http://app.linko.example',
        AuthRedirectTarget.web,
      ),
      throwsA(isA<AuthenticationLaunchException>()),
    );
    expect(
      () => AuthRedirectPolicy.validate(
        'https://app.linko.example',
        AuthRedirectTarget.web,
      ),
      returnsNormally,
    );
    expect(
      () => AuthRedirectPolicy.validate(
        'https://app.linko.example/auth?next=https://externo.example',
        AuthRedirectTarget.web,
      ),
      throwsA(isA<AuthenticationLaunchException>()),
    );
  });

  test('web metadata has production copy and no forced mobile orientation', () {
    final index = File('web/index.html').readAsStringSync();
    final manifest = File('web/manifest.json').readAsStringSync();

    expect(index, isNot(contains('A new Flutter project')));
    expect(manifest, isNot(contains('A new Flutter project')));
    expect(manifest, isNot(contains('portrait-primary')));
    expect(index, contains('LinkO conecta clientes'));
  });

  test(
    'Supabase configuration requires the native callback without fallback',
    () {
      const config = BackendConfig(
        mode: BackendMode.supabase,
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'public-key',
      );
      expect(config.validate, throwsA(isA<BackendConfigurationException>()));
    },
  );

  test(
    'new Supabase profiles require onboarding without changing old rows',
    () {
      final migration = File(
        'supabase/migrations/202608080004_auth_onboarding_default.sql',
      ).readAsStringSync();

      expect(
        migration,
        contains('alter column onboarding_completed set default false'),
      );
      expect(
        migration.toLowerCase(),
        isNot(contains('update public.profiles')),
      );
    },
  );
}
