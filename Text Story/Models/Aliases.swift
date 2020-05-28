//
//  Aliases.swift
//  Text Story
//
//  Created by Joseph on 5/28/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import Foundation
import UIKit

typealias BookInfoDelegate = (String?, GutenbergBook?) -> Void
typealias BookTextDelegate = (String?, String?) -> Void
typealias BookResultsDelegate = (String?, [GutenbergBook]) -> Void
typealias CoverArtDelegate = (UITableViewCell, Data) -> Void
typealias BookSortDelegate = (Book, Book) -> Bool
