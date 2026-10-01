import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../domain/models/api_request.dart';
import '../../../../domain/models/http_traffic.dart';
import '../../../../domain/models/mock_rule.dart';
import '../../../../domain/repositories/repositories.dart';
import '../../../../domain/use_cases/replay_request_use_case.dart';
import '../../../../infrastructure/proxy/proxy_server.dart';

class InterceptorViewModel extends ChangeNotifier {
  final ITrafficRepository _trafficRepository;
  final ProxyServer _proxyServer;
  final IMockRuleRepository _mockRuleRepository;
  final ReplayRequestUseCase _replayRequestUseCase;

  StreamSubscription<List<TrafficItem>>? _subscription;
  List<TrafficItem> _allTraffic = [];

  TrafficItem? _selectedItem;
  ApiRequestModel? _editableRequest;
  ApiResponseModel? _testResponse;
  bool _isTesting = false;
  String _activeEditorTab = 'params'; // 'params', 'headers', 'body', 'auth', 'response', 'overview'

  String _searchQuery = '';
  String _methodFilter = 'ALL';
  String _statusFilter = 'ALL'; // ALL, 2XX, 4XX, 5XX, MOCKED
  bool _isAutoScroll = true;

  InterceptorViewModel({
    required this._trafficRepository,
    required this._proxyServer,
    required this._mockRuleRepository,
    required this._replayRequestUseCase,
  }) {
    _init();
  }

  void _init() {
    _allTraffic = _trafficRepository.currentTraffic;
    _subscription = _trafficRepository.trafficStream.listen((items) {
      _allTraffic = items;
      if (_selectedItem != null) {
        final updated = _allTraffic.where((t) => t.id == _selectedItem!.id).firstOrNull;
        if (updated != null) {
          _selectedItem = updated;
        }
      }
      notifyListeners();
    });

    if (_allTraffic.isNotEmpty) {
      selectItem(_allTraffic.first);
    }
  }

  bool get isProxyRunning => _proxyServer.isRunning;
  int get proxyPort => _proxyServer.config.port;
  String get proxyHost => _proxyServer.config.host;
  String get lanIp => _proxyServer.detectedLanIp;
  TrafficItem? get selectedItem => _selectedItem;
  ApiRequestModel? get editableRequest => _editableRequest;
  ApiResponseModel? get testResponse => _testResponse;
  bool get isTesting => _isTesting;
  String get activeEditorTab => _activeEditorTab;

  String get searchQuery => _searchQuery;
  String get methodFilter => _methodFilter;
  String get statusFilter => _statusFilter;
  bool get isAutoScroll => _isAutoScroll;

  List<TrafficItem> get filteredTraffic {
    return _allTraffic.where((item) {
      if (_methodFilter != 'ALL' && item.request.method.toUpperCase() != _methodFilter) {
        return false;
      }

      if (_statusFilter == 'MOCKED' && !item.isMocked) {
        return false;
      } else if (_statusFilter == '2XX') {
        final code = item.response?.statusCode ?? 0;
        if (code < 200 || code >= 300) return false;
      } else if (_statusFilter == '4XX') {
        final code = item.response?.statusCode ?? 0;
        if (code < 400 || code >= 500) return false;
      } else if (_statusFilter == '5XX') {
        final code = item.response?.statusCode ?? 0;
        if (code < 500 || code >= 600) return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesUrl = item.request.url.toLowerCase().contains(q);
        final matchesMethod = item.request.method.toLowerCase().contains(q);
        final matchesStatus = (item.response?.statusCode.toString() ?? '').contains(q);
        final matchesBody = item.request.body.toLowerCase().contains(q) ||
            (item.response?.body.toLowerCase().contains(q) ?? false);
        return matchesUrl || matchesMethod || matchesStatus || matchesBody;
      }

      return true;
    }).toList();
  }

  Future<void> toggleProxy() async {
    if (_proxyServer.isRunning) {
      await _proxyServer.stop();
    } else {
      await _proxyServer.start();
    }
    notifyListeners();
  }

  void selectItem(TrafficItem? item) {
    _selectedItem = item;
    if (item != null) {
      final headersList = item.request.headers.entries
          .map((e) => KeyValuePair(key: e.key, value: e.value))
          .toList();

      final queryList = item.request.resolvedQueryParams.entries
          .map((e) => KeyValuePair(key: e.key, value: e.value))
          .toList();

      _editableRequest = ApiRequestModel(
        id: item.id,
        name: '${item.request.method} ${item.request.pathWithQuery}',
        method: item.request.method,
        url: item.request.url,
        headers: headersList.isNotEmpty ? headersList : [const KeyValuePair(key: 'Accept', value: '*/*')],
        queryParams: queryList,
        bodyType: item.request.body.isNotEmpty ? 'json' : 'none',
        bodyContent: item.request.body,
        updatedAt: DateTime.now(),
      );

      if (item.response != null) {
        _testResponse = ApiResponseModel(
          statusCode: item.response!.statusCode,
          statusReason: item.response!.statusReason,
          headers: item.response!.headers,
          body: item.response!.body,
          durationMs: item.response!.durationMs,
          sizeBytes: item.response!.contentLength,
          timestamp: item.response!.timestamp,
        );
      } else {
        _testResponse = null;
      }
    }
    notifyListeners();
  }

