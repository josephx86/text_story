//
//  BookInfoViewController.swift
//  Text Story
//
//  Created by Joseph on 5/28/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import UIKit

class BookInfoViewController: UIViewController {
    
    @IBOutlet weak var coverArtImageView: UIImageView!
    @IBOutlet weak var detailsTextView: UITextView!
    @IBOutlet weak var progressStackView: UIStackView!
    @IBOutlet weak var downloadReadButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var book: Book!
    let readingViewControllerId = "readingViewController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Book Details"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
        tabBarController?.tabBar.isHidden = true
        setDetails()
        getExtras()
    }
    
    @IBAction func downloadAndRead(_ sender: Any) {
        if book.text == nil {
            downloadBook()
        } else {
            readBook()
        }
    }
    
    func downloadBook() {
        updateUI(gettingExtras: true, status: "Downloading book...")
        HttpHelper.getBookText(bookID: book.id) { (error, text) in
            DispatchQueue.main.async {
                if let error = error {
                    self.showMessage(error)
                } else if let text = text {
                    self.applyBookText(text)
                } else {
                    self.showMessage("Failed to download book!")
                }
                self.updateUI(gettingExtras: false)
            }
        }
    }
    
    func readBook() {
        if let navigator = navigationController {
            if let readingController = storyboard?.instantiateViewController(withIdentifier: readingViewControllerId) as! ReadingViewController?{
                readingController.text = String(data: book.text!, encoding: .utf8)
                navigator.pushViewController(readingController, animated: true)
            }
        }
    }
    
    func getExtras() {
        if !book.hasExtras {
            updateUI(gettingExtras: true)
            HttpHelper.getBookInfo(bookID: book.id) { (_, gutenbergBook) in
                if let gutenbergBook = gutenbergBook {
                    DispatchQueue.main.async {
                        self.applyExtras(gutenbergBook: gutenbergBook)
                    }
                }
            }
        }
    }
    
    func applyBookText(_ text: String) {
        if !text.isEmpty {
            book.isRandom = false
            book.isSearchResult = false
            book.text = text.data(using: .utf8)
            try? book.managedObjectContext?.save()
        }
        setDetails()
    }
    
    func applyExtras(gutenbergBook: GutenbergBook) {
        if !gutenbergBook.uniformTitle.isEmpty {
            book.uniformTitle = gutenbergBook.uniformTitle
        }
        if !gutenbergBook.language.isEmpty {
            book.language = gutenbergBook.language
        }
        if !gutenbergBook.locClass.isEmpty {
            book.locClass = gutenbergBook.locClass
        }
        if !gutenbergBook.category.isEmpty {
            book.category = gutenbergBook.category
        }
        if !gutenbergBook.releaseDate.isEmpty {
            book.releaseDate = gutenbergBook.releaseDate
        }
        if !gutenbergBook.copyrightStatus.isEmpty {
            book.copyright = gutenbergBook.copyrightStatus
        }
        if !gutenbergBook.subjects.isEmpty {
            book.subject = gutenbergBook.subjects.sorted().joined(separator: ", ") 
        }
        if book.isUpdated {
            book.hasExtras = true
            try? book.managedObjectContext?.save()
        }
        setDetails()
    }
    
    func updateUI(gettingExtras: Bool, status: String? = nil) {
        if gettingExtras {
            progressStackView.isHidden = false
            activityIndicator.startAnimating()
            downloadReadButton.isHidden = true
            statusLabel.text = status ?? "Getting book details..."
        } else {
            statusLabel.text = ""
            downloadReadButton.isHidden = false
            progressStackView.isHidden = true
            activityIndicator.stopAnimating()
        }
        
        // Show delete button if book is downloaded
        if book.text == nil {
            navigationItem.rightBarButtonItems?.removeAll()
        } else {
            let deleteButton = UIBarButtonItem(title: "DELETE", style: .done, target: self, action: #selector(deleteBook))
            deleteButton.tintColor = .red
            navigationItem.setRightBarButton(deleteButton, animated: true)
        }
    }
    
    @objc func deleteBook() {
        // Ask if user wants to delete.
        let question = UIAlertController(title: "Confirm delete", message: "Are you sure you sure you want to delete this book?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Yes, Delete", style: .destructive) { (_) in
            if let managerContext = self.book.managedObjectContext {
                managerContext.delete(self.book)
                try? managerContext.save()
                if let navigator = self.navigationController {
                    navigator.popViewController(animated: true)
                }
            }
        }
        question.addAction(cancelAction)
        question.addAction(deleteAction)
        present(question, animated: true)
    }
    
    func setDetails() {
        if book.text == nil {
            downloadReadButton.setTitle("Download", for: .normal)
        } else {
            downloadReadButton.setTitle("Read", for: .normal)
        }
        if let data = book.coverArt, let image = UIImage(data: data) {
            coverArtImageView.image = image
        }
        var buffer = ""
        if let title = book.title {
            buffer += "Title: \(title)"
        }
        if let uniformTitle = book.uniformTitle {
            buffer += "\n\nUniform Title: \(uniformTitle)"
        }
        if let author = book.author {
            buffer += "\n\nAuthor: \(author)"
        }
        if let language = book.language {
            buffer += "\n\nLanguage: \(language)"
        }
        if let subject = book.subject {
            buffer += "\n\nSubject: \(subject)"
        }
        if let category = book.category {
            buffer += "\n\nCategory: \(category)"
        }
        if let locClass = book.locClass {
            buffer += "\n\nLoC Class: \(locClass)"
        }
        if let releaseDate = book.releaseDate {
            buffer += "\n\nRelease Date: \(releaseDate)"
        }
        if let copyright = book.copyright {
            buffer += "\n\nCopyright: \(copyright)"
        }
        detailsTextView.text = buffer
        updateUI(gettingExtras: false)
    }
}
