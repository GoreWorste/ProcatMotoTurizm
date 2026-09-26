import 'package:flutter/foundation.dart';

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
  String? error;
  final Set<int> selected = {};

  Client? detailItem;
  LoadStatus detailStatus = LoadStatus.idle;
  String? detailError;

  bool get showDeleted => query.includeDeleted;

  Future<void> load() async {
    status = LoadStatus.loading;
    error = null;
    notifyListeners();

    try {
      result = await _repository.find(query);
      status = LoadStatus.success;
    } catch (e) {
      status = LoadStatus.error;
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> applyQuery(ClientQuery next) async {
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
    await load();
  }

  Future<void> hardDeleteSelected() => deleteSelected(hard: true);

  Future<void> softDeleteSelected() => deleteSelected(hard: false);

  Future<void> restoreSelected() async {
    for (final id in selected) {
      await _repository.restore(id);
    }
    selected.clear();
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    await load();
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
      detailError = e.toString();
    }
    notifyListeners();
  }
}
