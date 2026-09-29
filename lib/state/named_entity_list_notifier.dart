import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/load_status.dart';
import '../models/named_entity_query.dart';
import '../models/page_result.dart';

class NamedEntityListNotifier<T> extends ChangeNotifier {
  NamedEntityListNotifier({
    required Future<PageResult<T>> Function(NamedEntityQuery query) finder,
    required Future<T?> Function(int id) detailLoader,
    required Future<void> Function(int id) softDeleter,
    required Future<void> Function(int id) hardDeleter,
    required Future<void> Function(int id) restorer,
    required Future<int> Function(List<int> ids) bulkHardDeleter,
  })  : _finder = finder,
        _detailLoader = detailLoader,
        _softDeleter = softDeleter,
        _hardDeleter = hardDeleter,
        _restorer = restorer,
        _bulkHardDeleter = bulkHardDeleter;

  final Future<PageResult<T>> Function(NamedEntityQuery query) _finder;
  final Future<T?> Function(int id) _detailLoader;
  final Future<void> Function(int id) _softDeleter;
  final Future<void> Function(int id) _hardDeleter;
  final Future<void> Function(int id) _restorer;
  final Future<int> Function(List<int> ids) _bulkHardDeleter;

  NamedEntityQuery query = const NamedEntityQuery();
  PageResult<T> result = PageResult<T>.empty();
  LoadStatus status = LoadStatus.idle;
  String? error;
  final Set<int> selected = {};

  T? detailItem;
  LoadStatus detailStatus = LoadStatus.idle;
  String? detailError;

  bool get showDeleted => query.includeDeleted;

  Future<void> load() async {
    status = LoadStatus.loading;
    error = null;
    notifyListeners();

    try {
      result = await _finder(query);
      status = LoadStatus.success;
    } catch (e) {
      status = LoadStatus.error;
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> applyQuery(NamedEntityQuery next) async {
    query = next;
    selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    notifyListeners();
  }

  Future<void> softDeleteSelected() => deleteSelected(hard: false);

  Future<void> hardDeleteSelected() => deleteSelected(hard: true);

  Future<void> deleteSelected({required bool hard}) async {
    if (selected.isEmpty) return;
    final ids = selected.toList();
    if (hard) {
      await _bulkHardDeleter(ids);
    } else {
      for (final id in ids) {
        await _softDeleter(id);
      }
    }
    selected.clear();
    await load();
  }

  Future<void> restoreSelected() async {
    for (final id in selected) {
      await _restorer(id);
    }
    selected.clear();
    await load();
  }

  Future<void> restore(int id) async {
    await _restorer(id);
    await load();
  }

  Future<void> softDelete(int id) async {
    await _softDeleter(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _hardDeleter(id);
    await load();
  }

  Future<void> loadDetail(int id) async {
    detailStatus = LoadStatus.loading;
    detailError = null;
    detailItem = null;
    notifyListeners();

    try {
      detailItem = await _detailLoader(id);
      detailStatus = LoadStatus.success;
      if (detailItem == null) {
        detailError = 'Запись не найдена';
        detailStatus = LoadStatus.error;
      }
    } catch (e) {
      detailStatus = LoadStatus.error;
      detailError = e.toString();
    }
    notifyListeners();
  }
}
