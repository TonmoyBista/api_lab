import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../domain/models/api_request.dart';
import '../../../../domain/models/http_traffic.dart';
import '../../../../domain/repositories/repositories.dart';
import '../../../../domain/use_cases/replay_request_use_case.dart';

class ComposerViewModel extends ChangeNotifier {
  final ReplayRequestUseCase _replayRequestUseCase;
  final ICollectionRepository _collectionRepository;

  StreamSubscription<List<ApiCollection>>? _colSubscription;
  List<ApiCollection> _collections = [];

  ApiRequestModel _currentRequest = ApiRequestModel(
    id: const Uuid().v4(),
    name: 'New Request',
    method: 'GET',
    url: 'https://jsonplaceholder.typicode.com/todos/1',
    headers: [
      const KeyValuePair(key: 'Accept', value: 'application/json'),
    ],
    queryParams: [],
    bodyType: 'none',
    bodyContent: '{\n  "title": "New Task",\n  "completed": false\n}',
    updatedAt: DateTime.now(),
  );

  ApiResponseModel? _response;
  bool _isLoading = false;
  String _activeTab = 'params'; // 'params', 'headers', 'body', 'auth'
  String? _selectedCollectionId;

  ComposerViewModel({
    required this._replayRequestUseCase,
    required this._collectionRepository,
  }) {
    _init();
  }

  void _init() {
    _collections = _collectionRepository.currentCollections;
    _colSubscription = _collectionRepository.collectionsStream.listen((cols) {
      _collections = cols;
      notifyListeners();
    });
  }

  ApiRequestModel get currentRequest => _currentRequest;
  ApiResponseModel? get response => _response;
  bool get isLoading => _isLoading;
  String get activeTab => _activeTab;
  List<ApiCollection> get collections => _collections;
  String? get selectedCollectionId => _selectedCollectionId;

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void updateMethod(String method) {
    _currentRequest = _currentRequest.copyWith(method: method);
    notifyListeners();
  }

  void updateUrl(String url) {
    final updatedParams = ApiRequestModel.syncQueryParamsFromUrl(url, _currentRequest.queryParams);
    _currentRequest = _currentRequest.copyWith(
      url: url,
      queryParams: updatedParams,
    );
    notifyListeners();
  }

  void updateRequestName(String name) {
    _currentRequest = _currentRequest.copyWith(name: name);
    notifyListeners();
  }

  void updateBodyType(String type) {
    _currentRequest = _currentRequest.copyWith(bodyType: type);
    notifyListeners();
  }

  void updateBodyContent(String content) {
    _currentRequest = _currentRequest.copyWith(bodyContent: content);
    notifyListeners();
  }

  void updateAuthType(String type) {
    _currentRequest = _currentRequest.copyWith(authType: type);
    notifyListeners();
  }

  void updateBearerToken(String token) {
    _currentRequest = _currentRequest.copyWith(authBearerToken: token);
    notifyListeners();
  }

  void updateBasicAuth(String user, String pass) {
    _currentRequest = _currentRequest.copyWith(
      authUsername: user,
      authPassword: pass,
    );
    notifyListeners();
  }

  // Headers management
  void addHeader() {
    final list = List<KeyValuePair>.from(_currentRequest.headers)
      ..add(const KeyValuePair(key: '', value: ''));
    _currentRequest = _currentRequest.copyWith(headers: list);
    notifyListeners();
  }

  void updateHeader(int index, String key, String value, bool isEnabled) {
    if (index >= 0 && index < _currentRequest.headers.length) {
      final list = List<KeyValuePair>.from(_currentRequest.headers);
      list[index] = KeyValuePair(key: key, value: value, isEnabled: isEnabled);
      _currentRequest = _currentRequest.copyWith(headers: list);
      notifyListeners();
    }
  }

  void removeHeader(int index) {
    if (index >= 0 && index < _currentRequest.headers.length) {
      final list = List<KeyValuePair>.from(_currentRequest.headers)..removeAt(index);
      _currentRequest = _currentRequest.copyWith(headers: list);
      notifyListeners();
    }
  }

  // Query Params management
  void addQueryParam() {
    final list = List<KeyValuePair>.from(_currentRequest.queryParams)
      ..add(const KeyValuePair(key: '', value: ''));
    final newUrl = ApiRequestModel.buildUrlWithParams(_currentRequest.url, list);
    _currentRequest = _currentRequest.copyWith(
      url: newUrl,
      queryParams: list,
    );
    notifyListeners();
  }

  void updateQueryParam(int index, String key, String value, bool isEnabled) {
    if (index >= 0 && index < _currentRequest.queryParams.length) {
      final list = List<KeyValuePair>.from(_currentRequest.queryParams);
      list[index] = KeyValuePair(key: key, value: value, isEnabled: isEnabled);
      final newUrl = ApiRequestModel.buildUrlWithParams(_currentRequest.url, list);
      _currentRequest = _currentRequest.copyWith(
        url: newUrl,
        queryParams: list,
      );
      notifyListeners();
    }
  }

  void removeQueryParam(int index) {
    if (index >= 0 && index < _currentRequest.queryParams.length) {
      final list = List<KeyValuePair>.from(_currentRequest.queryParams)..removeAt(index);
      final newUrl = ApiRequestModel.buildUrlWithParams(_currentRequest.url, list);
      _currentRequest = _currentRequest.copyWith(
        url: newUrl,
        queryParams: list,
      );
      notifyListeners();
    }
  }

  // Format JSON
  void formatRequestBodyJson() {
    if (_currentRequest.bodyContent.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(_currentRequest.bodyContent);
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(decoded);
      _currentRequest = _currentRequest.copyWith(bodyContent: formatted);
      notifyListeners();
    } catch (_) {}
  }

  // Send request
  Future<void> sendRequest() async {
    if (_currentRequest.url.trim().isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _replayRequestUseCase.execute(_currentRequest);
      _response = result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load from intercepted traffic
  void loadFromTraffic(HttpRequestData traffic) {
    final headersList = traffic.headers.entries
        .map((e) => KeyValuePair(key: e.key, value: e.value))
        .toList();

    final queryList = traffic.queryParams.entries
        .map((e) => KeyValuePair(key: e.key, value: e.value))
        .toList();

    _currentRequest = ApiRequestModel(
      id: const Uuid().v4(),
      name: '${traffic.method} ${traffic.path}',
      method: traffic.method,
      url: traffic.url,
      headers: headersList.isNotEmpty ? headersList : [const KeyValuePair(key: 'Accept', value: '*/*')],
      queryParams: queryList,
      bodyType: traffic.body.isNotEmpty ? 'json' : 'none',
      bodyContent: traffic.body,
      updatedAt: DateTime.now(),
    );
    _response = null;
    notifyListeners();
  }

  // Load saved request
  void loadSavedRequest(ApiRequestModel request) {
    _currentRequest = request;
    _response = null;
    notifyListeners();
  }

  // Save to collection
  Future<void> saveToCollection(String collectionId) async {
    _selectedCollectionId = collectionId;
    await _collectionRepository.saveRequest(collectionId, _currentRequest);
    notifyListeners();
  }

  Future<void> createCollection(String name) async {
    await _collectionRepository.createCollection(name);
  }

  @override
  void dispose() {
    _colSubscription?.cancel();
    super.dispose();
  }
}
