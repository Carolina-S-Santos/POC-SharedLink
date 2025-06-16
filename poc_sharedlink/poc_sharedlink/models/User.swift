//
//  User.swift
//  poc_shared_link
//
//  Created by Carolina Silva dos Santos on 11/06/25.
//

import Foundation
import CloudKit

class User {
    let id: UUID = UUID()
    var name: String
    var nickname: String?
    var icloudRecordID: String?
    
    init(name: String, icloudRecordID: String? = nil) {
        self.name = name
        self.icloudRecordID = icloudRecordID
    }
}
