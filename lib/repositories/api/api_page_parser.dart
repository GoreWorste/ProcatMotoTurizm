import '../../models/page_result.dart';

PageResult<T> parsePage<T>(
  Map<String, dynamic> data,
  T Function(Map<String, dynamic>) fromJson,
) {
  final itemsRaw = data['items'];
  final items = itemsRaw is List
      ? itemsRaw
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList()
      : <T>[];
  return PageResult<T>(
    items: items,
    page: data['page'] as int? ?? 1,
    size: data['size'] as int? ?? items.length,
    total: data['total'] as int? ?? items.length,
  );
}

Map<String, dynamic> mergeQuery(
  Map<String, dynamic> base, {
  int? delayMs,
  int? failStatus,
}) {
  final q = Map<String, dynamic>.from(base);
  if (delayMs != null) q['__delay'] = delayMs;
  if (failStatus != null) q['__fail'] = failStatus;
  return q;
}
