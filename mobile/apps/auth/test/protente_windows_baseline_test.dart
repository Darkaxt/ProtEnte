import 'dart:io';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/services/update_service.dart';
import 'package:ente_auth/utils/directory_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Windows cannot offer an upstream Ente replacement', () {
    expect(UpdateService.instance.supportsInAppUpdates(), isFalse);
    expect(
      Configuration.instance.appIdentity.passkeyRedirectUrl,
      'protente://passkey',
    );
  }, skip: !Platform.isWindows);

  test('Windows legacy migration performs no upstream data access', () async {
    var platformCalls = 0;
    const channels = [
      MethodChannel('plugins.flutter.io/path_provider'),
      MethodChannel('plugins.flutter.io/shared_preferences'),
    ];
    for (final channel in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            platformCalls++;
            throw StateError('No platform data access is allowed');
          });
    }
    try {
      await DirectoryUtils.migrateNamingChanges();
      expect(platformCalls, 0);
    } finally {
      for (final channel in channels) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    }
  }, skip: !Platform.isWindows);
}
