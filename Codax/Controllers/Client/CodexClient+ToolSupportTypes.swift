//
//  CodexClient+ToolSupportTypes.swift
//  Codax
//
//  Created by Codex on 3/10/26.
//

import Foundation

public struct ByteRange: Sendable, Codable, Equatable, Hashable {
	public var start: Int
	public var end: Int
}

public struct TextElement: Sendable, Codable, Equatable, Hashable {
	public var byteRange: ByteRange
	public var placeholder: String?
}

public enum UserInput: Sendable, Codable, Equatable, Hashable {
	case text(text: String, textElements: [TextElement])
	case image(url: String)
	case localImage(path: String)
	case skill(name: String, path: String)
	case mention(name: String, path: String)

	private enum CodingKeys: String, CodingKey {
		case type
		case text
		case textElements = "text_elements"
		case url
		case path
		case name
	}

	private enum Kind: String, Codable {
		case text
		case image
		case localImage
		case skill
		case mention
	}

	public init(from decoder: any Decoder) throws {
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "UserInput"
		)
		switch kind {
		case .text:
			self = .text(
				text: try container.decode(String.self, forKey: .text),
				textElements: try container.decode([TextElement].self, forKey: .textElements)
			)
		case .image:
			self = .image(url: try container.decode(String.self, forKey: .url))
		case .localImage:
			self = .localImage(path: try container.decode(String.self, forKey: .path))
		case .skill:
			self = .skill(
				name: try container.decode(String.self, forKey: .name),
				path: try container.decode(String.self, forKey: .path)
			)
		case .mention:
			self = .mention(
				name: try container.decode(String.self, forKey: .name),
				path: try container.decode(String.self, forKey: .path)
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .text(text, textElements):
			try container.encode(Kind.text, forKey: .type)
			try container.encode(text, forKey: .text)
			try container.encode(textElements, forKey: .textElements)
		case let .image(url):
			try container.encode(Kind.image, forKey: .type)
			try container.encode(url, forKey: .url)
		case let .localImage(path):
			try container.encode(Kind.localImage, forKey: .type)
			try container.encode(path, forKey: .path)
		case let .skill(name, path):
			try container.encode(Kind.skill, forKey: .type)
			try container.encode(name, forKey: .name)
			try container.encode(path, forKey: .path)
		case let .mention(name, path):
			try container.encode(Kind.mention, forKey: .type)
			try container.encode(name, forKey: .name)
			try container.encode(path, forKey: .path)
		}
	}
}

public enum DynamicToolCallOutputContentItem: Sendable, Codable, Equatable, Hashable {
	case inputText(text: String)
	case inputImage(imageUrl: String)

	private enum CodingKeys: String, CodingKey {
		case type
		case text
		case imageUrl
	}

	private enum Kind: String, Codable {
		case inputText
		case inputImage
	}

	public init(from decoder: any Decoder) throws {
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "DynamicToolCallOutputContentItem"
		)
		switch kind {
		case .inputText:
			self = .inputText(text: try container.decode(String.self, forKey: .text))
		case .inputImage:
			self = .inputImage(imageUrl: try container.decode(String.self, forKey: .imageUrl))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .inputText(text):
			try container.encode(Kind.inputText, forKey: .type)
			try container.encode(text, forKey: .text)
		case let .inputImage(imageUrl):
			try container.encode(Kind.inputImage, forKey: .type)
			try container.encode(imageUrl, forKey: .imageUrl)
		}
	}
}

public struct ToolRequestUserInputOption: Sendable, Codable, Equatable, Hashable {
	public var label: String
	public var description: String
}
