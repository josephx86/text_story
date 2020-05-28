//
//  ReadingViewController.swift
//  Text Story
//
//  Created by Joseph on 5/28/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import UIKit

class ReadingViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    var text: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = text 
    }
}
