import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/client.dart';
import '../models/client_query.dart';
import '../models/load_status.dart';
import '../models/page_result.dart';
import '../repositories/client_repository.dart';

class ClientListNotifier extends ChangeNotifier {
  ClientListNotifier(this._repository);

  final ClientRepository _repository;

  ClientQuery query = const ClientQuery();
  PageResult<Client> result = PageResult<Client>.empty();
  LoadStatus status = LoadStatus.idle;
  Object? error;
  final Set<int> selected = {};

  Client? detailItem;
  LoadStatus detailStatus = LoadStatus.idle;
  String? detailError;

  bool get showDeleted => query.includeDeleted;

  int _loadGeneration = 0;

  Future<void> load({bool force = false}) async {
    if (status == LoadStatus.loading && !force) return;

    final generation = ++_loadGeneration;
    status = LoadStatus.loading;
    error = null;
    notifyListeners();

    try {
      final page = await _repository.find(query).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw const NetworkException(
          'Сервер не отвечает. Запустите .\\scripts\\run_api_server.ps1 (порт 8080).',
        ),
      );
      if (generation != _loadGeneration) return;
      result = page;
      status = LoadStatus.success;
    } catch (e, st) {
      if (generation != _loadGeneration) return;
      status = LoadStatus.error;
      error = mapLoadError(e);
      result = PageResult<Client>.empty();
      if (kDebugMode) {
        debugPrint('[ClientList] load failed: $error ($st)');
      }
    }
    notifyListeners();
  }

  Future<void> applyQuery(ClientQuery next) async {
    query = next;
    selected.clear();
    await load(force: true);
  }

  void toggleSelection(int id) {
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    notifyListeners();
  }

  Future<void> toggleShowDeleted(bool value) async {
    await applyQuery(query.copyWith(includeDeleted: value));
  }

  Future<void> deleteSelected({required bool hard}) async {
    if (selected.isEmpty) return;
    final ids = selected.toList();
    if (hard) {
      await _repository.deleteMany(ids);
    } else {
      for (final id in ids) {
        await _repository.softDelete(id);
      }
    }
    selected.clear();
    await load(force: true);
  }

  Future<void> hardDeleteSelected() => deleteSelected(hard: true);

  Future<void> softDeleteSelected() => deleteSelected(hard: false);

  Future<void> restoreSelected() async {
    for (final id in selected) {
      await _repository.restore(id);
    }
    selected.clear();
    await load(force: true);
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load(force: true);
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    await load(force: true);
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    await load(force: true);
  }

  Future<void> loadDetail(int id) async {
    detailStatus = LoadStatus.loading;
    detailError = null;
    detailItem = null;
    notifyListeners();

    try {
      detailItem = await _repository.findById(id);
      detailStatus = LoadStatus.success;
      if (detailItem == null) {
        detailError = 'Клиент не найден';
        detailStatus = LoadStatus.error;
      }
    } catch (e) {
      detailStatus = LoadStatus.error;
      detailError = describeError(mapLoadError(e));
    }
    notifyListeners();
  }
}
