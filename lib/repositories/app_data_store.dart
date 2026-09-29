import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/brand.dart';
import '../models/category.dart';
import '../models/client.dart';
import '../models/equipment.dart';
import '../models/seed_data.dart';
import '../models/tag.dart';

class AppDataStore {
  AppDataStore(this._prefs);

  static const _equipmentKey = 'equipment_v1';
  static const _clientsKey = 'clients_v1';
  static const _categoriesKey = 'categories_v1';
  static const _brandsKey = 'brands_v1';
  static const _tagsKey = 'tags_v1';
  static const _metaKey = 'meta_v1';

  final SharedPreferences _prefs;

  List<Equipment> equipment = [];
  List<Client> clients = [];
  List<Category> categories = [];
  List<Brand> brands = [];
  List<Tag> tags = [];

  int equipmentNextId = 100;
  int clientNextId = 100;
  int categoryNextId = 100;
  int brandNextId = 100;
  int tagNextId = 100;

  String? storageResetMessage;

  Future<void> restore() async {
    equipment = _loadEquipment();
    clients = _loadClients();
    categories = _loadCategories();
    brands = _loadBrands();
    tags = _loadTags();

    final metaRaw = _prefs.getString(_metaKey);
    if (metaRaw != null) {
      try {
        final meta = jsonDecode(metaRaw) as Map<String, dynamic>;
        equipmentNextId = meta['equipmentNextId'] as int? ?? equipmentNextId;
        clientNextId = meta['clientNextId'] as int? ?? clientNextId;
        categoryNextId = meta['categoryNextId'] as int? ?? categoryNextId;
        brandNextId = meta['brandNextId'] as int? ?? brandNextId;
        tagNextId = meta['tagNextId'] as int? ?? tagNextId;
      } catch (_) {
        // ignore broken meta
      }
    }
  }

  List<Equipment> _loadEquipment() {
    return _loadList(_equipmentKey, Equipment.fromJson, seedEquipment());
  }

  List<Client> _loadClients() {
    return _loadList(_clientsKey, Client.fromJson, seedClients());
  }

  List<Category> _loadCategories() {
    return _loadList(_categoriesKey, Category.fromJson, seedCategories());
  }

  List<Brand> _loadBrands() {
    return _loadList(_brandsKey, Brand.fromJson, seedBrands());
  }

  List<Tag> _loadTags() {
    return _loadList(_tagsKey, Tag.fromJson, seedTags());
  }

  List<T> _loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
    List<T> seed,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null) {
      final copy = List<T>.from(seed);
      _persistList(key, copy);
      return copy;
    }
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      storageResetMessage ??=
          'Данные в хранилище устарели или повреждены — загружен начальный набор.';
      final copy = List<T>.from(seed);
      _persistList(key, copy);
      return copy;
    }
  }

  void _persistList<T>(String key, List<T> items) {
    // Fire-and-forget on first seed; repositories persist with await later.
    switch (items) {
      case List<Equipment> equipmentItems:
        _prefs.setString(
          key,
          jsonEncode(equipmentItems.map((e) => e.toJson()).toList()),
        );
      case List<Client> clientItems:
        _prefs.setString(
          key,
          jsonEncode(clientItems.map((e) => e.toJson()).toList()),
        );
      case List<Category> categoryItems:
        _prefs.setString(
          key,
          jsonEncode(categoryItems.map((e) => e.toJson()).toList()),
        );
      case List<Brand> brandItems:
        _prefs.setString(
          key,
          jsonEncode(brandItems.map((e) => e.toJson()).toList()),
        );
      case List<Tag> tagItems:
        _prefs.setString(
          key,
          jsonEncode(tagItems.map((e) => e.toJson()).toList()),
        );
    }
  }

  Future<void> persistEquipment() async {
    await _prefs.setString(
      _equipmentKey,
      jsonEncode(equipment.map((e) => e.toJson()).toList()),
    );
    await _persistMeta();
  }

  Future<void> persistClients() async {
    await _prefs.setString(
      _clientsKey,
      jsonEncode(clients.map((e) => e.toJson()).toList()),
    );
    await _persistMeta();
  }

  Future<void> persistCategories() async {
    await _prefs.setString(
      _categoriesKey,
      jsonEncode(categories.map((e) => e.toJson()).toList()),
    );
    await _persistMeta();
  }

  Future<void> persistBrands() async {
    await _prefs.setString(
      _brandsKey,
      jsonEncode(brands.map((e) => e.toJson()).toList()),
    );
    await _persistMeta();
  }

  Future<void> persistTags() async {
    await _prefs.setString(
      _tagsKey,
      jsonEncode(tags.map((e) => e.toJson()).toList()),
    );
    await _persistMeta();
  }

  Future<void> _persistMeta() async {
    await _prefs.setString(
      _metaKey,
      jsonEncode({
        'equipmentNextId': equipmentNextId,
        'clientNextId': clientNextId,
        'categoryNextId': categoryNextId,
        'brandNextId': brandNextId,
        'tagNextId': tagNextId,
      }),
    );
  }
}
