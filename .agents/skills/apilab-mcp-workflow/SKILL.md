---
name: apilab-mcp-workflow
description: >-
  Work with the ApiLab desktop application via its Model Context Protocol (MCP) server.
  Use when inspecting intercepted network traffic, analyzing HTTP/HTTPS requests and responses,
  creating or managing mock projects, and generating conditional mock rules to simulate API behavior.
---

# ApiLab MCP Workflow Skill

This skill teaches agents how to inspect, analyze, and manipulate intercepted HTTP/HTTPS network traffic and create conditional mock rules using the **ApiLab MCP Server**.

---

## 1. Connecting to ApiLab MCP Server

ApiLab runs an embedded MCP server listening on `0.0.0.0:8765` supporting both **Streamable HTTP** (recommended) and **Server-Sent Events (SSE)**.

- **Primary Streamable HTTP URL**: `http://127.0.0.1:8765/mcp` (or your LAN IP e.g. `http://192.168.0.101:8765/mcp`)
- **Legacy SSE URL**: `http://127.0.0.1:8765/sse`
- **Info / Health Endpoint**: `http://127.0.0.1:8765/info`

### Client Configurations

#### OpenAI Codex (`~/.codex/config.toml`):
```toml
[mcp_servers.apilab]
url = "http://127.0.0.1:8765/mcp"
```

#### Claude Desktop (`claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "apilab": {
      "url": "http://127.0.0.1:8765/sse"
    }
  }
}
```

---

## 2. Core Capabilities & MCP Resources

ApiLab exposes three real-time resources that can be read via `resources/read`:

| Resource URI | Description |
| :--- | :--- |
| `apilab://traffic` | Real-time JSON list of all intercepted requests and responses. |
| `apilab://projects` | List of all mock projects, rule counts, and active rule names. |
| `apilab://rules` | Complete set of active and inactive mock rules with conditions. |

---

## 3. Available MCP Tools Reference

### Traffic Inspection Tools
- **`apilab_get_traffic`**:
  - `limit` (integer): Max items to return (default 50).
  - `urlFilter` (string): Filter URL substring (e.g. `auth/login` or `users`).
  - `methodFilter` (string): Filter HTTP method (`GET`, `POST`, `PUT`, `DELETE`).
  - `statusFilter` (string): `pending`, `intercepted`, `completed`, `failed`, `mocked`.
  - `mockedOnly` (boolean): Show only intercepted requests that triggered a mock rule.
  - `searchQuery` (string): Full-text search across URL, request body, and response body.
- **`apilab_get_traffic_detail`**:
  - `id` (string, required): Intercepted traffic item ID to inspect complete headers, query parameters, request body, and response body.
- **`apilab_clear_traffic`**:
  - Clear intercepted traffic history.

### Project Management Tools
- **`apilab_list_projects`**: List all mock projects and their rule statistics.
- **`apilab_create_project`**:
  - `projectName` (string, required): Create a new mock project category.

### Mock Rule Tools
- **`apilab_list_rules`**:
  - `projectName` (string): Optional project filter.
  - `urlFilter` (string): Optional URL filter.
  - `methodFilter` (string): Optional HTTP method filter.
  - `isEnabledOnly` (boolean): Filter active rules only.
- **`apilab_get_rule_detail`**:
  - `id` (string, required): Get full conditions and response template for a rule.
- **`apilab_create_mock`**:
  - `name` (string, required): Descriptive rule name (e.g. `Simulate Login Mr X`).
  - `projectName` (string): Project to organize under (defaults to `Default Project`).
  - `urlPattern` (string, required): Wildcard pattern (e.g. `*/api/v1/auth/login*` or `/api/users*`) or regex.
  - `matchMethod` (string): `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, or `ALL` (default `ALL`).
  - `isRegex` (boolean): Whether `urlPattern` is a regex.
  - `conditionLogic` (string): `AND` or `OR` (default `AND`).
  - `conditions` (array): List of condition objects:
    - `source`: `any`, `query`, `body`, or `header`
    - `field`: key to check (e.g. `username`, `isUserType`, `Authorization`)
    - `operator`: `=`, `!=`, `contains`, `>`, `<`, `>=`, `<=`, `regex`
    - `value`: expected value (e.g. `mr_x`)
  - `matchQueryParams` (object): Optional key-value query parameters to match.
  - `matchHeaders` (object): Optional key-value headers to match.
  - `matchBody` (string): Optional body substring matcher.
  - `customVariables` (object): Key-value variables available for template interpolation (e.g. `{"role": "Admin", "token": "xyz"}`).
  - `statusCode` (integer): HTTP status code to return (default 200).
  - `responseHeaders` (object): Headers to include in the mock response.
  - `responseBody` (string, required): Response payload. Supports template variables `{{username}}`, `{{timestamp}}`, `{{query.param}}`, etc.
  - `delayMs` (integer): Simulated latency delay in milliseconds.
  - `isEnabled` (boolean): Whether rule is active immediately (default true).
- **`apilab_update_mock`**: Update any property of an existing mock rule by `id`.
- **`apilab_toggle_mock`**: Enable or disable a rule by `id`.
- **`apilab_delete_mock`**: Delete a rule by `id`.
- **`apilab_generate_fake_response`**: Use synthetic data engine to generate realistic JSON based on endpoint and description.
- **`apilab_send_request`**: Send an HTTP request through ApiLab and view latency and response.

---

## 4. Standard Agent Procedures

### Procedure A: Simulating an App Scenario (e.g. "Login as User X")

1. **Inspect Intercepted Traffic**:
   Call `apilab_get_traffic` with `urlFilter: "login"` or `methodFilter: "POST"` to find the endpoint and request structure.
2. **Examine Payload Structure**:
   Call `apilab_get_traffic_detail` with the traffic `id` to see the exact field names in the JSON body (e.g. `username`, `email`, etc.).
3. **Ensure Project Exists**:
   Call `apilab_list_projects`. If a dedicated project doesn't exist, call `apilab_create_project` (e.g. `User Simulation`).
4. **Create Conditional Mock Rule**:
   Call `apilab_create_mock` with:
   - `name`: "Simulate Login Mr X"
   - `projectName`: "User Simulation"
   - `urlPattern`: match the endpoint pattern (e.g. `*/api/v1/auth/login*`)
   - `matchMethod`: "POST"
   - `conditions`: check that `body.username = "mr_x"`
   - `statusCode`: 200
   - `responseBody`: structured JSON containing synthetic auth token and profile.
5. **Verify**:
   Call `apilab_list_rules` to confirm the rule is registered and enabled.

### Procedure B: Diagnosing Intercepted API Errors

1. Call `apilab_get_traffic` with `statusFilter: "failed"` or search for 4xx/5xx status codes.
2. Call `apilab_get_traffic_detail` to retrieve the complete server error payload and request headers.
3. Formulate the fix or create a mock rule to simulate a successful response while backend services are down.
