import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claim_whats_yours/core/config/app_config.dart';
import 'package:claim_whats_yours/core/errors/api_exception.dart';
import 'package:claim_whats_yours/core/errors/app_exception.dart';
import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/scholarships/data/api_scholarship_repository.dart';
import 'package:claim_whats_yours/features/scholarships/data/scholarship_json_parser.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';

import '../../core/api_client_test.dart';

const String _scholarshipId = '3fa85f64-5717-4562-b3fc-2c963f66afa6';

Map<String, dynamic> _scholarshipJson() {
  return <String, dynamic>{
    'id': _scholarshipId,
    'name': 'National Merit Scholarship',
    'slug': 'national-merit-scholarship',
    'description': null,
    'administering_authority': 'Ministry of Education',
    'category': 'merit',
    'benefits': <Object?>[],
    'application_url': null,
    'is_active': true,
    'created_at': '2025-06-01T10:00:00Z',
    'updated_at': '2025-07-15T08:30:00Z',
    'eligibility_criteria': <Object?>[],
    'academic_years': <Object?>[],
    'sources': <Object?>[],
  };
}

Map<String, dynamic> _pageEnvelope() {
  return <String, dynamic>{
    'data': [_scholarshipJson()],
    'meta': <String, dynamic>{
      'page': 2,
      'page_size': 10,
      'total': 11,
      'total_pages': 2,
    },
  };
}

ResponseBody _jsonBody(Object? data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// Records every request and answers with [handler]'s result.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Returns the error thrown by [future], failing the test if it completes.
Future<Object> _errorOf(Future<Object?> future) async {
  try {
    await future;
  } catch (error) {
    return error;
  }
  fail('Expected the future to throw, but it completed successfully.');
}

void main() {
  const config = AppConfig(
    appName: 'Test App',
    apiBaseUrl: 'http://test.invalid/api/v1',
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 5),
    isProduction: false,
  );

  ApiScholarshipRepository buildRepo(_RecordingAdapter adapter) {
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    final apiClient = ApiClient(
      config: config,
      tokenProvider: MockTokenProvider('token'),
      customDio: dio,
    );
    return ApiScholarshipRepository(apiClient);
  }

  group('ApiScholarshipRepository.fetchPage', () {
    test(
      'sends page, page_size, trimmed search, category, sort_by and sort_order',
      () async {
        final adapter = _RecordingAdapter(
          (_) async => _jsonBody(_pageEnvelope()),
        );
        final repo = buildRepo(adapter);

        await repo.fetchPage(
          const ScholarshipQuery(
            page: 2,
            pageSize: 10,
            search: '  merit  ',
            category: ScholarshipCategory.sc,
            sortBy: ScholarshipSortField.name,
            sortOrder: ScholarshipSortOrder.asc,
          ),
        );

        expect(adapter.requests, hasLength(1));
        final request = adapter.requests.single;
        expect(request.uri.path, endsWith('/scholarships'));
        expect(request.queryParameters, {
          'page': 2,
          'page_size': 10,
          'search': 'merit',
          'category': 'sc',
          'sort_by': 'name',
          'sort_order': 'asc',
        });
      },
    );

    test('does not send search when it is blank after trimming', () async {
      final adapter = _RecordingAdapter(
        (_) async => _jsonBody(_pageEnvelope()),
      );
      final repo = buildRepo(adapter);

      await repo.fetchPage(const ScholarshipQuery(search: '   '));

      final params = adapter.requests.single.queryParameters;
      expect(params.containsKey('search'), isFalse);
      expect(params, {'page': 1, 'page_size': 20});
    });

    test('parses the list envelope into items and page metadata', () async {
      final adapter = _RecordingAdapter(
        (_) async => _jsonBody(_pageEnvelope()),
      );
      final repo = buildRepo(adapter);

      final page = await repo.fetchPage(
        const ScholarshipQuery(page: 2, pageSize: 10),
      );

      expect(page.items, hasLength(1));
      expect(page.items.single.id, _scholarshipId);
      expect(page.items.single.name, 'National Merit Scholarship');
      expect(page.page, 2);
      expect(page.pageSize, 10);
      expect(page.total, 11);
      expect(page.totalPages, 2);
    });
  });

  group('ApiScholarshipRepository.fetchById', () {
    test('requests the id path and parses the scholarship', () async {
      final adapter = _RecordingAdapter(
        (_) async => _jsonBody(_scholarshipJson()),
      );
      final repo = buildRepo(adapter);

      final scholarship = await repo.fetchById(_scholarshipId);

      expect(
        adapter.requests.single.uri.path,
        endsWith('/scholarships/$_scholarshipId'),
      );
      expect(scholarship.id, _scholarshipId);
      expect(scholarship.name, 'National Merit Scholarship');
      expect(scholarship.categoryValue, ScholarshipCategory.merit);
    });

    test('404 maps to NotFoundException with a message that is not the response body', () async {
      const body =
          '{"error":{"message":"Scholarship not found","code":"scholarship_not_found"}}';
      final adapter = _RecordingAdapter(
        (_) async => ResponseBody.fromString(
          body,
          404,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      final repo = buildRepo(adapter);

      final error = await _errorOf(repo.fetchById('missing-id'));

      expect(error, isA<NotFoundException>());
      final appError = error as AppException;
      expect(appError.message, isNot(body));
      expect(appError.message, 'Scholarship not found');
    });

    test('503 maps to a ServerException and the message omits the raw response body', () async {
      const rawBody = 'upstream-db-trace-xyz';
      final adapter = _RecordingAdapter(
        (_) async => ResponseBody.fromString(
          rawBody,
          503,
          headers: {
            Headers.contentTypeHeader: ['text/plain'],
          },
        ),
      );
      final repo = buildRepo(adapter);

      final error = await _errorOf(repo.fetchById(_scholarshipId));

      expect(error, isA<ServerException>());
      final appError = error as AppException;
      expect(appError.message, isNot(contains(rawBody)));
      expect(appError.message, 'Request failed with status 503');
    });

    test('connection error maps to NetworkException', () async {
      final adapter = _RecordingAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      final repo = buildRepo(adapter);

      final error = await _errorOf(repo.fetchById(_scholarshipId));

      expect(error, isA<NetworkException>());
      expect(error, isA<AppException>());
    });

    test('a JSON list instead of an object maps to BadResponseException without raw JSON in the message', () async {
      final adapter = _RecordingAdapter(
        (_) async => _jsonBody(<Object?>[1, 2, 'secret-marker']),
      );
      final repo = buildRepo(adapter);

      final error = await _errorOf(repo.fetchById(_scholarshipId));

      expect(error, isA<BadResponseException>());
      expect(error, isA<AppException>());
      final message = (error as AppException).message;
      expect(message, isNot(contains('secret-marker')));
      expect(message, isNot(contains('[1,2')));
    });

    test('a malformed list body maps to BadResponseException, not a raw ScholarshipParseException', () async {
      final adapter = _RecordingAdapter(
        (_) async => _jsonBody(<String, dynamic>{'data': 'bad'}),
      );
      final repo = buildRepo(adapter);

      final error = await _errorOf(repo.fetchPage(const ScholarshipQuery()));

      expect(error, isA<BadResponseException>());
      expect(error, isNot(isA<ScholarshipParseException>()));
    });
  });
}
