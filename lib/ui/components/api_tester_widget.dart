import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:yourapp/ui/theme/app_theme.dart';
import 'package:yourapp/utils/ai_operations.dart';

class ApiTesterWidget extends StatefulWidget {
  final String? specContent;
  final Function(String endpoint, String method, String? body)? onValidateApi;

  const ApiTesterWidget({
    super.key,
    this.specContent,
    this.onValidateApi,
  });

  @override
  State<ApiTesterWidget> createState() => _ApiTesterWidgetState();
}

class _ApiTesterWidgetState extends State<ApiTesterWidget> {
  final Dio _dio = Dio();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final ScrollController _responseScrollController = ScrollController();

  String _selectedMethod = 'GET';
  bool _isLoading = false;
  String? _responseData;
  String? _errorMessage;
  int? _statusCode;
  Duration? _responseTime;
  final List<String> _methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];

  @override
  void initState() {
    super.initState();
    _urlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    _responseScrollController.dispose();
    super.dispose();
  }

  Future<void> _testApi() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _responseData = null;
      _statusCode = null;
      _responseTime = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      Response response;

      switch (_selectedMethod) {
        case 'GET':
          response = await _dio.get(url);
          break;
        case 'POST':
          String? body = _bodyController.text.trim().isNotEmpty
              ? _bodyController.text.trim()
              : null;
          response = await _dio.post(url, data: body);
          break;
        case 'PUT':
          String? body = _bodyController.text.trim().isNotEmpty
              ? _bodyController.text.trim()
              : null;
          response = await _dio.put(url, data: body);
          break;
        case 'DELETE':
          response = await _dio.delete(url);
          break;
        case 'PATCH':
          String? body = _bodyController.text.trim().isNotEmpty
              ? _bodyController.text.trim()
              : null;
          response = await _dio.patch(url, data: body);
          break;
        default:
          response = await _dio.get(url);
      }

      stopwatch.stop();

      setState(() {
        _statusCode = response.statusCode;
        _responseTime = stopwatch.elapsed;

        if (response.data != null) {
          if (response.data is Map || response.data is List) {
            _responseData = _formatJson(response.data);
          } else {
            _responseData = response.data.toString();
          }
        } else {
          _responseData = 'No response body';
        }

        _isLoading = false;
      });
    } on DioException catch (e) {
      stopwatch.stop();
      setState(() {
        _statusCode = e.response?.statusCode;
        _responseTime = stopwatch.elapsed;
        _errorMessage = _getDioErrorMessage(e);
        if (e.response?.data != null) {
          _responseData = _formatJson(e.response?.data);
        }
        _isLoading = false;
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _responseTime = stopwatch.elapsed;
        _isLoading = false;
      });
    }
  }

  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badCertificate:
        return 'Bad certificate';
      case DioExceptionType.badResponse:
        return 'Bad response: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error - check your network';
      case DioExceptionType.unknown:
        return e.message ?? 'Unknown error';
    }
  }

  String _formatJson(dynamic data) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      return data.toString();
    }
  }

  Future<void> _validateWithAi() async {
    if (_responseData == null || widget.specContent == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ai = AIOperations();
      final validationPrompt = '''
Analyze this API response against the app specification:

=== API RESPONSE ===
${_responseData?.substring(0, 2000)}

=== APP SPECIFICATION ===
${widget.specContent}

Does this API response match the expected data structure from the spec? 
Respond with:
- VALID: if the response has the expected fields/data
- INVALID: if the response is missing expected fields or has wrong structure
- Brief explanation of what fields are present/missing
''';

      final result = await ai.getCode(validationPrompt);

      if (!mounted) return;

      if (result != null && result.toLowerCase().contains('valid')) {
        setState(() {
          _errorMessage = '✅ API Response Valid: $result';
        });
      } else {
        setState(() {
          _errorMessage = '⚠️ API Validation: $result';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Validation error: ${e.toString()}';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _clearResponse() {
    setState(() {
      _responseData = null;
      _errorMessage = null;
      _statusCode = null;
      _responseTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppColors.border),
          _buildRequestSection(),
          if (_responseData != null || _errorMessage != null) ...[
            const Divider(height: 1, color: AppColors.border),
            _buildResponseSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.api_rounded,
            size: 14,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: 6),
          Text(
            'API Tester',
            style: AppTextStyles.monoSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_statusCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusCode! >= 200 && _statusCode! < 300
                    ? AppColors.successLight
                    : AppColors.errorLight,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '$_statusCode',
                style: AppTextStyles.monoSmall.copyWith(
                  color: _statusCode! >= 200 && _statusCode! < 300
                      ? AppColors.success
                      : AppColors.error,
                  fontSize: 10,
                ),
              ),
            ),
          if (_responseTime != null) ...[
            const SizedBox(width: 8),
            Text(
              '${_responseTime!.inMilliseconds}ms',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value!;
                      });
                    },
                    style: AppTextStyles.monoSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    dropdownColor: AppColors.surfaceVariant,
                    items: _methods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            method,
                            style: AppTextStyles.monoSmall.copyWith(
                              color: method == 'GET'
                                  ? AppColors.success
                                  : method == 'POST'
                                      ? AppColors.accentBlue
                                      : method == 'DELETE'
                                          ? AppColors.error
                                          : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _urlController,
                    style: AppTextStyles.monoSmall,
                    decoration: InputDecoration(
                      hintText: 'https://api.example.com/endpoint',
                      hintStyle: AppTextStyles.monoSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isLoading ? null : _testApi,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isLoading ? AppColors.elevated : AppColors.accentBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.textMuted,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
          if (_selectedMethod != 'GET' && _selectedMethod != 'DELETE') ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _bodyController,
                style: AppTextStyles.monoSmall,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Request body (JSON)',
                  hintStyle: AppTextStyles.monoSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(10),
                  isDense: true,
                ),
              ),
            ),
          ],
          if (_errorMessage != null && _responseData == null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.monoSmall.copyWith(
                        color: AppColors.error,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponseSection() {
    final isValidResponse =
        _statusCode != null && _statusCode! >= 200 && _statusCode! < 300;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValidResponse
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                size: 14,
                color: isValidResponse ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                'Response',
                style: AppTextStyles.monoSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_responseData != null && widget.specContent != null)
                GestureDetector(
                  onTap: _isLoading ? null : _validateWithAi,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'Validate with AI',
                      style: AppTextStyles.monoSmall.copyWith(
                        color: AppColors.accentBlue,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _clearResponse,
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_errorMessage != null && _responseData != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _errorMessage!.contains('✅')
                    ? AppColors.successLight
                    : AppColors.errorLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _errorMessage!.contains('✅')
                        ? Icons.check_circle
                        : Icons.warning_amber,
                    size: 14,
                    color: _errorMessage!.contains('✅')
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.monoSmall.copyWith(
                        color: _errorMessage!.contains('✅')
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              controller: _responseScrollController,
              padding: const EdgeInsets.all(10),
              child: SelectableText(
                _responseData ?? '',
                style: AppTextStyles.monoSmall.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
