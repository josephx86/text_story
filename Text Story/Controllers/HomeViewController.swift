//
//  HomeViewController.swift
//  Text Story
//
//  Created by Joseph on 5/27/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import UIKit
import CoreData

class HomeViewController: SearchableViewController {
    
    @IBOutlet weak var booksTableView: UITableView! 
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var getRandomButton: UIButton!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var bookManager: BookManager!
    var randomBooks: [Book] = []
    var bookManagerLoaded = false
    let bookInfoViewControllerID = "bookInfoViewController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.numberOfLines = 0
        booksTableView.dataSource = self
        booksTableView.delegate = self
        loadBookManager() 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = true
        tabBarController?.tabBar.isHidden = false
        
        // Reload books, it is possible some may have been removed in detail view or expired
        if bookManagerLoaded {
            getRandomBooks()
        }
    }
    
    @IBAction func retryGetRandomBooks() {
        getRandomBooks()
    }
    
    @IBAction func downloadRandomBooks() {
        updateUI(state: .gettingBooks)
        HttpHelper.getRandomBooks(handler: showRandomBooks(errorMessage:gutenbergBookList:))
    }
    
    func loadBookManager() {
        updateUI(state: .loadingBookManager, status: "Checking saved books...")
        bookManager = BookManager()
        bookManager.load {
            self.bookManagerLoaded = true
            self.getRandomBooks()
        }
    }
    
    func getRandomBooks() {
        updateUI(state: .gettingBooks)
        
        // Check if there are any saved books before downloading
        randomBooks.removeAll()
        randomBooks = bookManager.getRandomBooks()
        
        // If users previously favorited or downloaded a book marked random, the book manager will skip it.
        // So it is possible returned books might be less than 10 in total... in which case, download more books. 
        if randomBooks.count < 10 {
            downloadRandomBooks()
        } else {
            randomBooks.sort(by: BookManager.bookSorter)
            updateUI(state: .ready) 
        }
    }
    
    func updateUI(state: UIState, status: String? = nil ) {
        updateSearchBar(state: state)
        switch state {
        case .loadingBookManager, .gettingBooks:
            activityIndicator.startAnimating()
            statusLabel.text = status ?? "Getting books..."
            retryButton.isHidden = true
            getRandomButton.isHidden = true
            stackView.isHidden = false
            booksTableView.isHidden = true
        default: 
            activityIndicator.stopAnimating()
            if randomBooks.count == 0 {
                stackView.isHidden = false
                booksTableView.isHidden = true
                statusLabel.text = status ?? "Oops!\nSomething went wrong while trying to get books ☹️"
                retryButton.isHidden = false
                getRandomButton.isHidden = true
            } else {
                stackView.isHidden = true
                booksTableView.isHidden = false
                statusLabel.text = ""
                retryButton.isHidden = true
                getRandomButton.isHidden = false
                booksTableView.reloadData()
                let first = IndexPath(row: 0, section: 0)
                booksTableView.scrollToRow(at: first, at: .top, animated: true)
            }
        }
    }
    
    func showRandomBooks(errorMessage: String?, gutenbergBookList: [GutenbergBook]) {
        DispatchQueue.main.async {
            if errorMessage != nil {
                self.updateUI(state: .ready, status: errorMessage)
            } else {
                self.bookManager.deleteRandomBooks()
                self.randomBooks.removeAll()
                for gutenbergBook in gutenbergBookList {
                    let book = self.bookManager.createBook(gutenbergBook: gutenbergBook, isRandom: true)
                    self.randomBooks.append(book)
                }
                
                self.randomBooks.sort(by: BookManager.bookSorter)
                self.updateUI(state: .ready)
            }
        }
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let book = randomBooks[indexPath.section]
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
        return randomBooks.count
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 4
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let navigator = navigationController {
            let book = randomBooks[indexPath.section]
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
                    let book = self.randomBooks[indexPath.section]
                    book.coverArt = data
                    try? book.managedObjectContext?.save()
                }
            }
        }
    }
}

