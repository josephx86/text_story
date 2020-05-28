//
//  GutenbergBook.swift
//  Text Story
//
//  Created by Joseph on 5/27/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import Foundation

struct GutenbergBook {
    let title: String
    let author: String?
    let id: Int32
    
    var uniformTitle: String = ""
    var language = ""
    var locClass = ""
    var subjects: Set<String> = []
    var category = ""
    var releaseDate = ""
    var copyrightStatus = "" 
}
