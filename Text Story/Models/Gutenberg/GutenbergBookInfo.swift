//
//  GutenbergBookInfo.swift
//  Text Story
//
//  Created by Joseph on 5/27/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import Foundation

struct GutenbergBookInfo: Codable {
    let books: [[String?]]
    
    enum CodingKeys: String, CodingKey {
        case books
    }
}
