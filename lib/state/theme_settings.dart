import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Whether the app follows the system's light/dark setting or is pinned to
/// one. Kept in a JSON file in the app support directory, like the Tag pad
/// settings.
class ThemeSettings extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    _save();
  }

  static Future<File> _file() async =>
      File(p.join((await getApplicationSupportDirectory()).path, 'theme.json'));

  Future<void> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _mode = ThemeMode.values.asNameMap()[json['mode']] ?? ThemeMode.system;
      notifyListeners();
    } catch (_) {
      // A corrupt file just means following the system.
    }
  }

  Future<void> _save() async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'mode': _mode.name}));
    } catch (_) {}
  }
}
