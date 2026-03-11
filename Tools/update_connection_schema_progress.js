#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const schemaRoot = path.join(repoRoot, "codex-schemas", "v0.112.0");
const generatedSwiftPath = path.join(repoRoot, "Codax", "Controllers", "Connection", "CodexSchema.generated.swift");
const connectionSwiftPaths = [
  generatedSwiftPath,
  path.join(repoRoot, "Codax", "Controllers", "Connection", "CodexConnection.swift"),
  path.join(repoRoot, "Codax", "Controllers", "Connection", "CodexConnection+Types.swift"),
];
const trackerPath = path.join(repoRoot, "Docs", "connection-schema-progress.md");
const verifyOnly = process.argv.includes("--verify");

const CLIENT_REQUEST_RESPONSES = {
  "initialize": "InitializeResponse",
  "thread/start": "ThreadStartResponse",
  "thread/resume": "ThreadResumeResponse",
  "thread/fork": "ThreadForkResponse",
  "thread/archive": "ThreadArchiveResponse",
  "thread/unsubscribe": "ThreadUnsubscribeResponse",
  "thread/name/set": "ThreadSetNameResponse",
  "thread/metadata/update": "ThreadMetadataUpdateResponse",
  "thread/unarchive": "ThreadUnarchiveResponse",
  "thread/compact/start": "ThreadCompactStartResponse",
  "thread/rollback": "ThreadRollbackResponse",
  "thread/list": "ThreadListResponse",
  "thread/loaded/list": "ThreadLoadedListResponse",
  "thread/read": "ThreadReadResponse",
  "skills/list": "SkillsListResponse",
  "skills/remote/list": "SkillsRemoteReadResponse",
  "skills/remote/export": "SkillsRemoteWriteResponse",
  "app/list": "AppsListResponse",
  "skills/config/write": "SkillsConfigWriteResponse",
  "plugin/install": "PluginInstallResponse",
  "turn/start": "TurnStartResponse",
  "turn/steer": "TurnSteerResponse",
  "turn/interrupt": "TurnInterruptResponse",
  "review/start": "ReviewStartResponse",
  "model/list": "ModelListResponse",
  "experimentalFeature/list": "ExperimentalFeatureListResponse",
  "mcpServer/oauth/login": "McpServerOauthLoginResponse",
  "config/mcpServer/reload": "McpServerRefreshResponse",
  "mcpServerStatus/list": "ListMcpServerStatusResponse",
  "windowsSandbox/setupStart": "WindowsSandboxSetupStartResponse",
  "account/login/start": "LoginAccountResponse",
  "account/login/cancel": "CancelLoginAccountResponse",
  "account/logout": "LogoutAccountResponse",
  "account/rateLimits/read": "GetAccountRateLimitsResponse",
  "feedback/upload": "FeedbackUploadResponse",
  "command/exec": "CommandExecResponse",
  "config/read": "ConfigReadResponse",
  "externalAgentConfig/detect": "ExternalAgentConfigDetectResponse",
  "externalAgentConfig/import": "ExternalAgentConfigImportResponse",
  "config/value/write": "ConfigWriteResponse",
  "config/batchWrite": "ConfigWriteResponse",
  "configRequirements/read": "ConfigRequirementsReadResponse",
  "account/read": "GetAccountResponse",
  "getConversationSummary": "GetConversationSummaryResponse",
  "gitDiffToRemote": "GitDiffToRemoteResponse",
  "getAuthStatus": "GetAuthStatusResponse",
  "fuzzyFileSearch": "FuzzyFileSearchResponse",
};

const ROOTS = [
  "ClientRequest",
  "ServerNotification",
  "ServerRequest",
  ...new Set(Object.values(CLIENT_REQUEST_RESPONSES)),
  "CommandExecutionRequestApprovalResponse",
  "FileChangeRequestApprovalResponse",
  "ToolRequestUserInputResponse",
  "McpServerElicitationRequestResponse",
  "DynamicToolCallResponse",
  "ChatgptAuthTokensRefreshResponse",
  "ApplyPatchApprovalResponse",
  "ExecCommandApprovalResponse",
];

