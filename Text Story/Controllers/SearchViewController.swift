//
//  SearchViewController.swift
//  Text Story
//
//  Created by Joseph on 5/28/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import UIKit
import CoreData

class SearchViewController: UIViewController {
    
    @IBOutlet weak var booksTableView: UITableView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var bookManager: BookManager!
    var bookManagerLoaded = false
    let bookInfoViewControllerID = "bookInfoViewController"
    var query: String!
    var foundBooks: [Book] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.numberOfLines = 0
        booksTableView.dataSource = self
        booksTableView.delegate = self
        loadBookManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = "Search Results"
        navigationController?.navigationBar.isHidden = false
        tabBarController?.tabBar.isHidden = true
    }
    
    func loadBookManager() {
        updateUI(state: .loadingBookManager, status: "Preparing for search...")
        bookManager = BookManager()
        bookManager.load {
            self.bookManagerLoaded = true
            self.getSearchBooks()
        }
    }
    
    func getSearchBooks() {
        updateUI(state: .gettingBooks)
        
        // Check if there are any saved books before downloading
        foundBooks.removeAll()
        bookManager.deleteSearchResults()
        
        doSearch()
    }
    
    func doSearch() {
        updateUI(state: .gettingBooks) 
        HttpHelper.search(query, handler: showFoundBooks(errorMessage:gutenbergBookList:))
    }
    
    func showFoundBooks(errorMessage: String?, gutenbergBookList: [GutenbergBook]) {
        DispatchQueue.main.async {
            if errorMessage != nil {
                self.updateUI(state: .ready, status: errorMessage)
            } else {
                for gutenbergBook in gutenbergBookList {
                    if let existing = self.bookManager.getBookById(id: gutenbergBook.id) {
                        self.foundBooks.append(existing)
                    } else {
                        let book = self.bookManager.createBook(gutenbergBook: gutenbergBook, isRandom: true)
                        self.foundBooks.append(book)
                    }
                }
                
                self.foundBooks.sort(by: BookManager.bookSorter)
                self.updateUI(state: .ready)
            }
        }
    }
    
    func updateUI(state: UIState, status: String? = nil ) {
        switch state {
        case .loadingBookManager, .gettingBooks:
            activityIndicator.startAnimating()
            statusLabel.text = status ?? "Searching..."
            stackView.isHidden = false
            booksTableView.isHidden = true
        default:
            activityIndicator.stopAnimating()
            if foundBooks.count == 0 {
                stackView.isHidden = false
                booksTableView.isHidden = true
                statusLabel.text = status ?? "No matches were found"
            } else {
                stackView.isHidden = true
                booksTableView.isHidden = false
                statusLabel.text = ""
                booksTableView.reloadData()
                let first = IndexPath(row: 0, section: 0)
                booksTableView.scrollToRow(at: first, at: .top, animated: true)
            }
        }
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let book = foundBooks[indexPath.section]
        let cell = booksTableView.dequeueReusableCell(withIdentifier: "bookCell", for: indexPath)
        cell.textLabel?.text = book.title
        cell.detailTextLabel?.text = book.author
        if let data = book.coverArt, let image = UIImage(data: data) {
            cell.imageView?.image = image
        } else {
            HttpHelper.getCoverArt(bookID: book.id, cell: cell, handler: updateBookCoverArt(cell:data:))
        }
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return foundBooks.count
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 4
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let navigator = navigationController {
            let book = foundBooks[indexPath.section]
            if let bookInfoController = storyboard?.instantiateViewController(withIdentifier: bookInfoViewControllerID) as! BookInfoViewController? {
                bookInfoController.book = book
                navigator.pushViewController(bookInfoController, animated: true)
            }
        }
    }
    
    func updateBookCoverArt(cell: UITableViewCell, data: Data) {
        DispatchQueue.main.async {
            if let image = UIImage(data: data) {
                cell.imageView?.image = image
                if let indexPath = self.booksTableView.indexPath(for: cell) {
                    let book = self.foundBooks[indexPath.section]
                    book.coverArt = data
                    try? book.managedObjectContext?.save()
                }
            }
        }
    }
}
