import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tagline/services/app_paths.dart';
import 'package:tagline/services/portable_data_migrator.dart';
import 'package:tagline/services/secure_settings.dart';

void main() {
  tearDown(() {
    AppPaths.debugReset();
  });

  test('init with overrideRoot creates portable layout', () async {
    final root = await Directory.systemTemp.createTemp('tagline_app_paths_');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final paths = await AppPaths.init(overrideRoot: root);

    expect(paths.root.path, root.path);
    expect(await paths.tempDirectory.exists(), isTrue);
    expect(AppPaths.isInitialized, isTrue);
    expect((await AppPaths.portableDocumentsDirectory()).path, root.path);
  });

  test('migrator copies legacy history into userdata once', () async {
    final portableRoot =
        await Directory.systemTemp.createTemp('tagline_portable_');
    final legacyDocs =
        await Directory.systemTemp.createTemp('tagline_legacy_docs_');
    addTearDown(() async {
      for (final dir in [portableRoot, legacyDocs]) {
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    });

    await File(p.join(legacyDocs.path, AppPaths.historyFileName)).writeAsString(
      '[{"id":"1"}]',
    );

    final paths = await AppPaths.init(overrideRoot: portableRoot);
    await PortableDataMigrator.migrateIfNeeded(
      paths,
      documentsDirectory: () async => legacyDocs,
    );

    expect(await paths.historyFile.exists(), isTrue);
    expect(await paths.historyFile.readAsString(), '[{"id":"1"}]');
    expect(
      await File(p.join(paths.root.path, PortableDataMigrator.markerName))
          .exists(),
      isTrue,
    );

    // Second run is a no-op even if legacy still has the file.
    await paths.historyFile.delete();
    await PortableDataMigrator.migrateIfNeeded(
      paths,
      documentsDirectory: () async => legacyDocs,
    );
    expect(await paths.historyFile.exists(), isFalse);
  });

  test('SecureSettings reads and writes under override root', () async {
    final root = await Directory.systemTemp.createTemp('tagline_settings_');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final settings = SecureSettings(overrideRoot: root);
    await settings.setApiKey('sk-test');
    await settings.setModel('openai/gpt-4o');
    await settings.setUseSubscription(false);
    await settings.setFavoriteGenreIds(const ['modern_pop']);

    expect(await settings.getApiKey(), 'sk-test');
    expect(await settings.getModel(), 'openai/gpt-4o');
    expect(await settings.getUseSubscription(), isFalse);
    expect(await settings.getFavoriteGenreIds(), ['modern_pop']);
    expect(
      await File(p.join(root.path, AppPaths.apiKeyFileName)).exists(),
      isTrue,
    );
    expect(
      await File(p.join(root.path, AppPaths.settingsFileName)).exists(),
      isTrue,
    );
  });
}
