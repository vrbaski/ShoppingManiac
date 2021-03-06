//
//  CloudKitOperations.swift
//  ShoppingManiac
//
//  Created by Dmitry Matyushkin on 1/23/20.
//  Copyright © 2020 Dmitry Matyushkin. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitOperations: CloudKitOperationsProtocol {
	
	func run(operation: CKDatabaseOperation, localDb: Bool) {
		CKContainer.default().database(localDb: localDb).add(operation)
	}
}
