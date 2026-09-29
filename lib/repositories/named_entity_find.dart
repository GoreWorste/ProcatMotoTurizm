import '../models/named_entity_query.dart';
import '../models/page_result.dart';

PageResult<T> findNamedPage<T>({
  required List<T> source,
  required NamedEntityQuery query,
  required String Function(T item) nameOf,
  required DateTime? Function(T item) deletedAtOf,
}) {
  var list = List<T>.from(source);

  if (!query.includeDeleted) {
    list = list.where((e) => deletedAtOf(e) == null).toList();
  }

  final search = query.search.trim().toLowerCase();
  if (search.isNotEmpty) {
    list = list.where((e) => nameOf(e).toLowerCase().contains(search)).toList();
  }

  list.sort((a, b) {
    final cmp = nameOf(a).compareTo(nameOf(b));
    return query.sortAscending ? cmp : -cmp;
  });

  final total = list.length;
  final page = query.page < 1 ? 1 : query.page;
  final size = query.size < 1 ? 10 : query.size;
  final start = (page - 1) * size;
  final end = start + size;
  final to = end > total ? total : end;
  final pageItems = start >= total ? <T>[] : list.sublist(start, to);

  return PageResult<T>(
    items: pageItems,
    page: page,
    size: size,
    total: total,
  );
}
