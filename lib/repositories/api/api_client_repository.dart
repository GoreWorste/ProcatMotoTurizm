import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/client.dart';
import '../../models/client_query.dart';
import '../../models/page_result.dart';
import '../client_repository.dart';
import 'api_page_parser.dart';

class ApiClientRepository implements ClientRepository {
  ApiClientRepository(this._dio);

  final Dio _dio;

  Map<String, dynamic> _queryMap(ClientQuery q) => {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
        if (q.city != null && q.city!.isNotEmpty) 'city': q.city,
        'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      };

  Map<String, dynamic> _writeBody(Client item) => {
        'fullName': item.fullName,
        'email': item.email,
        'phone': item.phone,
        'city': item.city,
        'registeredAt': item.registeredAt.toIso8601String(),
        'rentalCard': item.rentalCard.toJson(),
      };

  @override
  Future<PageResult<Client>> find(
    ClientQuery query, {
    CancelToken? cancelToken,
  }) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/clients',
          queryParameters: _queryMap(query),
          cancelToken: cancelToken,
        );
        return parsePage(response.data ?? {}, Client.fromJson);
      });

  @override
  Future<Client?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get<Map<String, dynamic>>('/clients/$id');
        return Client.fromJson(response.data ?? {});
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Client> create(Client item) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/clients',
          data: _writeBody(item),
        );
        return Client.fromJson(response.data ?? {});
      });

  @override
  Future<Client> update(Client item) => guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/clients/${item.id}',
          data: _writeBody(item),
        );
        return Client.fromJson(response.data ?? {});
      });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete('/clients/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
        () => _dio.delete('/clients/$id', queryParameters: {'hard': true}),
      );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/clients/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/clients/bulk-delete',
          data: {'ids': ids},
        );
        return response.data?['deleted'] as int? ?? 0;
      });

  @override
  bool isPhoneTaken(String phone, {int? exceptId}) => false;

  @override
  bool isEmailTaken(String email, {int? exceptId}) => false;
}
