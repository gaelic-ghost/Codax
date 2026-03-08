//
//  CodexTransport.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

	// MARK: - Transport Protocol
	// Concrete implementation located in: `CodexTransport+Stdio.swift`

public protocol CodexTransport: Sendable {
	func send(_ message: Data) async throws
	func receive() async throws -> Data
	func close() async
}
