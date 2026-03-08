//
//  AuthCoordinator.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

@MainActor
public protocol AuthCoordinator: AnyObject {
	func openAuthURL(_ url: URL) async throws
}
