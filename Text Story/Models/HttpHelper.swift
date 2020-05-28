//
//  HttpHelper.swift
//  Text Story
//
//  Created by Joseph on 5/27/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import Foundation
import UIKit

enum Endpoints: String {
    case random = "https://www.gutenberg.org/ebooks/search/?sort_order=random&format=json"
    case coverArt = "https://www.gutenberg.org/cache/epub/_id_/pg_id_.cover.medium.jpg"
    case bookInfo = "https://www.gutenberg.org/ebooks/_id_"
    case bookText = "https://www.gutenberg.org/files/_id_"
    case bookFile = "https://www.gutenberg.org/files/_id_/_file_"
    case search = "https://www.gutenberg.org/ebooks/search/?query=_query_&format=json"
}

class HttpHelper {
    
    fileprivate class func handleBookResults(query: String, json: String, handler: @escaping BookResultsDelegate) {
        let bookData = json.replacingOccurrences(of: "[\"\(query)\",", with: "[[],")
        let properJson = "{\"books\":\(bookData)}"
        let decoder = JSONDecoder()
        if let bookInfo = try? decoder.decode(GutenbergBookInfo.self, from: properJson.data(using: .utf8)!) {
            var bookList: [GutenbergBook] = []
            let count = bookInfo.books[1].count
            if (count > 1) {
                for i in 1..<count {
                    let title = bookInfo.books[1][i] ?? ""
                    let author = bookInfo.books[2][i] ?? ""
                    let url = bookInfo.books[3][i] ?? ""
                    let idString = url
                        .replacingOccurrences(of: "/ebooks/", with: "")
                        .replacingOccurrences(of: ".json", with: "")
                    let id = Int32(idString) ?? -1
                    if id >= 0 {
                        let book = GutenbergBook(title: title, author: author, id: id)
                        bookList.append(book)
                    }}
            }
            
            if bookList.count > 0 {
                handler(nil, bookList)
            } else {
                handler("Failed to get books!", [])
            }
        } else {
            handler("Failed to get books from server!", [])
        }
    }
    
    fileprivate class func getBookInfoTable(html: String) -> String {
        // Locate the table with details in html
        var buffer = html
        while (true) {
            // Find start of row
            guard let start = buffer.range(of: "<table") else {
                break
            }
            buffer = "\(buffer[start.lowerBound..<buffer.endIndex])"
            
            // Find end of row
            guard let end = buffer.range(of: "</table>") else {
                break
            }
            let table = String(buffer[buffer.startIndex..<end.upperBound])
            if table.contains("class=\"bibrec\"") {
                buffer = table
                break
            } else {
                buffer = "\(buffer[end.upperBound..<buffer.endIndex])"
            }
        }
        
        return buffer
    }
    
    fileprivate class func getInfoTableRows(table: String) -> [String] {
        var buffer = table
        var tableRows: [String] = []
        while (true) {
            // Find end of row
            guard let end = buffer.range(of: "</tr>") else {
                break
            }
            let row = String(buffer[buffer.startIndex..<end.upperBound])
            tableRows.append(row)
            buffer = "\(buffer[end.upperBound..<buffer.endIndex])"
        }
        
        return tableRows
    }
    
    fileprivate class func getRowKey(_ row: String) -> String? {
        var buffer = row
        var key: String? = nil
        if let end = buffer.range(of: "</th>") {
            buffer = String(buffer[buffer.startIndex..<end.lowerBound])
            if let start = buffer.lastIndex(of: ">") {
                key = "\(buffer[start..<buffer.endIndex])"
                    .replacingOccurrences(of: ">", with: "")
                    .lowercased()
                    .components(separatedBy: .whitespacesAndNewlines).joined()
            }
        }
        
        // Only keep keys that are vars in GutenbergBook.swift
        let allowedKeys: Set<String> = [
            "uniformtitle",
            "language",
            "locclass",
            "subject",
            "category",
            "releasedate",
            "copyrightstatus",
        ]
        
        if key != nil {
            if key!.isEmpty{
                key = nil
            } else if !allowedKeys.contains(key!) {
                key = nil
            }
        }
        
        return key
    }
    