  void createNewRequest() {
    _selectedItem = null;
    _editableRequest = ApiRequestModel(
      id: const Uuid().v4(),
      name: 'New Request',
      method: 'GET',
      url: 'https://httpbin.org/get',
      headers: [
        const KeyValuePair(key: 'Accept', value: 'application/json'),
        const KeyValuePair(key: 'User-Agent', value: 'ApiLab/1.0'),
      ],
      queryParams: [],
      bodyType: 'none',
      bodyContent: '{\n  "name": "example",\n  "active": true\n}',
      updatedAt: DateTime.now(),
    );
    _testResponse = null;
    _activeEditorTab = 'params';
    notifyListeners();
  }

  void setActiveEditorTab(String tab) {
    _activeEditorTab = tab;
    notifyListeners();
  }

  void updateMethod(String method) {
    if (_editableRequest != null) {
      _editableRequest = _editableRequest!.copyWith(method: method);
      notifyListeners();
    }
  }

  void updateUrl(String url) {
    if (_editableRequest != null) {
      _editableRequest = _editableRequest!.copyWith(url: url);
      notifyListeners();
    }
  }

  void updateBodyType(String type) {
    if (_editableRequest != null) {
      _editableRequest = _editableRequest!.copyWith(bodyType: type);
      notifyListeners();
    }
  }

  void updateBodyContent(String content) {
    if (_editableRequest != null) {
      _editableRequest = _editableRequest!.copyWith(bodyContent: content);
      notifyListeners();
    }
  }

  void updateAuthType(String type) {
    if (_editableRequest != null) {
      _editableRequest = _editableRequest!.copyWith(authType: type);
      notifyListeners();
    }
  }

  void updateBearerToken(String token) {
    if (_editableRequest != null) {
      _editableRequest = _editableRequest!.copyWith(authBearerToken: token);
      notifyListeners();
    }
  }

  void updateBasicAuth(String user, String pass) {
    if (_editableRequest != null) {
      _editableRequest = _editableRequest!.copyWith(
        authUsername: user,
        authPassword: pass,
      );
      notifyListeners();
    }
  }

  void addHeader() {
    if (_editableRequest != null) {
      final list = List<KeyValuePair>.from(_editableRequest!.headers)
        ..add(const KeyValuePair(key: '', value: ''));
      _editableRequest = _editableRequest!.copyWith(headers: list);
      notifyListeners();
    }
  }

  void updateHeader(int index, String key, String value, bool isEnabled) {
    if (_editableRequest != null && index >= 0 && index < _editableRequest!.headers.length) {
      final list = List<KeyValuePair>.from(_editableRequest!.headers);
      list[index] = KeyValuePair(key: key, value: value, isEnabled: isEnabled);
      _editableRequest = _editableRequest!.copyWith(headers: list);
      notifyListeners();
    }
  }

  void removeHeader(int index) {
    if (_editableRequest != null && index >= 0 && index < _editableRequest!.headers.length) {
      final list = List<KeyValuePair>.from(_editableRequest!.headers)..removeAt(index);
      _editableRequest = _editableRequest!.copyWith(headers: list);
      notifyListeners();
    }
  }

  void addQueryParam() {
    if (_editableRequest != null) {
      final list = List<KeyValuePair>.from(_editableRequest!.queryParams)
        ..add(const KeyValuePair(key: '', value: ''));
      _editableRequest = _editableRequest!.copyWith(queryParams: list);
      notifyListeners();
    }
  }

  void updateQueryParam(int index, String key, String value, bool isEnabled) {
    if (_editableRequest != null && index >= 0 && index < _editableRequest!.queryParams.length) {
      final list = List<KeyValuePair>.from(_editableRequest!.queryParams);
      list[index] = KeyValuePair(key: key, value: value, isEnabled: isEnabled);
      _editableRequest = _editableRequest!.copyWith(queryParams: list);
      notifyListeners();
    }
  }

  void removeQueryParam(int index) {
    if (_editableRequest != null && index >= 0 && index < _editableRequest!.queryParams.length) {
      final list = List<KeyValuePair>.from(_editableRequest!.queryParams)..removeAt(index);
      _editableRequest = _editableRequest!.copyWith(queryParams: list);
      notifyListeners();
    }
  }

