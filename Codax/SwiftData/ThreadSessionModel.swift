//
//  ThreadSessionModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import SwiftData

// MARK: - Thread Session Record

struct ThreadSessionRecord: Codable, Equatable, Sendable {
	var threadCodexId: String
	var model: String
	var modelProvider: String
	var serviceTier: ServiceTier?
	var cwd: String
	var approvalPolicy: AskForApproval
	var sandboxPolicy: SandboxPolicy
	var reasoningEffort: ReasoningEffort?

	init(
		threadCodexId: String,
		model: String,
		modelProvider: String,
		serviceTier: ServiceTier?,
		cwd: String,
		approvalPolicy: AskForApproval,
		sandboxPolicy: SandboxPolicy,
		reasoningEffort: ReasoningEffort?
	) {
		self.threadCodexId = threadCodexId
		self.model = model
		self.modelProvider = modelProvider
		self.serviceTier = serviceTier
		self.cwd = cwd
		self.approvalPolicy = approvalPolicy
		self.sandboxPolicy = sandboxPolicy
		self.reasoningEffort = reasoningEffort
	}

	init(response: ThreadStartResponse) {
		self.init(
			threadCodexId: response.thread.id,
			model: response.model,
			modelProvider: response.modelProvider,
			serviceTier: response.serviceTier,
			cwd: response.cwd,
			approvalPolicy: response.approvalPolicy,
			sandboxPolicy: response.sandbox,
			reasoningEffort: response.reasoningEffort
		)
	}

	init(model: ThreadSessionModel) {
		self.init(
			threadCodexId: model.threadCodexId,
			model: model.model,
			modelProvider: model.modelProvider,
			serviceTier: model.serviceTier,
			cwd: model.cwd,
			approvalPolicy: model.approvalPolicy,
			sandboxPolicy: model.sandboxPolicy,
			reasoningEffort: model.reasoningEffort
		)
	}
}

// MARK: - Thread Session Model

@Model
final class ThreadSessionModel {
	var id: UUID
	var threadCodexId: String
	var model: String
	var modelProvider: String
	var serviceTierData: Data?
	var cwd: String
	var approvalPolicyData: Data
	var sandboxPolicyData: Data
	var reasoningEffortData: Data?

	var thread: ThreadModel?

	init(
		id: UUID = UUID(),
		threadCodexId: String,
		model: String,
		modelProvider: String,
		serviceTierData: Data? = nil,
		cwd: String,
		approvalPolicyData: Data,
		sandboxPolicyData: Data,
		reasoningEffortData: Data? = nil,
		thread: ThreadModel? = nil
	) {
		self.id = id
		self.threadCodexId = threadCodexId
		self.model = model
		self.modelProvider = modelProvider
		self.serviceTierData = serviceTierData
		self.cwd = cwd
		self.approvalPolicyData = approvalPolicyData
		self.sandboxPolicyData = sandboxPolicyData
		self.reasoningEffortData = reasoningEffortData
		self.thread = thread
	}

	convenience init(record: ThreadSessionRecord, thread: ThreadModel? = nil) {
		self.init(
			threadCodexId: record.threadCodexId,
			model: record.model,
			modelProvider: record.modelProvider,
			serviceTierData: Self.encodeOptional(record.serviceTier),
			cwd: record.cwd,
			approvalPolicyData: Self.encode(record.approvalPolicy) ?? Data(),
			sandboxPolicyData: Self.encode(record.sandboxPolicy) ?? Data(),
			reasoningEffortData: Self.encodeOptional(record.reasoningEffort),
			thread: thread
		)
	}

	var record: ThreadSessionRecord {
		ThreadSessionRecord(model: self)
	}

	var serviceTier: ServiceTier? {
		Self.decode(ServiceTier.self, from: serviceTierData)
	}

	var approvalPolicy: AskForApproval {
		Self.decode(AskForApproval.self, from: approvalPolicyData) ?? .onRequest
	}

	var sandboxPolicy: SandboxPolicy {
		Self.decode(SandboxPolicy.self, from: sandboxPolicyData) ?? .dangerFullAccess
	}

	var reasoningEffort: ReasoningEffort? {
		Self.decode(ReasoningEffort.self, from: reasoningEffortData)
	}

	func apply(_ record: ThreadSessionRecord) {
		threadCodexId = record.threadCodexId
		model = record.model
		modelProvider = record.modelProvider
		serviceTierData = Self.encodeOptional(record.serviceTier)
		cwd = record.cwd
		approvalPolicyData = Self.encode(record.approvalPolicy) ?? Data()
		sandboxPolicyData = Self.encode(record.sandboxPolicy) ?? Data()
		reasoningEffortData = Self.encodeOptional(record.reasoningEffort)
	}

	private static func encode<T: Encodable>(_ value: T) -> Data? {
		try? JSONEncoder().encode(value)
	}

	private static func encodeOptional<T: Encodable>(_ value: T?) -> Data? {
		guard let value else { return nil }
		return encode(value)
	}

	private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
		guard let data, !data.isEmpty else { return nil }
		return try? JSONDecoder().decode(T.self, from: data)
	}
}
