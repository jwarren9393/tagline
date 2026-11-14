import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves Tagline's portable on-disk layout.
///
/// **Windows:** `<folder containing tagline.exe>/userdata/`
/// **Android:** `<app external files>/userdata/` when available (USB-visible
/// under `Android/data/<package>/files/userdata`), else app documents.
/// **Linux:** `<documents>/userdata/` (desktop zip can still copy the folder).
///
/// History JSON, settings, API key file, and temp export staging live under
/// this single [root] so a Windows install folder is self-contained.
class AppPaths {
  AppPaths._(this.root);

  static AppPaths? _instance;

  /// Initialized portable root. Call [init] from `main` before stores/services.
  static AppPaths get instance {
    final current = _instance;
    if (current == null) {
      throw StateError('AppPaths.init() must be called before use.');
    }
    return current;
  }

  static bool get isInitialized => _instance != null;

  /// Portable userdata root directory.
  final Directory root;

  static const historyFileName = 'tagline_history.json';
  static const settingsFileName = 'settings.json';
  static const apiKeyFileName = 'api_key.txt';

  /// Override for tests; resets with [debugReset].
  static Future<AppPaths> init({Directory? overrideRoot}) async {
    if (overrideRoot != null) {
      await overrideRoot.create(recursive: true);
      _instance = AppPaths._(overrideRoot);
      await _instance!._ensureLayout();
      return _instance!;
    }

    if (_instance != null) {
      return _instance!;
    }

    final root = await resolveDefaultRoot();
    await root.create(recursive: true);
    _instance = AppPaths._(root);
    await _instance!._ensureLayout();
    return _instance!;
  }

  /// Test-only reset so the next [init] recomputes the root.
  static void debugReset() {
    _instance = null;
  }

  /// Platform default portable root (no side effects beyond path math).
  static Future<Directory> resolveDefaultRoot() async {
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return Directory(p.join(exeDir, 'userdata'));
    }

    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        return Directory(p.join(external.path, 'userdata'));
      }
    }

    final documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, 'userdata'));
  }

  Directory get tempDirectory => Directory(p.join(root.path, 'temp'));

  File get historyFile => File(p.join(root.path, historyFileName));

  File get settingsFile => File(p.join(root.path, settingsFileName));

  File get apiKeyFile => File(p.join(root.path, apiKeyFileName));

  Future<Directory> ensureTemp() => _ensure(tempDirectory);

  Future<void> _ensureLayout() async {
    await ensureTemp();
  }

  Future<Directory> _ensure(Directory directory) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// Default for services that used `getApplicationDocumentsDirectory`.
  static Future<Directory> portableDocumentsDirectory() async {
    if (isInitialized) {
      return instance.root;
    }
    return getApplicationDocumentsDirectory();
  }

  /// Temp work area under the portable root (share staging, etc.).
  static Future<Directory> portableTemporaryDirectory() async {
    if (isInitialized) {
      return instance.ensureTemp();
    }
    return getTemporaryDirectory();
  }
}
