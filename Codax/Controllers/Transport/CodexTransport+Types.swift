//
//  CodexTransport+Types.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Transport Layer Types

public enum CodexTransportError: Error, LocalizedError, Sendable {
	case endOfStream
	case invalidFrame
	case receiveAlreadyPending
	case closed

	public var errorDescription: String? {
		switch self {
			case .endOfStream:
				return "The transport closed before another message was received."
			case .invalidFrame:
				return "The transport produced an invalid JSONL frame."
			case .receiveAlreadyPending:
				return "Only one receive operation may be pending at a time."
			case .closed:
				return "The transport is already closed."
		}
	}
}