const RESERVED = new Set([
  "protocol",
  "repeat",
  "return",
  "struct",
  "enum",
  "class",
  "extension",
  "func",
  "let",
  "var",
  "default",
  "switch",
  "case",
  "internal",
  "public",
  "private",
  "in",
  "Type",
]);

function stripComments(source) {
  return source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/\/\/.*$/gm, "");
}

function findTypeExpression(source, typeName) {
  const marker = `export type ${typeName}`;
  const start = source.indexOf(marker);
  if (start === -1) return null;
  const equals = source.indexOf("=", start);
  if (equals === -1) return null;
  let index = equals + 1;
  let depth = 0;
  let inString = false;
  let escaped = false;
  for (; index < source.length; index += 1) {
    const char = source[index];
    if (inString) {
      if (escaped) escaped = false;
      else if (char === "\\") escaped = true;
      else if (char === "\"") inString = false;
      continue;
    }
    if (char === "\"") {
      inString = true;
      continue;
    }
    if (char === "{" || char === "(" || char === "<" || char === "[") depth += 1;
    else if (char === "}" || char === ")" || char === ">" || char === "]") depth -= 1;
    else if (char === ";" && depth === 0) break;
  }
  return source.slice(equals + 1, index).trim();
}

class Tokenizer {
  constructor(input) {
    this.input = input;
    this.index = 0;
    this.tokens = [];
    this.position = 0;
    this.tokenize();
  }

  tokenize() {
    while (this.index < this.input.length) {
      const char = this.input[this.index];
      if (/\s/.test(char)) {
        this.index += 1;
        continue;
      }
      if (char === "\"") {
        this.tokens.push({ type: "string", value: this.readString() });
        continue;
      }
      if (/[A-Za-z_]/.test(char)) {
        this.tokens.push({ type: "identifier", value: this.readIdentifier() });
        continue;
      }
      if (/\d/.test(char)) {
        this.tokens.push({ type: "number", value: this.readNumber() });
        continue;
      }
      this.tokens.push({ type: char, value: char });
      this.index += 1;
    }
    this.tokens.push({ type: "EOF", value: "EOF" });
  }

  readString() {
    let result = "";
    this.index += 1;
    let escaped = false;
    while (this.index < this.input.length) {
      const char = this.input[this.index];
      this.index += 1;
      if (escaped) {
        result += char;
        escaped = false;
        continue;
      }
      if (char === "\\") {
        escaped = true;
        continue;
      }
      if (char === "\"") break;
      result += char;
    }
    return result;
  }

  readIdentifier() {
    const start = this.index;
    this.index += 1;
    while (this.index < this.input.length && /[A-Za-z0-9_]/.test(this.input[this.index])) {
      this.index += 1;
    }
    return this.input.slice(start, this.index);
  }

  readNumber() {
    const start = this.index;
    this.index += 1;
    while (this.index < this.input.length && /[0-9]/.test(this.input[this.index])) {
      this.index += 1;
    }
    return this.input.slice(start, this.index);
  }

  peek(offset = 0) {
    return this.tokens[this.position + offset];
  }

  next() {
    const token = this.tokens[this.position];
    this.position += 1;
    return token;
  }

  expect(type, value = null) {
    const token = this.next();
    if (token.type !== type || (value !== null && token.value !== value)) {
      throw new Error(`Expected ${value ?? type}, got ${token.type}:${token.value}`);
    }
    return token;
  }

  consume(type, value = null) {
    const token = this.peek();
    if (token.type === type && (value === null || token.value === value)) {
      this.position += 1;
      return true;
    }
    return false;
  }
}

function parseTypeExpression(source) {
  const tokenizer = new Tokenizer(source);
  const result = parseUnion(tokenizer);
  tokenizer.expect("EOF");
  return result;
}

