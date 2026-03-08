//
//  Connector.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

// MARK: - Connection Layer Types

public enum ConnectionState: Sendable {
	case disconnected
	case connecting
	case connected
}

public enum CodexConnectionError: Error, LocalizedError, Sendable {
	case disconnected
	case invalidMessage
	case unsupportedServerRequest(method: String)
	case serverError(JSONRPCErrorObject)

	public var errorDescription: String? {
		switch self {
		case .disconnected:
			return "The connection is disconnected."
		case .invalidMessage:
			return "Received an invalid app-server message."
		case let .unsupportedServerRequest(method):
			return "Unhandled server request: \(method)"
		case let .serverError(error):
			return error.message
		}
	}
}
