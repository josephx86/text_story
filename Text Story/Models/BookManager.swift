//
//  BookManager.swift
//  Text Story
//
//  Created by Joseph on 5/27/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import Foundation
import CoreData

class BookManager {
    let persistentContainer: NSPersistentContainer
    
    init() {
        persistentContainer = NSPersistentContainer(name: "Model")
    }
    
    static var bookSorter : BookSortDelegate = {
        // Sort the books by title
        let title1 = $0.title ?? ""
        let title2 = $1.title ?? ""
        let result = title1.compare(title2)
        switch result {
        case ComparisonResult.orderedAscending:
            return true
        default:
            return false
        }
    }
    
    func load(handler: @escaping () -> Void) {
        persistentContainer.loadPersistentStores { (_ , _) in
            handler()
        }
    }
    
    func deleteRandomBooks() {
        let fetchRequest: NSFetchRequest<Book> = Book.fetchRequest()
        if let randomBooks = try? persistentContainer.viewContext.fetch(fetchRequest) {
            for book in randomBooks {
                // Skip downloaded books, i.e., text != nil
                let notDownloaded = (book.text == nil)
                if book.isRandom && notDownloaded {
                    deleteBook(book)
                }
            }
        }
    }
    
    func deleteSearchResults() {
        let fetchRequest: NSFetchRequest<Book> = Book.fetchRequest()
        if let foundBooks = try? persistentContainer.viewContext.fetch(fetchRequest) {
            for book in foundBooks { 
                if book.isSearchResult {
                    deleteBook(book)
                }
            }
        }
    }
    
    func getBookById(id: Int32) -> Book? {
        let fetchRequest: NSFetchRequest<Book> = Book.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %d", id)
        guard let allBooks = try? persistentContainer.viewContext.fetch(fetchRequest) else {
            return nil
        }
        
        if allBooks.isEmpty {
            return nil
        } else { 
            return allBooks.first
        }
    }
    
    func getDownloadedBooks() -> [Book] {
        let fetchRequest: NSFetchRequest<Book> = Book.fetchRequest()
        guard let allBooks = try? persistentContainer.viewContext.fetch(fetchRequest) else {
            return []
        }
        
        var matchedBooks: [Book] = [] 
        for book in allBooks {
            if book.text != nil {
                matchedBooks.append(book)
            }
        }
        return matchedBooks
    }
    
    func getRandomBooks() -> [Book] {
        let fetchRequest: NSFetchRequest<Book> = Book.fetchRequest()
        guard let allBooks = try? persistentContainer.viewContext.fetch(fetchRequest) else {
            return []
        }
        
        // return books that are:
        // 1. marked random
        // 2. are not downloaded
        // 3. stored less than 24hrs ago
        
        var matchedBooks: [Book] = []
        let secondsInDay = 60.0 * 60.0 * 24.0
        let now = Date()
        for book in allBooks {
            
            if book.text != nil {
                continue
            }
            
            var isOld = false
            if let saveDate = book.storeDate {
                let elapsedSeconds = saveDate.distance(to: now)
                isOld = elapsedSeconds > secondsInDay
            }
            if isOld {
                continue
            }
            
            if book.isRandom {
                matchedBooks.append(book)
            }
        }
        
        // If count of books matched is less than 10,
        // return empty list so that more can be downloaded online.
        if matchedBooks.count >= 10 {
            return matchedBooks
        } else {
            return []
        }
    }
    
    func createBook(gutenbergBook: GutenbergBook, isRandom: Bool = false) -> Book {
        let book = Book(context: persistentContainer.viewContext)
        book.id = gutenbergBook.id
        book.title = gutenbergBook.title
        book.author = gutenbergBook.author
        book.isRandom = isRandom
        book.storeDate = Date()
        try? persistentContainer.viewContext.save()
        return book
    }
    
    func deleteBook(_ book: Book) {
        persistentContainer.viewContext.delete(book)
        try? persistentContainer.viewContext.save()
    }
}