function parseUnion(tokenizer) {
  let node = parseIntersection(tokenizer);
  const members = [node];
  while (tokenizer.consume("|")) {
    members.push(parseIntersection(tokenizer));
  }
  return members.length === 1 ? node : { kind: "union", members };
}

function parseIntersection(tokenizer) {
  let node = parsePrimary(tokenizer);
  const members = [node];
  while (tokenizer.consume("&")) {
    members.push(parsePrimary(tokenizer));
  }
  return members.length === 1 ? node : { kind: "intersection", members };
}

function parsePrimary(tokenizer) {
  const token = tokenizer.peek();
  if (token.type === "(") {
    tokenizer.next();
    const node = parseUnion(tokenizer);
    tokenizer.expect(")");
    return node;
  }
  if (token.type === "{") return parseObject(tokenizer);
  if (token.type === "identifier") {
    const name = tokenizer.next().value;
    if (name === "Array") {
      tokenizer.expect("<");
      const element = parseUnion(tokenizer);
      tokenizer.expect(">");
      return { kind: "array", element };
    }
    if (name === "Record") {
      tokenizer.expect("<");
      const key = parseUnion(tokenizer);
      tokenizer.expect(",");
      const value = parseUnion(tokenizer);
      tokenizer.expect(">");
      return { kind: "record", key, value };
    }
    if (["string", "number", "boolean", "null", "undefined", "bigint", "never"].includes(name)) {
      return { kind: "primitive", name };
    }
    return { kind: "reference", name };
  }
  if (token.type === "string") return { kind: "stringLiteral", value: tokenizer.next().value };
  if (token.type === "number") return { kind: "numberLiteral", value: Number(tokenizer.next().value) };
  throw new Error(`Unsupported token ${token.type}:${token.value}`);
}

function parseObject(tokenizer) {
  tokenizer.expect("{");
  const fields = [];
  let indexSignature = null;
  while (!tokenizer.consume("}")) {
    if (tokenizer.consume("[")) {
      tokenizer.expect("identifier");
      tokenizer.expect("identifier", "in");
      parseUnion(tokenizer);
      tokenizer.expect("]");
      tokenizer.consume("?");
      tokenizer.expect(":");
      indexSignature = parseUnion(tokenizer);
    } else {
      const keyToken = tokenizer.next();
      if (!["identifier", "string"].includes(keyToken.type)) {
        throw new Error(`Unsupported object key ${keyToken.type}:${keyToken.value}`);
      }
      const key = keyToken.value;
      const optional = tokenizer.consume("?");
      tokenizer.expect(":");
      const value = parseUnion(tokenizer);
      fields.push({ key, optional, value });
    }
    tokenizer.consume(",");
  }
  return { kind: "object", fields, indexSignature };
}

function walk(root, files) {
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    const fullPath = path.join(root, entry.name);
    if (entry.isDirectory()) walk(fullPath, files);
    else files.push(fullPath);
  }
}

function loadSchemaDefinitions() {
  const files = [];
  walk(schemaRoot, files);
  const definitions = new Map();
  for (const file of files) {
    if (!file.endsWith(".ts")) continue;
    const source = stripComments(fs.readFileSync(file, "utf8"));
    const match = source.match(/export type\s+([A-Za-z0-9_]+)\s*=/);
    if (!match) continue;
    const typeName = match[1];
    const expression = findTypeExpression(source, typeName);
    if (!expression) continue;
    definitions.set(typeName, {
      typeName,
      file,
      relative: path.relative(schemaRoot, file).replace(/\\/g, "/"),
      expression,
      ast: parseTypeExpression(expression),
    });
  }
  return definitions;
}

function collectReferences(node, into) {
  switch (node.kind) {
    case "reference":
      into.add(node.name);
      break;
    case "array":
      collectReferences(node.element, into);
      break;
    case "record":
      collectReferences(node.key, into);
      collectReferences(node.value, into);
      break;
    case "union":
    case "intersection":
      for (const member of node.members) collectReferences(member, into);
      break;
    case "object":
      for (const field of node.fields) collectReferences(field.value, into);
      if (node.indexSignature) collectReferences(node.indexSignature, into);
      break;
    default:
      break;
  }
}