  void formatRequestBodyJson() {
    if (_editableRequest == null || _editableRequest!.bodyContent.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(_editableRequest!.bodyContent);
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(decoded);
      _editableRequest = _editableRequest!.copyWith(bodyContent: formatted);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> sendCurrentRequest() async {
    if (_editableRequest == null || _editableRequest!.url.trim().isEmpty) return;

    _isTesting = true;
    notifyListeners();

    try {
      final result = await _replayRequestUseCase.execute(_editableRequest!);
      _testResponse = result;
      _activeEditorTab = 'response';
    } finally {
      _isTesting = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setMethodFilter(String method) {
    _methodFilter = method;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void toggleAutoScroll() {
    _isAutoScroll = !_isAutoScroll;
    notifyListeners();
  }

  void clearTraffic() {
    _trafficRepository.clearTraffic();
    _selectedItem = null;
    _editableRequest = null;
    _testResponse = null;
    notifyListeners();
  }

  void togglePin(String id) {
    _trafficRepository.togglePin(id);
  }

  void deleteItem(String id) {
    if (_selectedItem?.id == id) {
      _selectedItem = null;
      _editableRequest = null;
      _testResponse = null;
    }
    _trafficRepository.deleteTraffic(id);
  }

  MockRule createMockFromItem(TrafficItem item) {
    final req = item.request;
    final res = item.response;

    final sanitizedHeaders = <String, String>{};
    res?.headers.forEach((k, v) {
      final lk = k.toLowerCase().trim();
      if (lk != 'transfer-encoding' &&
          lk != 'content-encoding' &&
          lk != 'content-length' &&
          lk != 'connection' &&
          lk != 'server' &&
          lk != 'date') {
        sanitizedHeaders[k] = v;
      }
    });

    if (!sanitizedHeaders.keys.any((k) => k.toLowerCase() == 'content-type')) {
      sanitizedHeaders['content-type'] = 'application/json; charset=utf-8';
    }

    final conditions = <MockCondition>[];
    const uuid = Uuid();

    // 1. Auto-fill Query Parameters as Mock Conditions
    for (final entry in req.resolvedQueryParams.entries) {
      if (entry.key.trim().isNotEmpty) {
        conditions.add(
          MockCondition(
            id: uuid.v4(),
            source: ConditionSource.query,
            field: entry.key.trim(),
            operator: ConditionOperator.equals,
            value: entry.value.trim(),
            isEnabled: true,
          ),
        );
      }
    }

    // 2. Auto-fill Request Body as Mock Conditions
    if (req.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(req.body);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final valStr = entry.value?.toString() ?? '';
            if (entry.key.toString().trim().isNotEmpty) {
              conditions.add(
                MockCondition(
                  id: uuid.v4(),
                  source: ConditionSource.body,
                  field: entry.key.toString().trim(),
                  operator: ConditionOperator.equals,
                  value: valStr,
                  isEnabled: true,
                ),
              );
            }
          }
        } else {
          conditions.add(
            MockCondition(
              id: uuid.v4(),
              source: ConditionSource.body,
              field: 'body',
              operator: ConditionOperator.contains,
              value: req.body.trim(),
              isEnabled: true,
            ),
          );
        }
      } catch (_) {
        conditions.add(
          MockCondition(
            id: uuid.v4(),
            source: ConditionSource.body,
            field: 'body',
            operator: ConditionOperator.contains,
            value: req.body.trim(),
            isEnabled: true,
          ),
        );
      }
    }

    return MockRule(
      id: '',
      name: 'Mock: ${req.path}',
      matchMethod: req.method,
      urlPattern: '*${req.path}*',
      conditionLogic: 'AND',
      conditions: conditions,
      matchQueryParams: req.resolvedQueryParams,
      matchHeaders: req.headers.isNotEmpty ? Map<String, String>.from(req.headers) : const {},
      matchBody: req.body,
      responseStatusCode: res?.statusCode ?? 200,
      responseStatusReason: res?.statusReason ?? 'OK',
      responseHeaders: sanitizedHeaders,
      responseBody: res?.body.isNotEmpty == true ? res!.body : '{\n  "mocked": true\n}',
      responseDelayMs: res?.durationMs ?? 50,
      description: 'Created from intercepted request #${item.id.substring(0, 6)}',
    );
  }

  Future<void> saveMockRule(MockRule rule) async {
    await _mockRuleRepository.addRule(rule);
  }

  String generateCurl(TrafficItem item) {
    final req = item.request;
    final buffer = StringBuffer('curl -X ${req.method} "${req.url}"');
    req.headers.forEach((key, val) {
      buffer.write(' \\\n  -H "$key: $val"');
    });
    if (req.body.isNotEmpty) {
      final escaped = req.body.replaceAll('"', '\\"');
      buffer.write(' \\\n  -d "$escaped"');
    }
    return buffer.toString();
  }

  String generateCurlFromEditable() {
    if (_editableRequest == null) return '';
    final req = _editableRequest!;
    final buffer = StringBuffer('curl -X ${req.method} "${req.fullUri}"');
    req.resolvedHeaders.forEach((key, val) {
      buffer.write(' \\\n  -H "$key: $val"');
    });
    if (req.bodyType != 'none' && req.bodyContent.isNotEmpty) {
      final escaped = req.bodyContent.replaceAll('"', '\\"');
      buffer.write(' \\\n  -d "$escaped"');
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
