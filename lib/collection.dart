import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'game.dart';

class CloudCollection extends ChangeNotifier {
  CloudCollection(this.file);
  final File file;
  final List<CloudPiece> _pieces = [];
  List<CloudPiece> get pieces => List.unmodifiable(_pieces);
  Future<void> _writes = Future.value();
  String? saveError;

  static Future<CloudCollection> open() async {
    final directory = await getApplicationSupportDirectory();
    final collection = CloudCollection(
      File('${directory.path}/my_sky_v1.json'),
    );
    await collection.load();
    return collection;
  }

  Future<void> load() async {
    if (!await file.exists()) return;
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (data['version'] != 1) {
      throw const FormatException('Unknown collection version');
    }
    final loaded = (data['clouds'] as List)
        .map((item) => CloudPiece.fromJson(item as Map<String, dynamic>))
        .toList();
    if (loaded.map((p) => p.id).toSet().length != loaded.length) {
      throw const FormatException('Duplicate cloud IDs');
    }
    _pieces
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  Future<CloudPiece> collect(MineGame game, int seconds) async {
    if (game.status != GameStatus.won) {
      throw StateError('Game has not been won');
    }
    final existing = _pieces.where((piece) => piece.id == game.id).firstOrNull;
    final piece = existing ?? CloudPiece.fromWin(game, seconds);
    if (existing == null) _pieces.add(piece);
    await save();
    return piece;
  }

  /// Serialize writes so a slow earlier drag cannot overwrite a newer position.
  /// Keep the previous valid collection beside the atomic replacement.
  Future<void> save() {
    final snapshot = jsonEncode({
      'version': 1,
      'clouds': _pieces.map((p) => p.toJson()).toList(),
    });
    final operation = _writes.then((_) async {
      try {
        await file.parent.create(recursive: true);
        final temp = File('${file.path}.tmp');
        await temp.writeAsString(snapshot, flush: true);
        if (await file.exists()) await file.copy('${file.path}.bak');
        await temp.rename(file.path);
        saveError = null;
      } catch (_) {
        saveError = '배치를 저장하지 못했어요. 다시 저장해주세요.';
        rethrow;
      } finally {
        notifyListeners();
      }
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }
}
