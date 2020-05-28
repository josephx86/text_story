# Text Story

This is an app that allows a user to search, download, and read books in plain-text format (.txt) from gutenberg.org. It uses CoreData to keep book details stored on the device.

![Random books](/01_random.png?raw=true) ![Books details](/02_details.png?raw=true) ![Reading a book](/03_reading.png?raw=true)

# Implementation

Describe the main view controllers of the app and what they do more in detail

# How to build

Download the source to your computer with XCode 11 installed
Open the project by double-clicking on "Text Story.xcodeproj"

# Requirements

Xcode 9.2
Swift 4.0

The app allows the user to read books as text files from gutenberg.org

When the app is launched, the user is presented with a tabbed screen that has "Random"  and "Downloads" tabs. The user is first shown random books. Pressing on one of the books will take the user to a book details screen. 

On the details screen, a user can download a book. The user interface will allow reading or deleting books after they have been downloaded and stored on the device. Before deleting, the app will ask the user to confirm the delete operation. If a user wants to read a book, they can press on the read button after the downloading the book, which will take the user to a screen where teh book text is displayed. 

Going back to the initial tabbed screen, the user can view a list of downloaded books. 

On the from the Random or Downloads screens, a user can search for books and the reults will be shown in a separate screen.