function computeClosure(definitions) {
  const included = new Set();
  const queue = [...ROOTS];
  while (queue.length > 0) {
    const name = queue.pop();
    if (included.has(name)) continue;
    const definition = definitions.get(name);
    if (!definition) continue;
    included.add(name);
    const refs = new Set();
    collectReferences(definition.ast, refs);
    for (const ref of refs) {
      if (!included.has(ref) && definitions.has(ref)) queue.push(ref);
    }
  }
  return included;
}

function renameType(name) {
  if (name === "JsonValue") return "JSONValue";
  if (name === "Model") return "AppModel";
  return name;
}

function swiftCaseName(value) {
  const cleaned = value
    .replace(/[^A-Za-z0-9]+/g, " ")
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .map((part, index) => {
      const normalized = part.replace(/^[0-9]/, "_$&");
      return index === 0
        ? normalized[0].toLowerCase() + normalized.slice(1)
        : normalized[0].toUpperCase() + normalized.slice(1);
    })
    .join("");
  const finalValue = cleaned || "value";
  return RESERVED.has(finalValue) ? `\`${finalValue}\`` : finalValue;
}

function methodCaseName(method) {
  return swiftCaseName(method.replace(/[/.]/g, " "));
}

function methodFunctionName(method) {
  const parts = method.split("/").flatMap((part) => part.split(".")).filter(Boolean);
  const mapped = parts.map((part, index) => {
    const cleaned = part.replace(/[^A-Za-z0-9]+/g, " ");
    const token = cleaned
      .split(/\s+/)
      .filter(Boolean)
      .map((piece, pieceIndex) => {
        const normalized = piece.replace(/^[0-9]/, "_$&");
        if (index === 0 && pieceIndex === 0) return normalized[0].toLowerCase() + normalized.slice(1);
        return normalized[0].toUpperCase() + normalized.slice(1);
      })
      .join("");
    return token;
  });
  const value = mapped.join("");
  return RESERVED.has(value) ? `${value}Request` : value;
}

function parseUnionCases(definition) {
  const expression = definition.expression;
  return expression
    .split(/\}\s*\|\s*\{/)
    .map((chunk, index, array) => {
      let normalized = chunk.trim();
      if (index !== 0) normalized = `{ ${normalized}`;
      if (index !== array.length - 1) normalized = `${normalized} }`;
      return normalized;
    })
    .map((chunk) => {
      const methodMatch = chunk.match(/"method"\s*:\s*"([^"]+)"/);
      const paramsMatch = chunk.match(/params\s*:\s*([^,}]+)/);
      return {
        method: methodMatch ? methodMatch[1] : null,
        paramsType: paramsMatch ? paramsMatch[1].trim() : null,
      };
    })
    .filter((entry) => entry.method);
}

function parseGeneratedDeclarations(source) {
  const types = new Map();
  for (const match of source.matchAll(/public\s+(?:(indirect)\s+)?(struct|enum|typealias|protocol|actor)\s+([A-Za-z_][A-Za-z0-9_]*)/g)) {
    const qualifier = match[1] ? `${match[1]} ` : "";
    types.set(match[3], `${qualifier}${match[2]}`.trim());
  }
  return types;
}

function typeStatus(typeName, declarations) {
  if (typeName === "ClientRequest" && declarations.has("CodexConnection")) return "envelope-api";
  if (typeName === "ServerNotification" && declarations.has("ServerNotificationEnvelope")) return "envelope";
  if (typeName === "ServerRequest" && declarations.has("ServerRequestEnvelope")) return "envelope";
  if (typeName === "RequestId" && declarations.has("JSONRPCID")) return "generated:enum(rename:JSONRPCID)";
  if (typeName === "JsonValue" && declarations.has("JSONValue")) return `generated:${declarations.get("JSONValue")}(rename:JSONValue)`;
  const swiftName = renameType(typeName);
  return declarations.has(swiftName) ? `generated:${declarations.get(swiftName)}` : "missing";
}

