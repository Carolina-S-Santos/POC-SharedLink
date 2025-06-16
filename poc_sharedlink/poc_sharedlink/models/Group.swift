//
//  Group.swift
//  poc_shared_link
//
//  Created by Carolina Silva dos Santos on 11/06/25.
//
import Foundation
import UIKit

public class Group {
    let id: UUID = UUID()
    
    var name: String
    
    var users: [User] = []
        
    init(name: String) {
        self.name = name
    }
}
