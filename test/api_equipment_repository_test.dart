import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:procat_moto_turizm/core/api_exceptions.dart';
import 'package:procat_moto_turizm/models/equipment.dart';
import 'package:procat_moto_turizm/models/equipment_query.dart';
import 'package:procat_moto_turizm/repositories/api/api_equipment_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late ApiEquipmentRepository repo;

  setUp(() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8080/api',
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final status = response.statusCode ?? 0;
          if (status >= 400) {
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: mapHttpError(status, response.data),
              ),
              true,
            );
          }
          return handler.next(response);
        },
      ),
    );
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    repo = ApiEquipmentRepository(dio);
  });

  test('find разбирает постраничный ответ', () async {
    adapter.onGet(
      RegExp(r'/equipment$'),
      (server) => server.reply(200, {
        'items': [
          {
            'id': 1,
            'name': 'Test',
            'inventoryNumber': 'EQ-9999',
            'categoryId': 1,
            'brandId': 1,
            'purchaseYear': 2020,
            'dailyRate': 100,
            'condition': 'новое',
            'unitsTotal': 1,
            'unitsAvailable': 1,
            'tagIds': [1],
          },
        ],
        'page': 1,
        'size': 10,
        'total': 1,
      }),
    );

    final page = await repo.find(const EquipmentQuery());
    expect(page.items.length, 1);
    expect(page.total, 1);
  });

  test('create с 422 превращается в ValidationException', () async {
    adapter.onPost(
      '/equipment',
      (server) => server.reply(422, {
        'message': 'Ошибка валидации',
        'errors': {'inventoryNumber': 'Инвентарный номер уже используется'},
      }),
      data: Matchers.any,
    );

    expect(
      () => repo.create(
        const Equipment(
          id: 0,
          name: 'X',
          inventoryNumber: 'EQ-1001',
          categoryId: 1,
          brandId: 1,
          purchaseYear: 2020,
          dailyRate: 1,
          condition: 'новое',
          unitsTotal: 1,
          unitsAvailable: 1,
          tagIds: [1],
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('mapHttpError для 404', () {
    final ex = mapHttpError(404, {'message': 'нет'});
    expect(ex, isA<NotFoundException>());
  });

  test('mapDioError для connectionError', () {
    final ex = mapDioError(
      DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(ex, isA<NetworkException>());
  });

  test('mapDioError сохраняет ValidationException из error', () {
    const validation = ValidationException('err', {'a': 'b'});
    final ex = mapDioError(
      DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.unknown,
        error: validation,
      ),
    );
    expect(ex, validation);
  });
}
