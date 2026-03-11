//
//  CodexClient+SandboxTypes.swift
//  Codax
//
//  Created by Codex on 3/10/26.
//

import Foundation

public enum SandboxMode: String, Sendable, Codable, Equatable, Hashable {
	case readOnly = "read-only"
	case workspaceWrite = "workspace-write"
	case dangerFullAccess = "danger-full-access"
}

public enum NetworkAccess: String, Sendable, Codable, Equatable, Hashable {
	case restricted
	case enabled
}

public enum NetworkPolicyRuleAction: String, Sendable, Codable, Equatable, Hashable {
	case allow
	case deny
}

public enum MacOsPreferencesPermission: String, Sendable, Codable, Equatable, Hashable {
	case none
	case readOnly = "read_only"
	case readWrite = "read_write"
}

public enum MacOsAutomationPermission: Sendable, Codable, Equatable, Hashable {
	case none
	case all
	case bundleIDs([String])

	private enum CodingKeys: String, CodingKey {
		case bundleIDs = "bundle_ids"
	}

	public init(from decoder: any Decoder) throws {
		self = try CodexCoding.decodeStringOrObject(
			from: decoder,
			typeName: "MacOsAutomationPermission",
			stringMapping: [
				"none": .none,
				"all": .all,
			]
		) { (container: KeyedDecodingContainer<CodingKeys>) in
			.bundleIDs(try container.decode([String].self, forKey: .bundleIDs))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .none:
			try CodexCoding.encodeStringValue("none", to: encoder)
		case .all:
			try CodexCoding.encodeStringValue("all", to: encoder)
		case let .bundleIDs(bundleIDs):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(bundleIDs, forKey: .bundleIDs)
		}
	}
}

public struct AdditionalFileSystemPermissions: Sendable, Codable, Equatable, Hashable {
	public var read: [String]?
	public var write: [String]?
}

public struct AdditionalNetworkPermissions: Sendable, Codable, Equatable, Hashable {
	public var enabled: Bool?
}

public struct AdditionalMacOsPermissions: Sendable, Codable, Equatable, Hashable {
	public var preferences: MacOsPreferencesPermission
	public var automations: MacOsAutomationPermission
	public var accessibility: Bool
	public var calendar: Bool
}

public struct AdditionalPermissionProfile: Sendable, Codable, Equatable, Hashable {
	public var network: AdditionalNetworkPermissions?
	public var fileSystem: AdditionalFileSystemPermissions?
	public var macos: AdditionalMacOsPermissions?

	private enum CodingKeys: String, CodingKey {
		case network
		case fileSystem
		case macos
	}
}

public struct ExecPolicyAmendment: Sendable, Codable, Equatable, Hashable {
	public var commands: [String]

	public init(_ commands: [String]) {
		self.commands = commands
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.commands = try container.decode([String].self)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(commands)
	}
}

public struct NetworkPolicyAmendment: Sendable, Codable, Equatable, Hashable {
	public var host: String
	public var action: NetworkPolicyRuleAction
}

public enum ReadOnlyAccess: Sendable, Codable, Equatable, Hashable {
	case restricted(includePlatformDefaults: Bool, readableRoots: [String])
	case fullAccess

	private enum CodingKeys: String, CodingKey {
		case type
		case includePlatformDefaults
		case readableRoots
	}

	private enum Kind: String, Codable {
		case restricted
		case fullAccess
	}

	public init(from decoder: any Decoder) throws {
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "ReadOnlyAccess"
		)
		switch kind {
		case .restricted:
			self = .restricted(
				includePlatformDefaults: try container.decode(Bool.self, forKey: .includePlatformDefaults),
				readableRoots: try container.decode([String].self, forKey: .readableRoots)
			)
		case .fullAccess:
			self = .fullAccess
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .restricted(includePlatformDefaults, readableRoots):
			try container.encode(Kind.restricted, forKey: .type)
			try container.encode(includePlatformDefaults, forKey: .includePlatformDefaults)
			try container.encode(readableRoots, forKey: .readableRoots)
		case .fullAccess:
			try container.encode(Kind.fullAccess, forKey: .type)
		}
	}
}

public enum SandboxPolicy: Sendable, Codable, Equatable, Hashable {
	case dangerFullAccess
	case readOnly(access: ReadOnlyAccess, networkAccess: Bool)
	case externalSandbox(networkAccess: NetworkAccess)
	case workspaceWrite(
		writableRoots: [String],
		readOnlyAccess: ReadOnlyAccess,
		networkAccess: Bool,
		excludeTmpdirEnvVar: Bool,
		excludeSlashTmp: Bool
	)

	private enum CodingKeys: String, CodingKey {
		case type
		case access
		case networkAccess
		case writableRoots
		case readOnlyAccess
		case excludeTmpdirEnvVar
		case excludeSlashTmp
	}

	private enum Kind: String, Codable {
		case dangerFullAccess
		case readOnly
		case externalSandbox
		case workspaceWrite
	}

	public init(from decoder: any Decoder) throws {
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "SandboxPolicy"
		)
		switch kind {
		case .dangerFullAccess:
			self = .dangerFullAccess
		case .readOnly:
			self = .readOnly(
				access: try container.decode(ReadOnlyAccess.self, forKey: .access),
				networkAccess: try container.decode(Bool.self, forKey: .networkAccess)
			)
		case .externalSandbox:
			self = .externalSandbox(networkAccess: try container.decode(NetworkAccess.self, forKey: .networkAccess))
		case .workspaceWrite:
			self = .workspaceWrite(
				writableRoots: try container.decode([String].self, forKey: .writableRoots),
				readOnlyAccess: try container.decode(ReadOnlyAccess.self, forKey: .readOnlyAccess),
				networkAccess: try container.decode(Bool.self, forKey: .networkAccess),
				excludeTmpdirEnvVar: try container.decode(Bool.self, forKey: .excludeTmpdirEnvVar),
				excludeSlashTmp: try container.decode(Bool.self, forKey: .excludeSlashTmp)
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .dangerFullAccess:
			try container.encode(Kind.dangerFullAccess, forKey: .type)
		case let .readOnly(access, networkAccess):
			try container.encode(Kind.readOnly, forKey: .type)
			try container.encode(access, forKey: .access)
			try container.encode(networkAccess, forKey: .networkAccess)
		case let .externalSandbox(networkAccess):
			try container.encode(Kind.externalSandbox, forKey: .type)
			try container.encode(networkAccess, forKey: .networkAccess)
		case let .workspaceWrite(writableRoots, readOnlyAccess, networkAccess, excludeTmpdirEnvVar, excludeSlashTmp):
			try container.encode(Kind.workspaceWrite, forKey: .type)
			try container.encode(writableRoots, forKey: .writableRoots)
			try container.encode(readOnlyAccess, forKey: .readOnlyAccess)
			try container.encode(networkAccess, forKey: .networkAccess)
			try container.encode(excludeTmpdirEnvVar, forKey: .excludeTmpdirEnvVar)
			try container.encode(excludeSlashTmp, forKey: .excludeSlashTmp)
		}
	}
}
