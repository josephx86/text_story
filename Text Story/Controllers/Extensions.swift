//
//  Extensions.swift
//  Text Story
//
//  Created by Joseph on 5/28/20.
//  Copyright © 2020 Joseph. All rights reserved.
//

import UIKit

extension UIViewController {
    func showMessage(_ message: String, title: String? = nil) {
           let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
           let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
           alert.addAction(dismissAction)
           present(alert, animated: true)
       }
}
