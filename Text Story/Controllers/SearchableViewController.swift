//
//  SearchableViewController.swift
//  Text Story
//
//  Created by Joseph on 5/28/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import UIKit

class SearchableViewController: UIViewController, UISearchBarDelegate { 
    
    @IBOutlet var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        searchBar.text = ""
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let buffer = searchBar.text else {
            return
        }
        
        let query = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return
        }
        
        if let searchController = storyboard?.instantiateViewController(withIdentifier: "searchViewController") as! SearchViewController? {
            searchController.query = query
            if let navigator = navigationController {
                navigator.pushViewController(searchController, animated: true)
            }
        }
    }
    
    func updateSearchBar(state: UIState) {
        switch state {
        case .loadingBookManager, .gettingBooks:
            searchBar.isHidden = true
        default:
            searchBar.isHidden = false
        }
    }
}

enum UIState {
    case loadingBookManager
    case gettingBooks
    case ready
}
