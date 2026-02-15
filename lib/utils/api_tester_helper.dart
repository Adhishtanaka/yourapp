import 'dart:convert';
import 'package:dio/dio.dart';

class ApiTesterHelper {
  final Dio _dio;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  ApiTesterHelper() : _dio = Dio();

  Future<ApiTestResult> testApi({
    required String url,
    required String method,
    String? body,
    Map<String, String>? headers,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await _executeRequest(
          url: url,
          method: method,
          body: body,
          headers: headers,
        );
        return result;
      } catch (e) {
        if (attempt == maxRetries) {
          return ApiTestResult(
            success: false,
            error: 'Failed after $maxRetries attempts: ${e.toString()}',
            statusCode: null,
            responseData: null,
            responseTime: null,
            attempts: attempt,
          );
        }
        await Future.delayed(retryDelay);
      }
    }
    return ApiTestResult(
      success: false,
      error: 'Unknown error occurred',
      statusCode: null,
      responseData: null,
      responseTime: null,
      attempts: maxRetries,
    );
  }

  Future<ApiTestResult> _executeRequest({
    required String url,
    required String method,
    String? body,
    Map<String, String>? headers,
  }) async {
    final stopwatch = Stopwatch()..start();

    Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await _dio.get(
          url,
          options: Options(headers: headers),
        );
        break;
      case 'POST':
        response = await _dio.post(
          url,
          data: body,
          options: Options(headers: headers),
        );
        break;
      case 'PUT':
        response = await _dio.put(
          url,
          data: body,
          options: Options(headers: headers),
        );
        break;
      case 'DELETE':
        response = await _dio.delete(
          url,
          options: Options(headers: headers),
        );
        break;
      case 'PATCH':
        response = await _dio.patch(
          url,
          data: body,
          options: Options(headers: headers),
        );
        break;
      default:
        response = await _dio.get(
          url,
          options: Options(headers: headers),
        );
    }

    stopwatch.stop();

    dynamic responseData = response.data;
    if (responseData is Map || responseData is List) {
      responseData = responseData;
    } else {
      try {
        responseData = jsonDecode(response.data.toString());
      } catch (_) {
        responseData = response.data;
      }
    }

    final isSuccess = response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;

    return ApiTestResult(
      success: isSuccess,
      error: isSuccess ? null : 'HTTP ${response.statusCode}',
      statusCode: response.statusCode,
      responseData: responseData,
      responseTime: stopwatch.elapsed,
      attempts: 1,
    );
  }

  Future<ApiValidationResult> validateApiAgainstSpec({
    required String url,
    required String method,
    String? body,
    required String specContent,
  }) async {
    final testResult = await testApi(
      url: url,
      method: method,
      body: body,
    );

    if (!testResult.success) {
      return ApiValidationResult(
        valid: false,
        message: testResult.error ?? 'API request failed',
        apiStructure: null,
        apiType: null,
        inputSchema: null,
        outputSchema: null,
        urls: [url],
        canRetry: true,
      );
    }

    final parsedStructure = _parseApiStructure(
      url: url,
      method: method,
      responseData: testResult.responseData,
      body: body,
    );

    return ApiValidationResult(
      valid: true,
      message: 'API validated successfully',
      apiStructure: parsedStructure['structure'],
      apiType: parsedStructure['type'],
      inputSchema: parsedStructure['input'],
      outputSchema: parsedStructure['output'],
      urls: [url],
      canRetry: false,
    );
  }

  Map<String, dynamic> _parseApiStructure({
    required String url,
    required String method,
    dynamic responseData,
    String? body,
  }) {
    String structure = 'REST';
    String type = 'unknown';
    Map<String, dynamic>? input;
    Map<String, dynamic>? output;

    if (responseData is Map) {
      if (responseData.containsKey('data') ||
          responseData.containsKey('results')) {
        type = 'paginated';
      } else if (responseData.containsKey('token') ||
          responseData.containsKey('access_token')) {
        type = 'authentication';
      } else {
        type = 'standard';
      }

      output = _extractSchema(Map<String, dynamic>.from(responseData));
    } else if (responseData is List) {
      type = 'list';
      output = {
        'type': 'array',
        'items': responseData.isNotEmpty && responseData[0] is Map
            ? _extractSchema(Map<String, dynamic>.from(responseData[0]))
            : {'type': 'string'}
      };
    }

    if (body != null && body.isNotEmpty) {
      try {
        input = jsonDecode(body) is Map ? jsonDecode(body) : {'raw': body};
      } catch (_) {
        input = {'raw': body};
      }
    } else {
      input = method == 'GET' || method == 'DELETE' ? null : {'empty': true};
    }

    final uri = Uri.parse(url);
    if (uri.path.contains('/auth') || uri.path.contains('/login')) {
      type = 'authentication';
      structure = 'REST';
    } else if (uri.queryParameters.containsKey('search') ||
        uri.queryParameters.containsKey('query')) {
      type = 'search';
    }

    return {
      'structure': structure,
      'type': type,
      'input': input,
      'output': output,
    };
  }

  Map<String, dynamic> _extractSchema(Map<String, dynamic> data) {
    final schema = <String, dynamic>{};

    for (final entry in data.entries) {
      final value = entry.value;
      final valueType = value.runtimeType.toString();

      if (value is Map) {
        schema[entry.key] = {
          'type': 'object',
          'properties': _extractSchema(Map<String, dynamic>.from(value)),
        };
      } else if (value is List) {
        schema[entry.key] = {
          'type': 'array',
          'items': value.isNotEmpty
              ? {'type': value[0].runtimeType.toString().toLowerCase()}
              : {},
        };
      } else {
        String type = 'string';
        if (valueType == 'int' || valueType == 'double' || valueType == 'num') {
          type = 'number';
        } else if (valueType == 'bool') {
          type = 'boolean';
        } else if (value == null) {
          type = 'null';
        }
        schema[entry.key] = {'type': type};
      }
    }

    return schema;
  }
}

