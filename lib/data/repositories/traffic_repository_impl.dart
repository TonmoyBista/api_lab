import 'dart:async';
import '../../domain/models/http_traffic.dart';
import '../../domain/repositories/repositories.dart';

class TrafficRepositoryImpl implements ITrafficRepository {
  final List<TrafficItem> _traffic = [];
  final StreamController<List<TrafficItem>> _controller = StreamController<List<TrafficItem>>.broadcast();
  static const int maxCapacity = 1500;

  @override
  Stream<List<TrafficItem>> get trafficStream => _controller.stream;

  @override
  List<TrafficItem> get currentTraffic => List.unmodifiable(_traffic);

  @override
  void addTraffic(TrafficItem item) {
    // Insert at beginning so newest items are first
    _traffic.insert(0, item);
    if (_traffic.length > maxCapacity) {
      _traffic.removeLast();
    }
    _emit();
  }

  @override
  void updateTraffic(TrafficItem item) {
    final idx = _traffic.indexWhere((t) => t.id == item.id);
    if (idx != -1) {
      _traffic[idx] = item;
      _emit();
    }
  }

  @override
  void clearTraffic() {
    _traffic.clear();
    _emit();
  }

  @override
  TrafficItem? getById(String id) {
    try {
      return _traffic.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void togglePin(String id) {
    final idx = _traffic.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final current = _traffic[idx];
      _traffic[idx] = current.copyWith(isPinned: !current.isPinned);
      _emit();
    }
  }

  @override
  void deleteTraffic(String id) {
    _traffic.removeWhere((t) => t.id == id);
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_traffic));
  }

  void dispose() {
    _controller.close();
  }
}