    fileprivate class func getRowValue(_ row: String) -> String? {
        var buffer = row
        var value: String? = nil
        // Locate start of row value colum
        if let start = buffer.range(of: "<td") {
            buffer = String(buffer[start.upperBound..<buffer.endIndex])
            
            // Locate end of value
            if let end = buffer.range(of: "</") {
                buffer = String(buffer[buffer.startIndex..<end.lowerBound])
                if let start = buffer.lastIndex(of: ">") {
                    value = "\(buffer[start..<buffer.endIndex])"
                        .replacingOccurrences(of: "\n", with: "")
                        .replacingOccurrences(of: ">", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        if value != nil {
            if value!.isEmpty{
                value = nil
            }
        }
        
        return value
    }
    
    fileprivate class func getSubjects(_ value: String) -> Set<String> {
        var subjects: Set<String> = []
        // Some subjects are separated by 2 hyphens
        let parts1 = value.components(separatedBy: "--")
        for p1 in parts1 {
            // Others are separated by a coma and space
            let parts2 = p1.components(separatedBy: ", ")
            for p2 in parts2 {
                subjects.insert(p2.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        return subjects
    }
    
    fileprivate class func handleBookInfo(html: String, handler: @escaping BookInfoDelegate) {
        let bookInfoTable = getBookInfoTable(html: html)
        let tableRows = getInfoTableRows(table: bookInfoTable)
        var gutenbergBook = GutenbergBook(title: "", author: "", id: -1)
        for row in tableRows {
            if let key = getRowKey(row) {
                if let value = getRowValue(row) {
                    switch key {
                    case "uniformtitle":
                        gutenbergBook.uniformTitle = value
                    case "language":
                        gutenbergBook.language = value
                    case "locclass":
                        gutenbergBook.locClass = value
                    case "subject":
                        gutenbergBook.subjects = gutenbergBook.subjects.union( getSubjects(value))
                    case "category":
                        gutenbergBook.category = value
                    case "releasedate":
                        gutenbergBook.releaseDate = value
                    case "copyrightstatus":
                        gutenbergBook.copyrightStatus = value
                    default:
                        // Avoid error: 'default' label in a 'switch' should have at least one executable statement
                        print()
                    }
                }
            }
        }
        
        handler(nil, gutenbergBook)
    }
    
    fileprivate class func handleBookText(_ html: String, bookId: Int32, handler: @escaping BookTextDelegate) {
        // Get all href attributes on page
        var buffer = html
        var textFiles: [String] = []
        while (true) {
            // Get to start of value
            guard let start = buffer.range(of: "href=\"") else {
                break
            }
            buffer = String(buffer[start.upperBound..<buffer.endIndex])
            
            // Cut substring at endof value
            guard let end = buffer.firstIndex(of: "\"") else {
                break
            }
            let value = String(buffer[buffer.startIndex..<end])
            if value.contains(".txt") {
                textFiles.append(value)
            }
            buffer = String(buffer[end..<buffer.endIndex])
        }
        
        if textFiles.count > 0 {
            /*
             Plain text       12345.txt          (encoding: us-ascii)
             8-bit plain text 12345-8.txt        (encodings: iso-8859-1, windows-1252, MacRoman, ...)
             Big-5            12345-5.txt        (encoding: big-5)
             Unicode          12345-0.txt        (encoding: utf-8)
             */
            // At this point, app only supports UTF-8 (and ASCII)
            let bookFilename = Endpoints.bookFile.rawValue
                .replacingOccurrences(of: "_id_", with: "\(bookId)")
                .replacingOccurrences(of: "_file_", with: textFiles[0])
            downloadBook(address: bookFilename, handler: handler)
        } else {
            handler("Book not found!", nil)
        }
    }
    
    fileprivate class func downloadBook(address: String, handler: @escaping BookTextDelegate) {
        if let url = URL(string: address) {
            let task = URLSession.shared.dataTask(with: url) { (data, urlResponse, error) in
                if error != nil {
                    handler(error!.localizedDescription, nil)
                } else {
                    if let data = data {
                        if let text = String(data: data, encoding: .utf8) {
                            handler(nil, text)
                        } else if let text = String(data: data, encoding: .ascii) {
                            handler(nil, text)
                        } else {
                            handler("Failed to decode downloaded file!",nil)
                        }
                    } else {
                        handler("Failed to get book from server!", nil)
                    }
                }
            }
            task.resume()
        } else {
            handler("Failed to create url for book!", nil)
        }
    }
    
    class func getRandomBooks(handler: @escaping BookResultsDelegate) {
        let address = Endpoints.random.rawValue
        if let url = URL(string: address) {
            let task = URLSession.shared.dataTask(with: url) { (data, urlResponse, error) in
                if error != nil {
                    handler(error!.localizedDescription, [])
                } else {
                    let errorMessage = "Failed to get books from server!"
                    if let data = data {
                        // Returned json has an array that has an empty string element
                        // mixed in with with other elements that are string arrays
                        // Replace that element with an empty array then create a proper json object
                        if let json = String(data: data, encoding: .utf8) {
                            handleBookResults(query: "", json: json, handler: handler)
                        } else {
                            handler(errorMessage, [])
                        }
                    } else {
                        handler(errorMessage, [])
                    }
                }
            }
            task.resume()
        } else {
            handler("Failed to create url for books!", [])
        }
    }
    
    class func search(_ query: String, handler: @escaping BookResultsDelegate) {
        let addressQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let address = Endpoints.search.rawValue.replacingOccurrences(of: "_query_", with: addressQuery)
        if let url = URL(string: address) {
            let task = URLSession.shared.dataTask(with: url) { (data, urlResponse, error) in
                if error != nil {
                    handler(error!.localizedDescription, [])
                } else {
                    if let data = data {
                        // Returned json has an array that has an empty string element
                        // mixed in with with other elements that are string arrays
                        // Replace that element with an empty array then create a proper json object
                        if let json = String(data: data, encoding: .utf8) {
                            handleBookResults(query: query, json: json, handler: handler)
                        } else {
                            handler("Failed to get books from server!", [])
                        }
                    } else {
                        handler("Failed to parse data!", [])
                    }
                }
            }
            task.resume()
        } else {
            handler("Failed to create url for books!", [])
        }
    }
    
    class func getCoverArt(bookID: Int32, cell: UITableViewCell, handler: @escaping CoverArtDelegate) {
        let address = Endpoints.coverArt.rawValue.replacingOccurrences(of: "_id_", with: "\(bookID)")
        if let url = URL(string: address) {
            let task = URLSession.shared.dataTask(with: url) { (data, urlResponse, error) in
                if let data = data { 
                    handler(cell, data)
                }
            }
            task.resume()
        }
    }
    
    class func getBookInfo(bookID: Int32, handler: @escaping BookInfoDelegate) {
        let address = Endpoints.bookInfo.rawValue.replacingOccurrences(of: "_id_", with: "\(bookID)")
        if let url = URL(string: address) {
            let task = URLSession.shared.dataTask(with: url) {
                (data, urlResponse, error) in
                if error != nil {
                    handler(error!.localizedDescription, nil)
                } else {
                    let errorMessage = "Failed to get book details from server!"
                    if let data = data {
                        if let html = String(data: data, encoding: .utf8) {
                            handleBookInfo(html: html, handler: handler)
                        } else {
                            handler(errorMessage, nil)
                        }
                    } else {
                        handler(errorMessage, nil)
                    }
                }
            }
            task.resume()
        } else {
            handler("Failed to create url for book!", nil)
        }
    }
    
    class func getBookText(bookID: Int32, handler: @escaping BookTextDelegate) {
        let address = Endpoints.bookText.rawValue.replacingOccurrences(of: "_id_", with: "\(bookID)")
        if let url = URL(string: address) {
            let task = URLSession.shared.dataTask(with: url) {
                (data, urlResponse, error) in
                if error != nil {
                    handler(error!.localizedDescription, nil)
                } else {
                    let errorMessage = "Failed to get book from server!"
                    if let data = data {
                        if let html = String(data: data, encoding: .utf8) {
                            handleBookText(html, bookId: bookID, handler: handler)
                        } else {
                            handler(errorMessage, nil)
                        }
                    } else {
                        handler(errorMessage, nil)
                    }
                }
            }
            task.resume()
        } else {
            handler("Failed to create url for book!", nil)
        }
    }
}
