import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/models/api_request.dart';
import '../../domain/repositories/repositories.dart';

class CollectionRepositoryImpl implements ICollectionRepository {
  final List<ApiCollection> _collections = [];
  final StreamController<List<ApiCollection>> _controller = StreamController<List<ApiCollection>>.broadcast();

  CollectionRepositoryImpl() {
    _seedCollections();
  }

  void _seedCollections() {
    const uuid = Uuid();
    _collections.add(
      ApiCollection(
        id: uuid.v4(),
        name: 'Starter APIs',
        description: 'Common public APIs for testing and inspection',
        requests: [
          ApiRequestModel(
            id: uuid.v4(),
            name: 'Get Todo Item',
            method: 'GET',
            url: 'https://jsonplaceholder.typicode.com/todos/1',
            headers: [
              const KeyValuePair(key: 'Accept', value: 'application/json'),
            ],
            updatedAt: DateTime.now(),
          ),
          ApiRequestModel(
            id: uuid.v4(),
            name: 'Create Post',
            method: 'POST',
            url: 'https://jsonplaceholder.typicode.com/posts',
            headers: [
              const KeyValuePair(key: 'Content-Type', value: 'application/json; charset=UTF-8'),
            ],
            bodyType: 'json',
            bodyContent: '''{\n  "title": "ApiLab Flutter Desktop",\n  "body": "Testing HTTP requests via clean architecture",\n  "userId": 1\n}''',
            updatedAt: DateTime.now(),
          ),
          ApiRequestModel(
            id: uuid.v4(),
            name: 'Simulate 404 Error',
            method: 'GET',
            url: 'https://httpbin.org/status/404',
            updatedAt: DateTime.now(),
          ),
        ],
      ),
    );
  }

  @override
  Stream<List<ApiCollection>> get collectionsStream => _controller.stream;

  @override
  List<ApiCollection> get currentCollections => List.unmodifiable(_collections);

  @override
  Future<void> createCollection(String name, {String description = ''}) async {
    const uuid = Uuid();
    _collections.add(
      ApiCollection(
        id: uuid.v4(),
        name: name,
        description: description,
        requests: [],
      ),
    );
    _emit();
  }

  @override
  Future<void> deleteCollection(String id) async {
    _collections.removeWhere((c) => c.id == id);
    _emit();
  }

  @override
  Future<void> saveRequest(String collectionId, ApiRequestModel request) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx != -1) {
      final col = _collections[idx];
      final reqIdx = col.requests.indexWhere((r) => r.id == request.id);
      final updatedList = List<ApiRequestModel>.from(col.requests);
      if (reqIdx != -1) {
        updatedList[reqIdx] = request;
      } else {
        updatedList.add(request);
      }
      _collections[idx] = col.copyWith(requests: updatedList);
      _emit();
    }
  }

  @override
  Future<void> deleteRequest(String collectionId, String requestId) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx != -1) {
      final col = _collections[idx];
      final updatedList = col.requests.where((r) => r.id != requestId).toList();
      _collections[idx] = col.copyWith(requests: updatedList);
      _emit();
    }
  }

  void _emit() {
    _controller.add(List.unmodifiable(_collections));
  }

  void dispose() {
    _controller.close();
  }
}
