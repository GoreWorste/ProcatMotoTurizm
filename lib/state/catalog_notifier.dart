import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/brand.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../repositories/brand_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/tag_repository.dart';

class CatalogNotifier extends ChangeNotifier {
  CatalogNotifier(
    this._categories,
    this._brands,
    this._tags,
  );

  final CategoryRepository _categories;
  final BrandRepository _brands;
  final TagRepository _tags;

  List<Category> categories = [];
  List<Brand> brands = [];
  List<Tag> tags = [];

  Future<void> refresh() async {
    categories = await _categories.findAll();
    brands = await _brands.findAll();
    tags = await _tags.findAll();
    notifyListeners();
  }

  String categoryName(int id) {
    for (final c in categories) {
      if (c.id == id) return c.name;
    }
    return '—';
  }

  String brandName(int id) {
    for (final b in brands) {
      if (b.id == id) return b.name;
    }
    return '—';
  }

  String tagNames(List<int> ids) {
    if (ids.isEmpty) return '—';
    final names = <String>[];
    for (final id in ids) {
      for (final t in tags) {
        if (t.id == id) {
          names.add(t.name);
          break;
        }
      }
    }
    return names.isEmpty ? '—' : names.join(', ');
  }
}