function yesNo(value) {
  return value ? "yes" : "no";
}

function renderTable(headers, rows) {
  const head = `| ${headers.join(" | ")} |`;
  const sep = `| ${headers.map(() => "---").join(" | ")} |`;
  return [head, sep, ...rows.map((row) => `| ${row.join(" | ")} |`)].join("\n");
}

function main() {
  const definitions = loadSchemaDefinitions();
  const reachable = computeClosure(definitions);
  const generatedSource = fs.readFileSync(generatedSwiftPath, "utf8");
  const connectionSource = connectionSwiftPaths.map((filePath) => fs.readFileSync(filePath, "utf8")).join("\n");
  const declarations = parseGeneratedDeclarations(connectionSource);

  const clientRequestCases = parseUnionCases(definitions.get("ClientRequest"));
  const serverNotificationCases = parseUnionCases(definitions.get("ServerNotification"));
  const serverRequestCases = parseUnionCases(definitions.get("ServerRequest"));

  const requestRows = clientRequestCases.map(({ method, paramsType }) => {
    const functionName = methodFunctionName(method);
    const responseType = CLIENT_REQUEST_RESPONSES[method] || "MISSING_RESPONSE_MAP";
    const hasFunction = new RegExp(`(?:public\\s+)?func ${functionName}\\(`).test(generatedSource);
    const hasResponseType = responseType !== "MISSING_RESPONSE_MAP" && declarations.has(renameType(responseType));
    return [
      `\`${method}\``,
      `\`${functionName}\``,
      `\`${paramsType ?? "undefined"}\``,
      `\`${responseType}\``,
      hasFunction && hasResponseType ? "done" : "missing",
    ];
  });

  const notificationRows = serverNotificationCases.map(({ method, paramsType }) => {
    const caseName = methodCaseName(method);
    const hasCase = new RegExp(`case ${caseName}\\(`).test(generatedSource);
    const hasDecode = new RegExp(`case "${method.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}"`).test(generatedSource);
    return [
      `\`${method}\``,
      `\`${caseName}\``,
      `\`${paramsType ?? "undefined"}\``,
      hasCase && hasDecode ? "done" : "missing",
    ];
  });

  const serverRequestRows = serverRequestCases.map(({ method, paramsType }) => {
    const caseName = methodCaseName(method);
    const hasEnvelopeCase = new RegExp(`case ${caseName}\\(`).test(generatedSource);
    const hasDecode = new RegExp(`case "${method.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}"`).test(generatedSource);
    const hasResponseCase = new RegExp(`ServerRequestResponse[\\s\\S]*case ${caseName}\\(`).test(generatedSource);
    return [
      `\`${method}\``,
      `\`${caseName}\``,
      `\`${paramsType ?? "undefined"}\``,
      hasEnvelopeCase && hasDecode && hasResponseCase ? "done" : "missing",
    ];
  });

  const allTypes = [...definitions.values()].sort((a, b) => a.typeName.localeCompare(b.typeName));
  const fullyRepresentedRows = allTypes.map((definition) => ({
    definition,
    status: typeStatus(definition.typeName, declarations),
  }));
  const reachableRows = allTypes
    .filter((definition) => reachable.has(definition.typeName))
    .map((definition) => [
      `\`${definition.typeName}\``,
      `\`${renameType(definition.typeName)}\``,
      `\`${typeStatus(definition.typeName, declarations)}\``,
      `\`${definition.relative}\``,
    ]);

  const nonReachableRows = allTypes
    .filter((definition) => !reachable.has(definition.typeName))
    .map((definition) => [
      `\`${definition.typeName}\``,
      `\`${renameType(definition.typeName)}\``,
      `\`${typeStatus(definition.typeName, declarations)}\``,
      `\`${definition.relative}\``,
    ]);

  const missingReachableTypes = allTypes
    .filter((definition) => reachable.has(definition.typeName))
    .filter((definition) => typeStatus(definition.typeName, declarations) === "missing")
    .map((definition) => `- \`${definition.typeName}\` from \`${definition.relative}\``);

  const missingExportedTypes = fullyRepresentedRows
    .filter(({ status }) => status === "missing")
    .map(({ definition }) => `- \`${definition.typeName}\` from \`${definition.relative}\``);

  const incompleteRequests = requestRows.filter((row) => row[4] !== "done").length;
  const incompleteNotifications = notificationRows.filter((row) => row[3] !== "done").length;
  const incompleteServerRequests = serverRequestRows.filter((row) => row[3] !== "done").length;

  const lines = [
    "# Connection Schema Progress",
    "",
    `Generated on ${new Date().toISOString()}.`,
    "",
    "This tracker is derived from the pinned `codex-schemas/v0.112.0` tree and checked against `Codax/Controllers/Connection/CodexSchema.generated.swift`.",
    "",
    "## Summary",
    "",
    `- Total exported schema types: ${allTypes.length}`,
    `- Exported schema types represented in connection Swift: ${allTypes.length - missingExportedTypes.length}`,
    `- Exported schema types still missing in connection Swift: ${missingExportedTypes.length}`,
    `- Reachable protocol-surface types: ${reachableRows.length}`,
    `- Non-reachable exported types: ${nonReachableRows.length}`,
    `- Client request methods: ${requestRows.length} (${incompleteRequests === 0 ? "all done" : `${incompleteRequests} missing`})`,
    `- Server notification methods: ${notificationRows.length} (${incompleteNotifications === 0 ? "all done" : `${incompleteNotifications} missing`})`,
    `- Server request methods: ${serverRequestRows.length} (${incompleteServerRequests === 0 ? "all done" : `${incompleteServerRequests} missing`})`,
    `- Reachable types missing generated Swift: ${missingReachableTypes.length}`,
    "",
    "## Client Requests",
    "",
    renderTable(["Method", "Swift API", "Params", "Response", "Status"], requestRows),
    "",
    "## Server Notifications",
    "",
    renderTable(["Method", "Envelope Case", "Params", "Status"], notificationRows),
    "",
    "## Server Requests",
    "",
    renderTable(["Method", "Envelope Case", "Params", "Status"], serverRequestRows),
    "",
    "## Reachable Types",
    "",
    renderTable(["Schema Type", "Swift Type", "Status", "Schema File"], reachableRows),
    "",
    "## Missing Reachable Types",
    "",
    ...(missingReachableTypes.length === 0 ? ["- none"] : missingReachableTypes),
    "",
    "## Missing Exported Types",
    "",
    ...(missingExportedTypes.length === 0 ? ["- none"] : missingExportedTypes),
    "",
    "## Non-Reachable Exported Types",
    "",
    renderTable(["Schema Type", "Swift Type", "Status", "Schema File"], nonReachableRows),
    "",
  ];

  fs.mkdirSync(path.dirname(trackerPath), { recursive: true });
  fs.writeFileSync(trackerPath, `${lines.join("\n")}\n`);
  console.log(`Wrote ${path.relative(repoRoot, trackerPath)}`);
  console.log(`Reachable types: ${reachableRows.length}`);
  console.log(`Missing reachable types: ${missingReachableTypes.length}`);

  if (verifyOnly) {
    const failures = [];
    if (missingExportedTypes.length > 0) failures.push(`missing exported types: ${missingExportedTypes.length}`);
    if (missingReachableTypes.length > 0) failures.push(`missing reachable types: ${missingReachableTypes.length}`);
    if (incompleteRequests > 0) failures.push(`incomplete client requests: ${incompleteRequests}`);
    if (incompleteNotifications > 0) failures.push(`incomplete server notifications: ${incompleteNotifications}`);
    if (incompleteServerRequests > 0) failures.push(`incomplete server requests: ${incompleteServerRequests}`);

    if (failures.length > 0) {
      console.error(`Connection schema verification failed: ${failures.join(", ")}`);
      process.exit(1);
    }

    console.log("Connection schema verification passed.");
  }
}

main();
