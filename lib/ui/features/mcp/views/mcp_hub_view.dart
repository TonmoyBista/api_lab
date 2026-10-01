import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/mcp_and_ai.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/desktop_split_pane.dart';
import '../../mocks/view_models/mocks_view_model.dart';
import '../view_models/mcp_hub_view_model.dart';

class McpHubView extends StatefulWidget {
  final VoidCallback onNavigateToMocks;

  const McpHubView({super.key, required this.onNavigateToMocks});

  @override
  State<McpHubView> createState() => _McpHubViewState();
}

class _McpHubViewState extends State<McpHubView> {
  late TextEditingController _promptController;
  late TextEditingController _endpointController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<McpHubViewModel>();
    _promptController = TextEditingController(text: vm.testPrompt);
    _endpointController = TextEditingController(text: vm.testEndpoint);
    _baseUrlController = TextEditingController(text: vm.aiConfig.baseUrl);
    _modelController = TextEditingController(text: vm.aiConfig.modelName);
    _apiKeyController = TextEditingController(text: vm.aiConfig.apiKey);
  }

  @override
  void dispose() {
    _promptController.dispose();
    _endpointController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<McpHubViewModel>();

    return Scaffold(
      body: DesktopSplitPane(
        initialRatio: 0.40,
        minFirstRatio: 0.30,
        maxFirstRatio: 0.55,
        firstChild: _buildLeftControlPanel(context, vm),
        secondChild: _buildRightTestingAndLogs(context, vm),
      ),
    );
  }

  Widget _buildLeftControlPanel(BuildContext context, McpHubViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // MCP Server Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hub_outlined, color: AppColors.primaryHover, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Model Context Protocol (MCP)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (vm.isServerRunning ? AppColors.methodGet : Colors.grey).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: (vm.isServerRunning ? AppColors.methodGet : Colors.grey).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        vm.isServerRunning ? 'ONLINE' : 'STOPPED',
                        style: TextStyle(
                          color: vm.isServerRunning ? AppColors.methodGet : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'ApiLab exposes standard MCP tools so AI agents (Claude Desktop, Cursor, Antigravity, custom agents) can read traffic, replay calls, and generate mocks.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                _buildInfoBadge('Local Endpoint', vm.localSseUrl),
                if (vm.lanIp != '127.0.0.1' && vm.lanIp.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoBadge('LAN Wi-Fi Endpoint', vm.lanSseUrl),
                ],
                const SizedBox(height: 6),
                _buildInfoBadge('Active Clients', '${vm.activeClients} Connected'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: vm.toggleMcpServer,
                      icon: Icon(vm.isServerRunning ? Icons.stop : Icons.play_arrow, size: 16),
                      label: Text(vm.isServerRunning ? 'Stop MCP Server' : 'Start MCP Server'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vm.isServerRunning ? AppColors.methodDelete : AppColors.methodGet,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: vm.getClaudeDesktopConfigSnippet(useLan: true)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('MCP configuration (LAN) copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy JSON Config'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: vm.getCodexCliCommand(useLan: true)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Codex CLI command copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.terminal, size: 14),
                      label: const Text('Copy Codex Command'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // AI Model Engine Settings
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology_outlined, color: AppColors.secondary, size: 20),
                    SizedBox(width: 8),
                    Text('AI Generator Provider', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AiProviderType>(
                  isExpanded: true,
                  initialValue: vm.aiConfig.providerType,
                  decoration: const InputDecoration(labelText: 'AI Engine Mode'),
                  dropdownColor: AppColors.surfaceLight,
                  items: const [
                    DropdownMenuItem(
                      value: AiProviderType.heuristic,
                      child: Text('Built-in Heuristic (Instant, No API Key needed)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: AiProviderType.ollama,
                      child: Text('Ollama (Local LLM - localhost:11434)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: AiProviderType.lmStudio,
                      child: Text('LM Studio (Local LLM - localhost:1234)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: AiProviderType.openAiCompatible,
                      child: Text('OpenAI Compatible / Cloud LLM', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      vm.updateAiConfig(providerType: v);
                    }
                  },
                ),
                if (vm.aiConfig.providerType != AiProviderType.heuristic) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _baseUrlController,
                    onChanged: (v) => vm.updateAiConfig(baseUrl: v),
                    decoration: const InputDecoration(labelText: 'Base URL (OpenAI compatible endpoint)'),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _modelController,
                    onChanged: (v) => vm.updateAiConfig(modelName: v),
                    decoration: const InputDecoration(labelText: 'Model Name (e.g. llama3, gpt-4o, mistral)'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    onChanged: (v) => vm.updateAiConfig(apiKey: v),
                    decoration: const InputDecoration(labelText: 'API Key (Optional for local models)'),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightTestingAndLogs(BuildContext context, McpHubViewModel vm) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: const TabBar(
              labelColor: AppColors.primaryHover,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(icon: Icon(Icons.auto_awesome, size: 16), text: 'AI Mock Generator Studio'),
                Tab(icon: Icon(Icons.terminal, size: 16), text: 'Live MCP Agent Logs'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _buildMockStudioTab(context, vm),
                _buildMcpLogsTab(context, vm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockStudioTab(BuildContext context, McpHubViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Generate Realistic Fake Response with AI',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'Provide an endpoint path and describe the synthetic data you need. The AI will output valid production-grade JSON mock structures.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: vm.testMethod,
                decoration: const InputDecoration(labelText: 'Method'),
                dropdownColor: AppColors.surfaceLight,
                items: ['GET', 'POST', 'PUT', 'DELETE']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) vm.updateTestMethod(v);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _endpointController,
                onChanged: vm.updateTestEndpoint,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(labelText: 'API Endpoint / Path', hintText: '/api/v1/orders'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: vm.testStatusCode,
                decoration: const InputDecoration(labelText: 'Status'),
                dropdownColor: AppColors.surfaceLight,
                items: [200, 201, 400, 401, 404, 500]
                    .map((c) => DropdownMenuItem(value: c, child: Text('$c', overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) vm.updateTestStatusCode(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _promptController,
          onChanged: vm.updateTestPrompt,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Data Description / Instructions for AI',
            hintText: 'e.g., 3 user profiles with email, role, avatar, and last login timestamp',
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: vm.isTestingPrompt ? null : vm.runTestGeneration,
              icon: vm.isTestingPrompt
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Generate Fake Response'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusMock),
            ),
            if (vm.testOutput.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: vm.testOutput));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied JSON output to clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy JSON'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final mocksVm = context.read<MocksViewModel>();
                  mocksVm.createNewRule();
                  mocksVm.updateEditingField(
                    name: 'Mock: ${vm.testEndpoint}',
                    matchMethod: vm.testMethod,
                    urlPattern: '*${vm.testEndpoint}*',
                    responseStatusCode: vm.testStatusCode,
                    responseBody: vm.testOutput,
                    description: vm.testPrompt,
                  );
                  mocksVm.saveCurrentRule();
                  widget.onNavigateToMocks();
                },
                icon: const Icon(Icons.add_task, size: 14),
                label: const Text('Add as Active Mock Rule'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 350,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              vm.testOutput.isEmpty ? '// Generated mock JSON response will appear here...' : vm.testOutput,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.4,
                color: vm.testOutput.isEmpty ? AppColors.textMuted : AppColors.textMain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMcpLogsTab(BuildContext context, McpHubViewModel vm) {
    if (vm.logs.isEmpty) {
      return const Center(
        child: Text('No MCP requests recorded yet. Connect an AI agent via SSE.', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return ListView.builder(
      itemCount: vm.logs.length,
      itemBuilder: (context, index) {
        final log = vm.logs[index];
        final isIn = log.direction == 'IN';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isIn ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      log.direction,
                      style: TextStyle(
                        color: isIn ? AppColors.primary : AppColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    log.timestamp.toLocal().toString().substring(11, 19),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText(
                log.payload,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMain),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.primaryHover),
          ),
        ),
      ],
    );
  }
}
