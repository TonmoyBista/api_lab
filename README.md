# ApiLab 🔬

[![Build and Release Desktop Apps](https://github.com/TonmoyBista/api_lab/actions/workflows/release.yml/badge.svg)](https://github.com/TonmoyBista/api_lab/actions/workflows/release.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Linux-blue)](#)
[![Model Context Protocol](https://img.shields.io/badge/MCP-2024--11--05-green?logo=anthropic&logoColor=white)](https://modelcontextprotocol.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**ApiLab** is a cross-platform desktop developer suite built with Flutter that intercepts HTTP/HTTPS traffic, replays & tests requests with a Postman-like client, simulates realistic mock responses with conditional logic, and integrates directly with AI agents via the **Model Context Protocol (MCP)**.

---

## 🌟 Key Features

### 1. HTTP/HTTPS Traffic Interception
- **High-Performance Local Proxy Server**: Listens on `0.0.0.0:8888` (configurable).
- **Full Payload Inspection**: Real-time capture of request/response headers, query parameters, and bodies.
- **HTTPS CONNECT Tunneling & MITM Decryption**: Includes built-in SSL root CA certificate export for client trust.
- **Instant Filtering**: Filter by HTTP method (`GET`, `POST`, `PUT`, `DELETE`), status code (2xx, 4xx, 5xx, Mocked), or text search.
- **Developer Utilities**: One-click copy cURL command, JSON prettifier, and hex/text view.

### 2. Postman-like Request Composer & Tester
- Replay, modify, and test any intercepted or custom HTTP request.
- Tabbed editor for Query Parameters, Headers, and Body types (`JSON`, `Form-Data`, `Text`, `None`).
- Authentication options: Bearer Token, Basic Auth, and custom headers.
- Accurate latency benchmarking (ms), byte size metrics, and status code indicators.
- Save and organize requests into reusable **Collections**.

### 3. Conditional Mock Response Engine
- **Intercept & Synthesize**: Short-circuit incoming requests and return synthetic responses without hitting live backends.
- **Conditional Match Rules**: Match by URL pattern (wildcard `*` or regular expression), HTTP method, headers, query params, and JSON body values.
- **Logical Grouping**: Combine conditions with `AND` or `OR` operators.
- **Dynamic Variable Interpolation**: Use template placeholders like `{{username}}`, `{{timestamp}}`, `{{query.param}}`, and custom variables.
- **Simulated Latency**: Configure millisecond delays to test slow network edge-cases.
- **Project Organization**: Group rules by project for clean multi-app workflows.

### 4. Embedded Model Context Protocol (MCP) Server
- **Dual Transport**: Supports both **Streamable HTTP** (`/mcp`) and **Server-Sent Events** (`/sse`) on port `8765`.
- **Full Agent Control**: Connect **OpenAI Codex**, **Claude Desktop**, **Cursor**, **Antigravity**, or custom agents.
- **14 AI Tools**:
  - `apilab_get_traffic`: Inspect captured HTTP traffic.
  - `apilab_get_traffic_detail`: View full request and response headers/bodies.
  - `apilab_create_project`: Create organized mock projects.
  - `apilab_create_mock`: Generate conditional mock rules on the fly.
  - `apilab_list_rules`: Read and filter mock rules.
  - `apilab_update_mock`: Modify rules programmatically.
  - `apilab_toggle_mock`: Enable or disable rules dynamically.
  - `apilab_delete_mock`: Clean up obsolete rules.
  - `apilab_generate_fake_response`: Synthesize realistic mock data.
  - `apilab_send_request`: Execute and benchmark API requests.
- **Real-Time Resources**: AI can read `apilab://traffic`, `apilab://projects`, and `apilab://rules`.

---

## 🤖 Connecting AI Agents via MCP

ApiLab runs an embedded MCP server on port `8765`.

| Client | Config File | Config Snippet |
| :--- | :--- | :--- |
| **OpenAI Codex** | `~/.codex/config.toml` | `[mcp_servers.apilab]`<br>`url = "http://127.0.0.1:8765/mcp"` |
| **Claude Desktop** | `claude_desktop_config.json` | `{"mcpServers": {"apilab": {"url": "http://127.0.0.1:8765/sse"}}}` |
| **Antigravity / Gemini** | `.agents/plugins/apilab/mcp_config.json` | `{"mcpServers": {"apilab": {"serverUrl": "http://127.0.0.1:8765/mcp"}}}` |

> 📘 **Detailed Guide**: See [MCP_INSTRUCTIONS.md](MCP_INSTRUCTIONS.md) and the [.agents/skills/apilab-mcp-workflow/SKILL.md](.agents/skills/apilab-mcp-workflow/SKILL.md) skill.

### Example Prompt for AI (e.g. Codex or Claude):
```text
Connect to ApiLab MCP at http://127.0.0.1:8765/mcp.
1. Inspect intercepted traffic using `apilab_get_traffic` to find the user login request.
2. Create a mock project named "User Simulation".
3. Create a mock rule using `apilab_create_mock` that matches POST requests to the login endpoint where body.username == "mr_x", and returns a 200 OK with a simulated JWT token and admin profile.
```

---

## 🏛️ Architecture: MVVM + DDD + Clean Architecture

ApiLab strictly enforces **Domain-Driven Design (DDD)** and the **MVVM** pattern:

```text
lib/
├── domain/                      # 1. DOMAIN LAYER (Pure Dart, Zero UI dependencies)
│   ├── models/                  # Entities & Value Objects (HttpRequestData, HttpResponseData, MockRule, ApiRequestModel)
│   ├── repositories/            # Repository Interfaces (ITrafficRepository, IMockRuleRepository, ISettingsRepository)
│   └── use_cases/               # Use Cases (InterceptRequestUseCase, ReplayRequestUseCase, GenerateMockResponseUseCase)
│
├── data/                        # 2. DATA LAYER (Data Access & Persistence)
│   └── repositories/            # Repository implementations (TrafficRepositoryImpl, MockRuleRepositoryImpl, SettingsRepositoryImpl)
│
├── infrastructure/              # 3. INFRASTRUCTURE LAYER (Protocols & Networking)
│   ├── proxy/                   # ProxyServer (HTTP/HTTPS interceptor, MITM decrypter, mock router)
│   └── mcp/                     # McpServer (JSON-RPC 2.0, Streamable HTTP /mcp, SSE /sse, MCP tools)
│
└── ui/                          # 4. PRESENTATION / UI LAYER (MVVM)
    ├── core/                    # AppTheme, DesktopSplitPane, MethodBadge, StatusBadge
    └── features/
        ├── interceptor/         # InterceptorViewModel & InterceptorView
        ├── composer/            # ComposerViewModel & ComposerView (Postman-like client)
        ├── mocks/               # MocksViewModel & MocksView
        ├── mcp/                 # McpHubViewModel & McpHubView
        └── shell/               # DesktopShell (desktop sidebar navigation & status bar)
```

---

## 🌿 Development & Release Workflow

We maintain a strict two-branch workflow:

1. **`development` Branch (Daily Coding)**:
   - All code, features, and fixes are developed and committed on the `development` branch.
2. **`release` Branch (Production Releases)**:
   - When ready for a release, merge or push `development` to `release`.
   - Pushing to `release` automatically triggers the multi-platform GitHub Actions build pipeline.

### Automatic Multi-Platform CI/CD

On every push to `release`, GitHub Actions automatically compiles and packages desktop release bundles for:

- **macOS (Apple Silicon M1–M4 ARM64)**: `api_lab-macos-arm64.zip`
- **macOS (Intel x86_64)**: `api_lab-macos-intel-x64.zip`
- **Windows (Intel/AMD64 x64)**: `api_lab-windows-x64.zip`
- **Linux (Intel/AMD64 x64)**: `api_lab-linux-x64.tar.gz`
- **Linux (ARM64)**: `api_lab-linux-arm64.tar.gz`

All compiled packages are automatically attached to a GitHub Release tagged with the app's version (e.g. `v1.0.0+1`).

---

## 🚀 Running Locally

### Prerequisites
- Flutter 3.16+ (Dart 3.2+)
- macOS, Windows, or Linux desktop environment

### Run Development App
```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

### Run Unit & Integration Tests
```bash
flutter test
```

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
