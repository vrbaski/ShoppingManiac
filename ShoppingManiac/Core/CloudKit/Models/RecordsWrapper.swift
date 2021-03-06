//
//  RecordsWrapper.swift
//  ShoppingManiac
//
//  Created by Dmitry Matyushkin on 22/04/2018.
//  Copyright © 2018 Dmitry Matyushkin. All rights reserved.
//

import Foundation
import CloudKit

class RecordsWrapper {
    
    let localDb: Bool
    let records: [CKRecord]
    let ownerName: String?
    
    init(localDb: Bool, records: [CKRecord], ownerName: String?) {
        self.localDb = localDb
        self.records = records
        self.ownerName = ownerName
    }
}
