# ApiLab MCP Instructions for AI Agents 🤖

This document provides explicit instructions for AI models and assistants (such as OpenAI Codex, Claude, ChatGPT, Cursor, and Antigravity) on how to connect to, interact with, and automate workflows using the **ApiLab MCP Server**.

---

## 1. Connection & Endpoints

ApiLab runs a built-in MCP server on port `8765` bound to `0.0.0.0` (accessible via loopback `127.0.0.1` and local LAN IP `192.168.x.x`).

| Protocol / Transport | URL | Purpose |
| :--- | :--- | :--- |
| **Streamable HTTP (Recommended)** | `http://127.0.0.1:8765/mcp` | Modern MCP 2024-11-05 transport (Codex, Cursor) |
| **Server-Sent Events (SSE)** | `http://127.0.0.1:8765/sse` | Legacy SSE transport (Claude Desktop) |
| **Info / Health Check** | `http://127.0.0.1:8765/info` | GET request returns online status, endpoints & tool list |

### Client Configuration Examples

#### OpenAI Codex (`~/.codex/config.toml`):
```toml
[mcp_servers.apilab]
url = "http://127.0.0.1:8765/mcp"
```

#### Claude Desktop (`~/Library/Application Support/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "apilab": {
      "url": "http://127.0.0.1:8765/sse"
    }
  }
}
```

#### Antigravity / Gemini CLI (`.agents/plugins/apilab/mcp_config.json`):
```json
{
  "mcpServers": {
    "apilab": {
      "serverUrl": "http://127.0.0.1:8765/mcp"
    }
  }
}
```

---

## 2. Real-Time MCP Resources

You can inspect ApiLab state directly via MCP resources:

- **`apilab://traffic`**: JSON array of recently captured HTTP/HTTPS requests, headers, and responses.
- **`apilab://projects`**: List of all mock projects and their active/disabled rules.
- **`apilab://rules`**: All defined mock rules and their condition logic.

---

## 3. Tool Reference for AI Agents

### 1. `apilab_get_traffic`
Fetch intercepted network traffic with optional filtering.
- **`limit`** *(integer)*: Max requests to return (default 50).
- **`urlFilter`** *(string)*: Substring to match in URL (e.g. `auth`, `login`, `orders`).
- **`methodFilter`** *(string)*: `GET`, `POST`, `PUT`, `DELETE`, etc.
- **`statusFilter`** *(string)*: `pending`, `intercepted`, `completed`, `failed`, `mocked`.
- **`mockedOnly`** *(boolean)*: Show only mocked responses.
- **`searchQuery`** *(string)*: Full-text search across URLs, query params, headers, and bodies.

### 2. `apilab_get_traffic_detail`
Get full information for a specific request.
- **`id`** *(string, required)*: The traffic item ID.

### 3. `apilab_create_project`
Create a project to organize mock rules.
- **`projectName`** *(string, required)*: The project name (e.g. `User Simulation`).

### 4. `apilab_list_projects`
List all mock projects and their rule statistics.

### 5. `apilab_create_mock`
Create and immediately activate a conditional mock rule.
- **`name`** *(string, required)*: Descriptive name (e.g. `Simulate Login Mr X`).
- **`projectName`** *(string)*: Project name to group under.
- **`urlPattern`** *(string, required)*: Matching URL with wildcards (e.g. `*/api/v1/auth/login*`).
- **`matchMethod`** *(string)*: `GET`, `POST`, `PUT`, `DELETE`, `ALL` (default `ALL`).
- **`conditions`** *(array of objects)*:
  - `source`: `"body"`, `"query"`, `"header"`, or `"any"`
  - `field`: Field name to inspect (e.g. `username`)
  - `operator`: `"="`, `"!="`, `"contains"`, `">"`, `"<"`, `">="`, `"<="`, `"regex"`
  - `value`: Expected value (e.g. `"mr_x"`)
- **`conditionLogic`** *(string)*: `"AND"` or `"OR"` (default `"AND"`).
- **`customVariables`** *(object)*: Map of custom variables available for interpolation.
- **`statusCode`** *(integer)*: HTTP status code to return (default `200`).
- **`responseHeaders`** *(object)*: Headers to return (e.g. `{"content-type": "application/json"}`).
- **`responseBody`** *(string, required)*: Response payload JSON or text. Supports template variables like `{{username}}`, `{{timestamp}}`.
- **`delayMs`** *(integer)*: Latency simulation in milliseconds.
- **`isEnabled`** *(boolean)*: Default `true`.

### 6. `apilab_list_rules`
List all mock rules with optional filters (`projectName`, `urlFilter`, `methodFilter`, `isEnabledOnly`).

### 7. `apilab_update_mock`
Update an existing mock rule by `id`.

### 8. `apilab_toggle_mock`
Toggle a rule ON or OFF by `id` (`isEnabled`: true/false).

### 9. `apilab_delete_mock`
Permanently delete a mock rule by `id`.

### 10. `apilab_generate_fake_response`
Synthesize realistic mock data using ApiLab's AI engine for an endpoint.
- **`endpointUrl`** *(string, required)*
- **`method`** *(string, required)*
- **`statusCode`** *(integer)*
- **`description`** *(string)*

### 11. `apilab_send_request`
Replay or test an HTTP request directly through ApiLab and inspect the real response.
- **`url`** *(string, required)*
- **`method`** *(string, required)*
- **`headers`** *(object)*
- **`body`** *(string)*

---

## 4. End-to-End Workflow Examples for AI

### Scenario: Simulate Login for User "Mr X"

When asked: *"Analyze the app login request and mock the response when user logs in as mr_x"*

1. **Step 1: Inspect Traffic**
   ```json
   {
     "name": "apilab_get_traffic",
     "arguments": {
       "urlFilter": "login"
     }
   }
   ```
2. **Step 2: Inspect Payload Details**
   ```json
   {
     "name": "apilab_get_traffic_detail",
     "arguments": {
       "id": "traffic-id-from-step-1"
     }
   }
   ```
3. **Step 3: Create Project (if needed)**
   ```json
   {
     "name": "apilab_create_project",
     "arguments": {
       "projectName": "Auth Simulations"
     }
   }
   ```
4. **Step 4: Create Conditional Mock Rule**
   ```json
   {
     "name": "apilab_create_mock",
     "arguments": {
       "name": "Simulate Login Mr X",
       "projectName": "Auth Simulations",
       "urlPattern": "*/api/v1/auth/login*",
       "matchMethod": "POST",
       "conditionLogic": "AND",
       "conditions": [
         {
           "source": "body",
           "field": "username",
           "operator": "=",
           "value": "mr_x"
         }
       ],
       "statusCode": 200,
       "responseHeaders": {
         "content-type": "application/json"
       },
       "responseBody": "{\n  \"status\": \"SUCCESS\",\n  \"user_id\": 99401,\n  \"username\": \"mr_x\",\n  \"role\": \"Enterprise Admin\",\n  \"token\": \"mocked-jwt-token-for-mr-x\"\n}"
     }
   }
   ```
5. **Step 5: Confirm Rule is Active**
   ```json
   {
     "name": "apilab_list_rules",
     "arguments": {
       "projectName": "Auth Simulations"
     }
   }
   ```

Any app routing traffic through ApiLab (`port 8888`) that sends a POST to `/api/v1/auth/login` with `{"username": "mr_x"}` will now immediately receive the mocked response!