class ApiTestResult {
  final bool success;
  final String? error;
  final int? statusCode;
  final dynamic responseData;
  final Duration? responseTime;
  final int attempts;

  ApiTestResult({
    required this.success,
    required this.error,
    required this.statusCode,
    required this.responseData,
    required this.responseTime,
    required this.attempts,
  });
}

class ApiValidationResult {
  final bool valid;
  final String message;
  final String? apiStructure;
  final String? apiType;
  final Map<String, dynamic>? inputSchema;
  final Map<String, dynamic>? outputSchema;
  final List<String> urls;
  final bool canRetry;

  ApiValidationResult({
    required this.valid,
    required this.message,
    required this.apiStructure,
    required this.apiType,
    required this.inputSchema,
    required this.outputSchema,
    required this.urls,
    required this.canRetry,
  });

  Map<String, dynamic> toMap() {
    return {
      'valid': valid,
      'message': message,
      'apiStructure': apiStructure,
      'apiType': apiType,
      'inputSchema': inputSchema,
      'outputSchema': outputSchema,
      'urls': urls,
      'canRetry': canRetry,
    };
  }

  String toSpecAddition() {
    if (!valid) {
      return '\n\n=== API VALIDATION FAILED ===\n$message\nCan retry: $canRetry';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n\n=== API SPEC ===');
    buffer.writeln('Type: $apiType');
    buffer.writeln('Structure: $apiStructure');
    buffer.writeln('URLs: ${urls.join(", ")}');

    if (inputSchema != null && inputSchema!.isNotEmpty) {
      buffer.writeln('\nInput:');
      buffer.writeln(_prettyPrintJson(inputSchema!));
    }

    if (outputSchema != null && outputSchema!.isNotEmpty) {
      buffer.writeln('\nOutput:');
      buffer.writeln(_prettyPrintJson(outputSchema!));
    }

    return buffer.toString();
  }

  String _prettyPrintJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
