import '../models/http_traffic.dart';
import '../models/mock_rule.dart';
import '../models/api_request.dart';
import '../models/mcp_and_ai.dart';

abstract class ITrafficRepository {
  Stream<List<TrafficItem>> get trafficStream;
  List<TrafficItem> get currentTraffic;
  void addTraffic(TrafficItem item);
  void updateTraffic(TrafficItem item);
  void clearTraffic();
  TrafficItem? getById(String id);
  void togglePin(String id);
  void deleteTraffic(String id);
}

abstract class IMockRuleRepository {
  Stream<List<MockRule>> get rulesStream;
  List<MockRule> get currentRules;
  List<String> get currentProjects;
  Future<void> createProject(String projectName);
  Future<void> addRule(MockRule rule);
  Future<void> updateRule(MockRule rule);
  Future<void> deleteRule(String id);
  Future<void> toggleRule(String id, bool isEnabled);
  MockRule? findMatchingRule(HttpRequestData request);
}

abstract class ICollectionRepository {
  Stream<List<ApiCollection>> get collectionsStream;
  List<ApiCollection> get currentCollections;
  Future<void> createCollection(String name, {String description = ''});
  Future<void> deleteCollection(String id);
  Future<void> saveRequest(String collectionId, ApiRequestModel request);
  Future<void> deleteRequest(String collectionId, String requestId);
}

abstract class ISettingsRepository {
  ProxyConfig getProxyConfig();
  Future<void> saveProxyConfig(ProxyConfig config);
  McpServerConfig getMcpConfig();
  Future<void> saveMcpConfig(McpServerConfig config);
  AiConfig getAiConfig();
  Future<void> saveAiConfig(AiConfig config);
}
