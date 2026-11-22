import 'package:claim_whats_yours/core/errors/api_exception.dart';
import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'package:claim_whats_yours/features/scholarships/data/scholarship_json_parser.dart';
import 'package:claim_whats_yours/features/scholarships/data/scholarship_repository.dart';

/// Builds the query-string map for `GET /scholarships`.
///
/// `page` and `page_size` are always sent. Optional values are sent only when
/// non-null and non-empty after trimming. A blank search is never sent.
Map<String, dynamic> buildScholarshipQueryParameters(ScholarshipQuery query) {
  final params = <String, dynamic>{
    'page': query.page,
    'page_size': query.pageSize,
  };

  final search = query.search?.trim();
  if (search != null && search.isNotEmpty) {
    params['search'] = search;
  }

  final category = query.category;
  if (category != null) {
    params['category'] = category.wireValue;
  }

  final sortBy = query.sortBy;
  if (sortBy != null) {
    params['sort_by'] = sortBy.wireValue;
  }

  final sortOrder = query.sortOrder;
  if (sortOrder != null) {
    params['sort_order'] = sortOrder.wireValue;
  }

  final academicYear = query.academicYear?.trim();
  if (academicYear != null && academicYear.isNotEmpty) {
    params['academic_year'] = academicYear;
  }

  final educationLevel = query.educationLevel?.trim();
  if (educationLevel != null && educationLevel.isNotEmpty) {
    params['education_level'] = educationLevel;
  }

  return params;
}

/// [ScholarshipRepository] backed by the shared [ApiClient].
///
/// HTTP errors surface as the [ApiException] subclasses that [ApiClient]
/// already produces. A response whose shape violates the contract is reported
/// as a [BadResponseException] with a safe message. The response body is never
/// included in any message.
class ApiScholarshipRepository implements ScholarshipRepository {
  ApiScholarshipRepository(this._client);

  final ApiClient _client;

  static const String _listPath = '/scholarships';
  static const String _malformedCode = 'malformed_scholarship_response';
  static const String _malformedMessage =
      'We could not read the scholarship data. Please try again.';

  @override
  Future<ScholarshipPage> fetchPage(ScholarshipQuery query) async {
    final response = await _client.get<dynamic>(
      _listPath,
      queryParameters: buildScholarshipQueryParameters(query),
    );
    try {
      return parseScholarshipPage(response.data);
    } on ScholarshipParseException catch (error) {
      throw _malformed(error);
    }
  }

  @override
  Future<Scholarship> fetchById(String id) async {
    final response = await _client.get<dynamic>(
      '$_listPath/${Uri.encodeComponent(id.trim())}',
    );
    try {
      return parseScholarship(response.data);
    } on ScholarshipParseException catch (error) {
      throw _malformed(error);
    }
  }

  BadResponseException _malformed(ScholarshipParseException cause) {
    return BadResponseException(
      _malformedMessage,
      errorCode: _malformedCode,
      cause: cause,
    );
  }
}
