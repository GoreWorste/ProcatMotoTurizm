import 'package:dio/dio.dart';

import '../models/client.dart';
import '../models/client_query.dart';
import '../models/page_result.dart';

abstract class ClientRepository {
  Future<PageResult<Client>> find(
    ClientQuery query, {
    CancelToken? cancelToken,
  });

  Future<Client?> findById(int id);

  Future<Client> create(Client item);

  Future<Client> update(Client item);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids);

  bool isPhoneTaken(String phone, {int? exceptId});

  bool isEmailTaken(String email, {int? exceptId});
}
