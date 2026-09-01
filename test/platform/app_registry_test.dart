/// Guards the contract that makes the platform extensible: the registry is the
/// only place that decides which applications exist and which ones a session
/// may open.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ideco_platform/platform/registry/app_registry.dart';

void main() {
  group('AppRegistry', () {
    test('ships the two current applications with their legacy app ids', () {
      expect(AppRegistry.byId('inspection')?.serverAppId, 20);
      expect(AppRegistry.byId('meter_reading')?.serverAppId, 49);
    });

    test('keeps the login DataType each application already used', () {
      expect(AppRegistry.byId('inspection')?.loginDataType, 14);
      expect(AppRegistry.byId('meter_reading')?.loginDataType, 1);
    });

    test('module ids, routes and server app ids are unique', () {
      final ids = AppRegistry.modules.map((m) => m.id).toList();
      final routes = AppRegistry.modules.map((m) => m.route).toList();
      final appIds = AppRegistry.modules.map((m) => m.serverAppId).toList();

      expect(ids.toSet().length, ids.length);
      expect(routes.toSet().length, routes.length);
      expect(appIds.toSet().length, appIds.length);
    });

    test('every module declares a registered accent colour', () {
      // Guards the palette contract: an unknown accent would silently fall
      // back to blue and make two cards indistinguishable.
      for (final module in AppRegistry.modules) {
        expect(
          ['blue', 'teal', 'amber', 'violet', 'rose', 'green', 'slate', 'cyan'],
          contains(module.accent),
          reason: '${module.id} uses an unregistered accent',
        );
      }
    });

    test('authorisedFor returns only granted modules, in registry order', () {
      final both = AppRegistry.authorisedFor(['meter_reading', 'inspection']);
      expect(both.map((m) => m.id), ['inspection', 'meter_reading']);

      final single = AppRegistry.authorisedFor(['meter_reading']);
      expect(single.map((m) => m.id), ['meter_reading']);
    });

    test('authorisedFor ignores ids that this build does not know', () {
      // A cached session from a newer build must not crash an older one.
      final modules = AppRegistry.authorisedFor(['inspection', 'gis_beta']);
      expect(modules.map((m) => m.id), ['inspection']);
    });

    test('an empty grant list yields no modules', () {
      expect(AppRegistry.authorisedFor(const []), isEmpty);
    });
  });
}
