//
//  DownloadsViewController.swift
//  Text Story
//
//  Created by Joseph on 5/28/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import UIKit
import CoreData

class DownloadsViewController: SearchableViewController {
    
    @IBOutlet weak var booksTableView: UITableView! 
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var bookManager: BookManager!
    var downloadedBooks: [Book] = []
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
        
        // Reload books, it is possible some may have been removed in detail view
        if bookManagerLoaded {
            getDownloadedBooks()
        }
    }
    
    func loadBookManager() {
        updateUI(state: .loadingBookManager, status: "Checking downloaded books...")
        bookManager = BookManager()
        bookManager.load {
            self.bookManagerLoaded = true
            self.getDownloadedBooks()
        }
    }
    
    func updateUI(state: UIState, status: String? = nil ) {
        updateSearchBar(state: state)
        switch state {
        case .loadingBookManager, .gettingBooks:
            activityIndicator.startAnimating()
            statusLabel.text = status ?? "Getting books..."
            stackView.isHidden = false
            booksTableView.isHidden = true
        default: 
            activityIndicator.stopAnimating()
            if downloadedBooks.count == 0 {
                stackView.isHidden = false
                booksTableView.isHidden = true
                statusLabel.text = status ?? "There are no downloaded books"
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
    
    func getDownloadedBooks() {
        updateUI(state: .gettingBooks)
        downloadedBooks.removeAll()
        downloadedBooks = bookManager.getDownloadedBooks()
        updateUI(state: .ready)
    }
}

extension DownloadsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let book = downloadedBooks[indexPath.section]
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
        return downloadedBooks.count
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 4
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let navigator = navigationController {
            let book = downloadedBooks[indexPath.section]
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
                    let book = self.downloadedBooks[indexPath.section]
                    book.coverArt = data
                    try? book.managedObjectContext?.save()
                }
            }
        }
    }
}
