# ApiLab 🔬

**ApiLab** is a cross-platform desktop developer suite built with Flutter that intercepts HTTP/HTTPS traffic, replays & tests requests with a Postman-like client, simulates realistic mock responses, and integrates directly with AI agents via the **Model Context Protocol (MCP)**.

---

## 🌟 Key Features

1. **HTTP/HTTPS Traffic Interception**:
   - Built-in high-performance local proxy server (default port `8888`).
   - Intercepts requests, headers, query parameters, and payload bodies in real-time.
   - HTTPS `CONNECT` tunneling & MITM decryption with root CA certificate export.
   - Real-time filtering by HTTP method (GET, POST, etc.), status code (2xx, 4xx, 5xx, Mocked), or text search.
   - One-click copy cURL command.

2. **Postman-like Request Composer & Tester**:
   - Replay, customize, and test any intercepted or standalone HTTP request.
   - Dynamic parameters editor for URL Query Params, Request Headers, and Body types (JSON, Form-Data, Text, None).
   - Built-in JSON prettifier and validation.
   - Authentication support (Bearer Token, Basic Auth).
   - Exact latency benchmarking (ms), byte size metrics, and status badges.
   - Save requests into organized **Collections**.

3. **Configurable Mock Response Engine**:
   - Intercept incoming requests and return synthetic responses without hitting remote servers.
   - Flexible matching criteria: HTTP method, URL pattern (wildcard `*` or regular expressions `RegExp`), and header matchers.
   - Customizable status codes (200, 201, 400, 500, etc.), headers, body payload, and simulated latency delay (ms).
   - Easily toggle mock rules ON/OFF with live updates.

4. **AI & Model Context Protocol (MCP) Agent Hub**:
   - **Embedded MCP Server**: Runs on `http://127.0.0.1:8765/sse` and `/messages` using JSON-RPC 2.0.
   - Connect any AI assistant (**Claude Desktop**, **Cursor**, **Antigravity**, **LangChain**, or custom agents).
   - **Exposed MCP Tools**:
     - `apilab_get_traffic`: AI inspects captured HTTP/HTTPS requests & responses.
     - `apilab_create_mock`: AI creates mock rules on the fly based on user prompts or schemas.
     - `apilab_generate_fake_response`: AI synthesizes realistic mock data.
     - `apilab_send_request`: AI executes requests and tests backend endpoints.
     - `apilab_list_mocks`: AI queries active mock rules.
   - **AI Mock Studio**: Generate realistic mock JSON with local LLMs (Ollama, LM Studio), OpenAI-compatible endpoints, or the built-in instant heuristic generator.

5. **Desktop-First Experience**:
   - Tailored specifically for desktop with dual-pane resizable split views, monospace inspectors, and custom developer dark theme.
   - Supports **macOS (Intel & Apple Silicon ARM64)**, **Windows (x64 & ARM64)**, and **Linux (x64 & ARM64)**.

---

## 🏛️ Architecture: MVVM + DDD + Clean Architecture

ApiLab strictly follows **Clean Architecture**, **Domain-Driven Design (DDD)**, and the **MVVM** pattern:

```
lib/
├── domain/                      # 1. DOMAIN LAYER (Pure Dart, Zero UI dependencies)
│   ├── models/                  # Entities & Value Objects (HttpRequestData, HttpResponseData, MockRule, ApiRequestModel, McpServerConfig, AiConfig)
│   ├── repositories/            # Repository Interfaces (ITrafficRepository, IMockRuleRepository, ICollectionRepository, ISettingsRepository)
│   └── use_cases/               # Business Logic & Interactors (InterceptRequestUseCase, ReplayRequestUseCase, GenerateMockResponseUseCase)
│
├── data/                        # 2. DATA LAYER (Implementations)
│   └── repositories/            # Repository implementations (TrafficRepositoryImpl, MockRuleRepositoryImpl, CollectionRepositoryImpl, SettingsRepositoryImpl)
│
├── infrastructure/              # 3. INFRASTRUCTURE LAYER (Network, Protocols & OS)
│   ├── proxy/                   # ProxyServer (HTTP/HTTPS interceptor, tunnel, mock evaluator), SslCertificateManager
│   └── mcp/                     # McpServer (JSON-RPC 2.0, SSE endpoint, tool execution)
│
└── ui/                          # 4. PRESENTATION / UI LAYER (MVVM)
    ├── core/                    # AppTheme, DesktopSplitPane, MethodBadge, StatusBadge
    └── features/
        ├── interceptor/         # InterceptorViewModel & InterceptorView
        ├── composer/            # ComposerViewModel & ComposerView (Postman-like client)
        ├── mocks/               # MocksViewModel & MocksView
        ├── mcp/                 # McpHubViewModel & McpHubView
        ├── settings/            # SettingsViewModel & SettingsView
        └── shell/               # DesktopShell (desktop sidebar navigation & status bar)
```

---

## 🚀 Running ApiLab

### Requirements
- Flutter 3.16+ (Dart 3.2+)
- macOS, Windows, or Linux desktop developer environment

### Run on macOS Desktop
```bash
flutter run -d macos
```

### Run on Windows Desktop
```bash
flutter run -d windows
```

### Run on Linux Desktop
```bash
flutter run -d linux
```

### Run Tests
```bash
flutter test
```

---

## 🤖 Connecting AI Agents via MCP

Add the following to your AI client configuration (e.g. `claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "apilab": {
      "url": "http://127.0.0.1:8765/sse"
    }
  }
}
```

Now your AI assistant can inspect captured API traffic, diagnose backend bugs, send test requests, and generate synthetic mocks automatically!
