import 'dart:convert';
import 'dart:io';

import 'package:procat_moto_turizm/models/seed_data.dart';

void main() {
  final db = {
    'meta': {'equipmentNextId': 23, 'clientNextId': 10},
    'categories': seedCategories().map((e) => e.toJson()).toList(),
    'brands': seedBrands().map((e) => e.toJson()).toList(),
    'tags': seedTags().map((e) => e.toJson()).toList(),
    'equipment': seedEquipment().map((e) => e.toJson()).toList(),
    'clients': seedClients().map((e) => e.toJson()).toList(),
  };
  final out = File('api/db.json');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(db));
  stdout.writeln(out.path);
}
