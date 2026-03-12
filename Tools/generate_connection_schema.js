#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const schemaRoot = path.join(repoRoot, "codex-schemas", "v0.114.0");
const outputDir = path.join(repoRoot, "Codax", "Controllers", "Connection");
const outputFile = path.join(outputDir, "CodexSchema.generated.swift");

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
  "plugin/list": "PluginListResponse",
  "skills/remote/list": "SkillsRemoteReadResponse",
  "skills/remote/export": "SkillsRemoteWriteResponse",
  "app/list": "AppsListResponse",
  "skills/config/write": "SkillsConfigWriteResponse",
  "plugin/install": "PluginInstallResponse",
  "plugin/uninstall": "PluginUninstallResponse",
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
  "command/exec/write": "CommandExecWriteResponse",
  "command/exec/terminate": "CommandExecTerminateResponse",
  "command/exec/resize": "CommandExecResizeResponse",
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
  "PermissionsRequestApprovalResponse",
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
      if (escaped) {
        escaped = false;
      } else if (char === "\\") {
        escaped = true;
      } else if (char === "\"") {
        inString = false;
      }
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
    this.tokenize();
    this.position = 0;
  }

  tokenize() {
    while (this.index < this.input.length) {
      const char = this.input[this.index];
      if (/\s/.test(char)) {
        this.index += 1;
        continue;
      }
      if (char === "\"" ) {
        this.tokens.push({ type: "string", value: this.readString() });
        continue;
      }
      if (/[A-Za-z_$]/.test(char)) {
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
      if (char === "\"") {
        break;
      }
      result += char;
    }
    return result;
  }

  readIdentifier() {
    const start = this.index;
    this.index += 1;
    while (this.index < this.input.length && /[A-Za-z0-9_$]/.test(this.input[this.index])) {
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
  if (token.type === "{") {
    return parseObject(tokenizer);
  }
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
  if (token.type === "string") {
    return { kind: "stringLiteral", value: tokenizer.next().value };
  }
  if (token.type === "number") {
    return { kind: "numberLiteral", value: Number(tokenizer.next().value) };
  }
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

function loadSchemaFiles() {
  const files = [];
  walk(schemaRoot, files);
  const map = new Map();
  for (const file of files) {
    if (!file.endsWith(".ts")) continue;
    const source = stripComments(fs.readFileSync(file, "utf8"));
    const match = source.match(/export type\s+([A-Za-z0-9_]+)\s*=/);
    if (!match) continue;
    const typeName = match[1];
    const expression = findTypeExpression(source, typeName);
    if (!expression) continue;
    const relative = path.relative(schemaRoot, file).replace(/\\/g, "/");
    map.set(typeName, {
      typeName,
      file,
      relative,
      expression,
      ast: parseTypeExpression(expression),
    });
  }
  return map;
}

function walk(root, files) {
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    const fullPath = path.join(root, entry.name);
    if (entry.isDirectory()) {
      walk(fullPath, files);
    } else {
      files.push(fullPath);
    }
  }
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
  return [...included].map((name) => definitions.get(name));
}

function swiftIdentifier(name) {
  const parts = name
    .replace(/[^A-Za-z0-9_]+/g, "_")
    .replace(/^[0-9]/, "_$&")
    .split("_")
    .filter(Boolean);
  if (parts.length === 0) return "_value";
  const value = parts
    .map((part, index) => {
      if (index === 0) return part[0].toLowerCase() + part.slice(1);
      return part[0].toUpperCase() + part.slice(1);
    })
    .join("");
  return RESERVED.has(value) ? `\`${value}\`` : value;
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

function swiftType(node, context = {}) {
  const nullable = splitNullable(node);
  if (nullable.isOptional) {
    return `${swiftType(nullable.base, context)}?`;
  }
  switch (nullable.base.kind) {
    case "primitive":
      return primitiveSwiftType(nullable.base.name, context);
    case "reference":
      return renameType(nullable.base.name);
    case "array":
      return `[${swiftType(nullable.base.element, context)}]`;
    case "record":
      return `[${swiftType(nullable.base.key, context)}: ${swiftType(nullable.base.value, context)}]`;
    case "object":
      if (nullable.base.fields.length === 0 && nullable.base.indexSignature) {
        return `[String: ${swiftType(nullable.base.indexSignature, context)}]`;
      }
      return context.inlineName || "JSONValueObject";
    case "stringLiteral":
      return "String";
    case "union":
      return context.inlineName || "JSONValue";
    case "intersection":
      return context.inlineName || "JSONValue";
    default:
      throw new Error(`Unsupported Swift type for ${nullable.base.kind}`);
  }
}

function primitiveSwiftType(name, context) {
  switch (name) {
    case "string":
      return "String";
    case "number":
      return "Int";
    case "boolean":
      return "Bool";
    case "bigint":
      return "Int64";
    case "null":
    case "undefined":
      return "Never";
    case "never":
      return "Never";
    default:
      throw new Error(`Unsupported primitive ${name}`);
  }
}

function splitNullable(node) {
  if (node.kind !== "union") {
    return { base: node, isOptional: false };
  }
  const nonNull = node.members.filter(
    (member) =>
      !(member.kind === "primitive" && (member.name === "null" || member.name === "undefined"))
  );
  const removed = nonNull.length !== node.members.length;
  if (!removed) return { base: node, isOptional: false };
  if (nonNull.length === 1) return { base: nonNull[0], isOptional: true };
  return { base: { kind: "union", members: nonNull }, isOptional: true };
}

function fieldType(field) {
  const type = swiftType(field.value);
  if (field.optional && !type.endsWith("?")) return `${type}?`;
  return type;
}

function renameType(name) {
  if (name === "JsonValue") return "JSONValue";
  if (name === "Model") return "AppModel";
  return name;
}

function isStringLiteralUnion(node) {
  const base = splitNullable(node).base;
  return base.kind === "union" && base.members.every((member) => member.kind === "stringLiteral");
}

function isWrappedUnion(node) {
  const base = splitNullable(node).base;
  if (base.kind !== "union") return false;
  return base.members.every((member) => {
    if (member.kind === "stringLiteral") return true;
    if (member.kind !== "object") return false;
    return member.fields.length >= 1;
  });
}

function isTaggedUnion(node, definitions) {
  return taggedUnionDiscriminator(splitNullable(node).base, definitions) !== null;
}

function taggedUnionDiscriminator(base, definitions) {
  if (base.kind !== "union") return null;
  const objectMembers = base.members.map((member) => flattenObjectNode(member, definitions));
  if (objectMembers.some((member) => member === null) || objectMembers.length === 0) return null;
  const candidateKeys = objectMembers[0].fields
    .filter((field) => field.value.kind === "stringLiteral")
    .map((field) => field.key);
  for (const key of candidateKeys) {
    if (objectMembers.every((member) => member.fields.some((field) => field.key === key && field.value.kind === "stringLiteral"))) {
      return key;
    }
  }
  return null;
}

function flattenObjectNode(node, definitions, seen = new Set()) {
  const base = splitNullable(node).base;
  if (base.kind === "primitive" && (base.name === "null" || base.name === "undefined")) {
    return {
      kind: "object",
      fields: [],
      indexSignature: null,
    };
  }
  if (base.kind === "object") {
    return {
      kind: "object",
      fields: [...base.fields],
      indexSignature: base.indexSignature,
    };
  }
  if (base.kind === "reference") {
    if (seen.has(base.name)) return null;
    const definition = definitions.get(base.name);
    if (!definition) return null;
    const nextSeen = new Set(seen);
    nextSeen.add(base.name);
    return flattenObjectNode(definition.ast, definitions, nextSeen);
  }
  if (base.kind === "intersection") {
    const merged = { kind: "object", fields: [], indexSignature: null };
    for (const member of base.members) {
      const flattened = flattenObjectNode(member, definitions, seen);
      if (!flattened) return null;
      merged.fields.push(...flattened.fields);
      if (flattened.indexSignature) merged.indexSignature = flattened.indexSignature;
    }
    return merged;
  }
  return null;
}

function isJsonValueUnion(node) {
  const base = splitNullable(node).base;
  if (base.kind !== "union") return false;
  const kinds = new Set(base.members.map((member) => member.kind === "primitive" ? member.name : member.kind));
  return (
    kinds.has("number") &&
    kinds.has("string") &&
    kinds.has("boolean") &&
    kinds.has("array") &&
    kinds.has("object")
  );
}

function emitDefinition(definition, definitions) {
  const name = renameType(definition.typeName);
  const node = definition.ast;
  if (["RequestId", "ClientRequest", "ServerNotification", "ServerRequest"].includes(name)) return "";
  if (name === "JsonValue" || isJsonValueUnion(node)) {
    return emitJSONValue(name);
  }
  if (isStringLiteralUnion(node)) return emitStringEnum(name, splitNullable(node).base.members);
  if (isTaggedUnion(node, definitions)) return emitTaggedUnion(name, splitNullable(node).base.members, definitions);
  if (isWrappedUnion(node)) return emitWrappedUnion(name, splitNullable(node).base.members);
  if (splitNullable(node).base.kind === "union") return emitGeneralUnion(name, splitNullable(node).base.members);
  const nullable = splitNullable(node);
  const distributedUnion = nullable.base.kind === "intersection"
    ? distributeIntersectionUnion(nullable.base)
    : null;
  if (distributedUnion) {
    if (isTaggedUnion(distributedUnion, definitions)) return emitTaggedUnion(name, distributedUnion.members, definitions);
    if (isWrappedUnion(distributedUnion)) return emitWrappedUnion(name, distributedUnion.members);
    return emitGeneralUnion(name, distributedUnion.members);
  }
  if (nullable.base.kind === "stringLiteral") return emitStringEnum(name, [nullable.base]);
  if (nullable.base.kind === "object") return emitStruct(name, nullable.base);
  if (nullable.base.kind === "record") {
    if (nullable.base.value.kind === "primitive" && nullable.base.value.name === "never") {
      return `public struct ${name}: Sendable, Codable, Equatable, Hashable {\n\tpublic init() {}\n}\n`;
    }
    return `public typealias ${name} = [${swiftType(nullable.base.key)}: ${swiftType(nullable.base.value)}]\n`;
  }
  if (nullable.base.kind === "array") {
    return `public typealias ${name} = [${swiftType(nullable.base.element)}]\n`;
  }
  if (nullable.base.kind === "primitive" && (nullable.base.name === "null" || nullable.base.name === "undefined")) {
    return emitNullStruct(name);
  }
  if (nullable.base.kind === "reference" || nullable.base.kind === "primitive") {
    return `public typealias ${name} = ${swiftType(node)}\n`;
  }
  if (nullable.base.kind === "intersection") return emitIntersectionStruct(name, nullable.base, definitions);
  throw new Error(`Unsupported top-level definition for ${name}: ${nullable.base.kind}`);
}

function distributeIntersectionUnion(intersectionNode) {
  const unionMembers = intersectionNode.members.filter((member) => splitNullable(member).base.kind === "union");
  if (unionMembers.length !== 1) return null;
  const unionBase = splitNullable(unionMembers[0]).base;
  const otherMembers = intersectionNode.members.filter((member) => member !== unionMembers[0]);
  return {
    kind: "union",
    members: unionBase.members.map((member) => ({
      kind: "intersection",
      members: [...otherMembers, member],
    })),
  };
}

function emitStringEnum(name, members) {
  const cases = members
    .map((member) => `\tcase ${swiftCaseName(member.value)} = "${member.value}"`)
    .join("\n");
  return `public enum ${name}: String, Sendable, Codable, Equatable, Hashable {\n${cases}\n}\n`;
}

function emitNullStruct(name) {
  return `public struct ${name}: Sendable, Codable, Equatable, Hashable {\n\tpublic init() {}\n\n\tpublic init(from decoder: any Decoder) throws {\n\t\tlet container = try decoder.singleValueContainer()\n\t\tguard container.decodeNil() else {\n\t\t\tthrow DecodingError.dataCorruptedError(in: container, debugDescription: "Expected null for ${name}.")\n\t\t}\n\t}\n\n\tpublic func encode(to encoder: any Encoder) throws {\n\t\tvar container = encoder.singleValueContainer()\n\t\ttry container.encodeNil()\n\t}\n}\n`;
}

function emitStruct(name, objectNode) {
  if (objectNode.fields.length === 0 && objectNode.indexSignature) {
    return `public typealias ${name} = [String: ${swiftType(objectNode.indexSignature)}]\n`;
  }
  if (objectNode.fields.length === 0) {
    return `public struct ${name}: Sendable, Codable, Equatable, Hashable {\n\tpublic init() {}\n}\n`;
  }
  const hasExtras = objectNode.indexSignature !== null;
  const codingKeys = objectNode.fields
    .map((field) => {
      const swiftName = swiftIdentifier(field.key);
      if (swiftName.replace(/`/g, "") === field.key) return `\t\tcase ${swiftName}`;
      return `\t\tcase ${swiftName} = "${field.key}"`;
    })
    .join("\n");
  const properties = objectNode.fields
    .map((field) => {
      const swiftName = swiftIdentifier(field.key);
      const type = fieldType(field);
      return `\tpublic var ${swiftName}: ${type}`;
    })
    .join("\n");
  const extras = hasExtras
    ? `
\tpublic var additionalProperties: [String: JSONValue]? = nil
`
    : "";
  const extrasDecl = hasExtras
    ? `
\tprivate enum AdditionalPropertiesCodingKeys: String, CodingKey {
\t\tcase additionalProperties
\t}
`
    : "";
  const codingKeysDecl = objectNode.fields.length > 0
    ? `\tprivate enum CodingKeys: String, CodingKey {\n${codingKeys}\n\t}\n`
    : "";
  const bodyParts = [properties];
  if (extras) bodyParts.push(extras.trimEnd());
  if (codingKeysDecl) bodyParts.push(codingKeysDecl.trimEnd());
  if (extrasDecl) bodyParts.push(extrasDecl.trimEnd());
  return `public struct ${name}: Sendable, Codable, Equatable, Hashable {\n${bodyParts.join("\n\n")}\n}\n`;
}

function emitIntersectionStruct(name, intersectionNode, definitions) {
  const merged = flattenObjectNode(intersectionNode, definitions);
  if (!merged) {
    throw new Error(`Unsupported intersection members in ${name}`);
  }
  return emitStruct(name, merged);
}

function dynamicCodingKeysDecl() {
  return `\tprivate struct CodingKeys: CodingKey {\n\t\tvar stringValue: String\n\t\tvar intValue: Int?\n\n\t\tinit?(stringValue: String) {\n\t\t\tself.stringValue = stringValue\n\t\t\tself.intValue = nil\n\t\t}\n\n\t\tinit?(intValue: Int) {\n\t\t\tself.stringValue = String(intValue)\n\t\t\tself.intValue = intValue\n\t\t}\n\t}\n`;
}

function codingKeyExpr(rawKey) {
  return `CodingKeys(stringValue: ${JSON.stringify(rawKey)})!`;
}

function emitTaggedUnion(name, members, definitions) {
  const discriminatorKey = taggedUnionDiscriminator({ kind: "union", members }, definitions);
  if (!discriminatorKey) {
    throw new Error(`Missing tagged union discriminator in ${name}`);
  }
  const discriminatorSwiftName = swiftIdentifier(discriminatorKey).replace(/`/g, "");
  const caseDecls = [];
  const decodeCases = [];
  const encodeCases = [];
  for (const member of members) {
    const flattenedMember = flattenObjectNode(member, definitions);
    if (!flattenedMember) {
      throw new Error(`Unsupported tagged union member in ${name}`);
    }
    const typeField = flattenedMember.fields.find((field) => field.key === discriminatorKey);
    const caseName = swiftCaseName(typeField.value.value);
    const payloadFields = flattenedMember.fields.filter((field) => field !== typeField);
    if (payloadFields.length === 0) {
      caseDecls.push(`\tcase ${caseName}`);
      decodeCases.push(`\t\tcase "${typeField.value.value}": self = .${caseName}`);
      encodeCases.push(`\t\tcase .${caseName}: try container.encode("${typeField.value.value}", forKey: ${codingKeyExpr(discriminatorKey)})`);
      continue;
    }
    const assoc = payloadFields
      .map((field) => `${swiftIdentifier(field.key)}: ${field.optional ? `${swiftType(field.value)}?`.replace("??", "?") : swiftType(field.value)}`)
      .join(", ");
    caseDecls.push(`\tcase ${caseName}(${assoc})`);
    const decodeBindings = payloadFields
      .map((field) => {
        const labelName = swiftIdentifier(field.key).replace(/`/g, "");
        const fn = field.optional ? "decodeIfPresent" : "decode";
        const baseType = swiftType(field.value).replace(/\?$/, "");
        return `${labelName}: try container.${fn}(${baseType}.self, forKey: ${codingKeyExpr(field.key)})`;
      })
      .join(", ");
    decodeCases.push(`\t\tcase "${typeField.value.value}": self = .${caseName}(${decodeBindings})`);
    const pattern = payloadFields
      .map((field) => `${swiftIdentifier(field.key).replace(/`/g, "")}`)
      .join(", ");
    const encodePayload = payloadFields
      .map((field) => {
        const swiftName = swiftIdentifier(field.key).replace(/`/g, "");
        const fn = field.optional ? "encodeIfPresent" : "encode";
        return `\t\t\ttry container.${fn}(${swiftName}, forKey: ${codingKeyExpr(field.key)})`;
      })
      .join("\n");
    encodeCases.push(`\t\tcase let .${caseName}(${pattern}):\n\t\t\ttry container.encode("${typeField.value.value}", forKey: ${codingKeyExpr(discriminatorKey)})\n${encodePayload}`);
  }
  return `public enum ${name}: Sendable, Codable, Equatable, Hashable {\n${caseDecls.join("\n")}\n\n${dynamicCodingKeysDecl().trimEnd()}\n\n\tpublic init(from decoder: any Decoder) throws {\n\t\tlet container = try decoder.container(keyedBy: CodingKeys.self)\n\t\tswitch try container.decode(String.self, forKey: ${codingKeyExpr(discriminatorKey)}) {\n${decodeCases.join("\n")}\n\t\tdefault: throw DecodingError.dataCorruptedError(forKey: ${codingKeyExpr(discriminatorKey)}, in: container, debugDescription: "Unsupported ${name} discriminator.")\n\t\t}\n\t}\n\n\tpublic func encode(to encoder: any Encoder) throws {\n\t\tvar container = encoder.container(keyedBy: CodingKeys.self)\n\t\tswitch self {\n${encodeCases.join("\n")}\n\t\t}\n\t}\n}\n`;
}

function emitWrappedUnion(name, members) {
  const caseDecls = [];
  const decodeCases = [];
  const encodeCases = [];
  for (const member of members) {
    if (member.kind === "stringLiteral") {
      const caseName = swiftCaseName(member.value);
      caseDecls.push(`\tcase ${caseName}`);
      decodeCases.push(`\t\tif let value = try? single.decode(String.self), value == "${member.value}" { self = .${caseName}; return }`);
      encodeCases.push(`\t\tcase .${caseName}: try single.encode("${member.value}")`);
      continue;
    }
    if (member.kind !== "object" || member.fields.length !== 1) {
      throw new Error(`Unsupported wrapped union member in ${name}`);
    }
    const field = member.fields[0];
    const caseName = swiftCaseName(field.key);
    caseDecls.push(`\tcase ${caseName}(${swiftType(field.value)})`);
    decodeCases.push(`\t\tif container.contains(${codingKeyExpr(field.key)}) { self = .${caseName}(try container.decode(${swiftType(field.value).replace(/\?$/, "")}.self, forKey: ${codingKeyExpr(field.key)})); return }`);
    encodeCases.push(`\t\tcase let .${caseName}(value):\n\t\t\ttry keyed.encode(value, forKey: ${codingKeyExpr(field.key)})`);
  }
  const stringDecodeCases = decodeCases.filter((line) => line.includes("single"));
  const containerDecodeCases = decodeCases.filter((line) => line.includes("container"));
  const stringEncodeCases = encodeCases.filter((line) => line.includes("single.encode"));
  const keyedEncodeCases = encodeCases.filter((line) => line.includes("keyed.encode"));
  return `public enum ${name}: Sendable, Codable, Equatable, Hashable {\n${caseDecls.join("\n")}\n\n${dynamicCodingKeysDecl().trimEnd()}\n\n\tpublic init(from decoder: any Decoder) throws {\n${stringDecodeCases.length > 0 ? "\t\tlet single = try decoder.singleValueContainer()\n" : ""}${stringDecodeCases.join("\n")}\n${containerDecodeCases.length > 0 ? "\t\tlet container = try decoder.container(keyedBy: CodingKeys.self)\n" : ""}${containerDecodeCases.join("\n")}\n\t\tthrow DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unsupported ${name} payload."))\n\t}\n\n\tpublic func encode(to encoder: any Encoder) throws {\n\t\tswitch self {\n${stringEncodeCases
    .map((line) => line.replace(": try single.encode", ":\n\t\t\tvar single = encoder.singleValueContainer()\n\t\t\ttry single.encode"))
    .join("\n")}\n${keyedEncodeCases
    .map((line) => line.replace("\n\t\t\ttry keyed.encode", "\n\t\t\tvar keyed = encoder.container(keyedBy: CodingKeys.self)\n\t\t\ttry keyed.encode"))
    .join("\n")}\n\t\t}\n\t}\n}\n`;
}

function emitJSONValue(name) {
  return `public indirect enum ${name}: Sendable, Codable, Equatable, Hashable {\n\tcase null\n\tcase bool(Bool)\n\tcase number(Int)\n\tcase string(String)\n\tcase array([${name}])\n\tcase object([String: ${name}])\n\n\tpublic init(from decoder: any Decoder) throws {\n\t\tlet container = try decoder.singleValueContainer()\n\t\tif container.decodeNil() {\n\t\t\tself = .null\n\t\t} else if let value = try? container.decode(Bool.self) {\n\t\t\tself = .bool(value)\n\t\t} else if let value = try? container.decode(Int.self) {\n\t\t\tself = .number(value)\n\t\t} else if let value = try? container.decode(String.self) {\n\t\t\tself = .string(value)\n\t\t} else if let value = try? container.decode([${name}].self) {\n\t\t\tself = .array(value)\n\t\t} else if let value = try? container.decode([String: ${name}].self) {\n\t\t\tself = .object(value)\n\t\t} else {\n\t\t\tthrow DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value.")\n\t\t}\n\t}\n\n\tpublic func encode(to encoder: any Encoder) throws {\n\t\tvar container = encoder.singleValueContainer()\n\t\tswitch self {\n\t\tcase .null:\n\t\t\ttry container.encodeNil()\n\t\tcase let .bool(value):\n\t\t\ttry container.encode(value)\n\t\tcase let .number(value):\n\t\t\ttry container.encode(value)\n\t\tcase let .string(value):\n\t\t\ttry container.encode(value)\n\t\tcase let .array(value):\n\t\t\ttry container.encode(value)\n\t\tcase let .object(value):\n\t\t\ttry container.encode(value)\n\t\t}\n\t}\n}\n`;
}

function emitGeneralUnion(name, members) {
  const caseDecls = [];
  const decodeCases = [];
  const encodeCases = [];
  for (const member of members) {
    const { caseName, typeName } = generalUnionCase(member);
    caseDecls.push(typeName ? `\tcase ${caseName}(${typeName})` : `\tcase ${caseName}`);
    if (typeName) {
      decodeCases.push(`\t\tif let value = try? ${decodeExpression(member, "container")} { self = .${caseName}(value); return }`);
      encodeCases.push(`\t\tcase let .${caseName}(value): try ${encodeExpression(member, "container", "value")}`);
    } else {
      decodeCases.push(`\t\tif container.decodeNil() { self = .${caseName}; return }`);
      encodeCases.push(`\t\tcase .${caseName}: try container.encodeNil()`);
    }
  }
  return `public enum ${name}: Sendable, Codable, Equatable, Hashable {\n${caseDecls.join("\n")}\n\n\tpublic init(from decoder: any Decoder) throws {\n\t\tlet container = try decoder.singleValueContainer()\n${decodeCases.join("\n")}\n\t\tthrow DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported ${name} payload.")\n\t}\n\n\tpublic func encode(to encoder: any Encoder) throws {\n\t\tvar container = encoder.singleValueContainer()\n\t\tswitch self {\n${encodeCases.join("\n")}\n\t\t}\n\t}\n}\n`;
}

function generalUnionCase(member) {
  switch (member.kind) {
    case "primitive":
      if (member.name === "null" || member.name === "undefined") return { caseName: "null", typeName: null };
      return { caseName: swiftCaseName(member.name), typeName: primitiveSwiftType(member.name) };
    case "reference":
      return { caseName: swiftCaseName(member.name), typeName: renameType(member.name) };
    case "array":
      return { caseName: "array", typeName: swiftType(member) };
    case "object":
      return { caseName: "object", typeName: "[String: JSONValue]" };
    case "stringLiteral":
      return { caseName: swiftCaseName(member.value), typeName: "String" };
    default:
      throw new Error(`Unsupported general union member kind ${member.kind}`);
  }
}

function decodeExpression(member, containerName) {
  switch (member.kind) {
    case "primitive":
      return `${containerName}.decode(${primitiveSwiftType(member.name)}.self)`;
    case "reference":
      return `${containerName}.decode(${renameType(member.name)}.self)`;
    case "array":
      return `${containerName}.decode(${swiftType(member)}.self)`;
    case "object":
      return `${containerName}.decode([String: JSONValue].self)`;
    case "stringLiteral":
      return `${containerName}.decode(String.self)`;
    default:
      throw new Error(`Unsupported decode member ${member.kind}`);
  }
}

function encodeExpression(member, containerName, valueName) {
  switch (member.kind) {
    case "primitive":
    case "reference":
    case "array":
    case "object":
    case "stringLiteral":
      return `${containerName}.encode(${valueName})`;
    default:
      throw new Error(`Unsupported encode member ${member.kind}`);
  }
}

function emitSupport() {
  return `public struct DynamicCodingKey: CodingKey, Hashable, Sendable {\n\tpublic let stringValue: String\n\tpublic let intValue: Int?\n\n\tpublic init?(stringValue: String) {\n\t\tself.stringValue = stringValue\n\t\tself.intValue = nil\n\t}\n\n\tpublic init?(intValue: Int) {\n\t\tself.stringValue = String(intValue)\n\t\tself.intValue = intValue\n\t}\n}\n`;
}

function emitRequestResponseMap() {
  const lines = Object.entries(CLIENT_REQUEST_RESPONSES)
    .map(([method, response]) => `\tcase "${method}": return ${renameType(response)}.self`)
    .join("\n");
  return `internal enum CodexConnectionResponseTypeRegistry {\n\tstatic func responseType(for method: String) -> (any Decodable.Type)? {\n\t\tswitch method {\n${lines}\n\t\tdefault: return nil\n\t\t}\n\t}\n}\n`;
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

function clientRequestCases(definitions) {
  return splitNullable(definitions.get("ClientRequest").ast).base.members.map((member) => {
    const methodField = member.fields.find((field) => field.key === "method");
    const paramsField = member.fields.find((field) => field.key === "params");
    const method = methodField.value.value;
    return {
      method,
      paramsType:
        !paramsField ||
        (paramsField.value.kind === "primitive" && paramsField.value.name === "undefined")
          ? null
          : swiftType(paramsField.value),
      responseType: renameType(CLIENT_REQUEST_RESPONSES[method]),
    };
  });
}

function serverNotificationCases(definitions) {
  return splitNullable(definitions.get("ServerNotification").ast).base.members.map((member) => {
    const method = member.fields.find((field) => field.key === "method").value.value;
    const paramsType = swiftType(member.fields.find((field) => field.key === "params").value);
    return { method, paramsType, caseName: methodCaseName(method) };
  });
}

function serverRequestCases(definitions) {
  const responseTypes = {
    "item/commandExecution/requestApproval": "CommandExecutionRequestApprovalResponse",
    "item/fileChange/requestApproval": "FileChangeRequestApprovalResponse",
    "item/tool/requestUserInput": "ToolRequestUserInputResponse",
    "mcpServer/elicitation/request": "McpServerElicitationRequestResponse",
    "item/permissions/requestApproval": "PermissionsRequestApprovalResponse",
    "item/tool/call": "DynamicToolCallResponse",
    "account/chatgptAuthTokens/refresh": "ChatgptAuthTokensRefreshResponse",
    "applyPatchApproval": "ApplyPatchApprovalResponse",
    "execCommandApproval": "ExecCommandApprovalResponse",
  };
  return splitNullable(definitions.get("ServerRequest").ast).base.members.map((member) => {
    const method = member.fields.find((field) => field.key === "method").value.value;
    const paramsType = swiftType(member.fields.find((field) => field.key === "params").value);
    return {
      method,
      paramsType,
      caseName: methodCaseName(method),
      responseType: responseTypes[method],
    };
  });
}

function emitConnectionAPI(definitions) {
  const methods = clientRequestCases(definitions)
    .map(({ method, paramsType, responseType }) => {
      const name = methodFunctionName(method);
      if (paramsType) {
        return `\tfunc ${name}(_ params: ${paramsType}) async throws -> ${responseType} {\n\t\ttry await _request(method: "${method}", params: params, as: ${responseType}.self)\n\t}`;
      }
      return `\tfunc ${name}() async throws -> ${responseType} {\n\t\ttry await _request(method: "${method}", params: CodexEmptyParams(), as: ${responseType}.self)\n\t}`;
    })
    .join("\n\n");
  return `private struct CodexEmptyParams: Sendable, Encodable {}\n\npublic extension CodexConnection {\n${methods}\n\n\tfunc initialized() async throws {\n\t\ttry await _notify(method: "initialized")\n\t}\n}\n`;
}

function emitRuntimeAPI(definitions) {
  const methods = clientRequestCases(definitions)
    .map(({ method, paramsType, responseType }) => {
      const name = methodFunctionName(method);
      if (paramsType) {
        return `\tfunc ${name}(_ params: ${paramsType}) async throws -> ${responseType} {\n\t\ttry await requireConnection().${name}(params)\n\t}`;
      }
      return `\tfunc ${name}() async throws -> ${responseType} {\n\t\ttry await requireConnection().${name}()\n\t}`;
    })
    .join("\n\n");
  return `public extension CodexRuntimeCoordinator {\n${methods}\n\n\tfunc initialized() async throws {\n\t\ttry await requireConnection().initialized()\n\t}\n}\n`;
}

function emitServerNotificationEnvelope(definitions) {
  const cases = serverNotificationCases(definitions);
  const caseDecls = cases.map(({ caseName, paramsType }) => `\tcase ${caseName}(${paramsType})`).join("\n");
  const decodeCases = cases
    .map(
      ({ method, caseName, paramsType }) =>
        `\t\tcase "${method}": return .${caseName}(try decoder.decode(${paramsType}.self, from: params))`
    )
    .join("\n");
  return `public enum ServerNotificationEnvelope: Sendable {\n${caseDecls}\n}\n\nextension ServerNotificationEnvelope {\n\tstatic func decode(method: String, params: Data, decoder: JSONDecoder) throws -> ServerNotificationEnvelope {\n\t\tswitch method {\n${decodeCases}\n\t\tdefault: throw CodexConnectionError.invalidMessage\n\t\t}\n\t}\n}\n`;
}

function emitServerRequestSupport(definitions) {
  const cases = serverRequestCases(definitions);
  const envelopeCases = cases
    .map(({ caseName, paramsType }) => `\tcase ${caseName}(${paramsType}, id: JSONRPCID)`)
    .join("\n");
  const decodeCases = cases
    .map(
      ({ method, caseName, paramsType }) =>
        `\t\tcase "${method}": return .${caseName}(try decoder.decode(${paramsType}.self, from: params), id: id)`
    )
    .join("\n");
  const idCases = cases.map(({ caseName }) => `\t\tcase let .${caseName}(_, id): return id`).join("\n");
  const responseCases = cases
    .map(({ caseName, responseType }) => `\tcase ${caseName}(${responseType})`)
    .join("\n");
  return `public protocol CodexServerRequestResponder: Sendable {\n\tfunc handle(_ request: ServerRequestEnvelope) async -> ServerRequestResponse\n}\n\npublic enum ServerRequestEnvelope: Sendable {\n${envelopeCases}\n}\n\nextension ServerRequestEnvelope {\n\tstatic func decode(method: String, id: JSONRPCID, params: Data, decoder: JSONDecoder) throws -> ServerRequestEnvelope {\n\t\tswitch method {\n${decodeCases}\n\t\tdefault: throw CodexConnectionError.invalidMessage\n\t\t}\n\t}\n\n\tvar id: JSONRPCID {\n\t\tswitch self {\n${idCases}\n\t\t}\n\t}\n}\n\npublic enum ServerRequestResponse: Sendable {\n${responseCases}\n\tcase unhandled\n}\n`;
}

function main() {
  const definitions = loadSchemaFiles();
  const allDefinitions = [...definitions.values()];
  const duplicates = findDuplicates(allDefinitions.map((definition) => renameType(definition.typeName)));
  if (duplicates.length > 0) {
    throw new Error(`Duplicate generated type names: ${duplicates.join(", ")}`);
  }
  const sorted = allDefinitions.sort((lhs, rhs) => lhs.relative.localeCompare(rhs.relative));
  const emittedDefinitions = [];
  for (const definition of sorted) {
    try {
      const emitted = emitDefinition(definition, definitions);
      if (emitted) emittedDefinitions.push(emitted);
    } catch (error) {
      throw new Error(`Failed generating ${definition.typeName} from ${definition.relative}: ${error.message}`);
    }
  }
  const body = [
    "// GENERATED FILE. DO NOT EDIT.",
    "",
    "import Foundation",
    "",
    emitSupport(),
    ...emittedDefinitions,
    emitServerNotificationEnvelope(definitions),
    emitServerRequestSupport(definitions),
    emitConnectionAPI(definitions),
    emitRuntimeAPI(definitions),
    emitRequestResponseMap(),
  ].join("\n");
  fs.mkdirSync(outputDir, { recursive: true });
  fs.writeFileSync(outputFile, body);
  console.log(`Wrote ${path.relative(repoRoot, outputFile)}`);
}

function findDuplicates(values) {
  const counts = new Map();
  for (const value of values) counts.set(value, (counts.get(value) ?? 0) + 1);
  return [...counts.entries()].filter(([, count]) => count > 1).map(([value]) => value);
}

main();
