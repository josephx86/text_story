# Text Story

This is an app that allows a user to search, download, and read books in plain-text format (.txt) from gutenberg.org. It uses CoreData to keep book details stored on the device.

![Random books](/01_random.png?raw=true) 

## Implementation

The app has 5 view controllers. The first 2 are accessible using tabs on the landing screen. These are: 
- HomeViewController: This is the 'Random' tab. Shows books randomly fetched from gutenberg.org.
- DownloadsViewController: Shows books that have their full plain text downloaded and saved using CoreData.

HomeViewController displays random books that are refreshed when older than 24 hours. Pressing the 'Get Random' button will fetch a new set of random books. From the 'Random' or 'Downloads' screens, a user can search for books and results will be displayed in SearchViewController

HomeViewController, DownloadsViewController, and SearchViewController all display books in a UITableView and tappig on a book will have the book details shown in BookInfoViewController. This allows a user to see more details about the book and if interested, download and read the book. If a book is already downloaded, it can be deleted from this controller as well.

ReadingViewController allows reading the book's full text when 'Read' is pressed on BookInfoViewController.

All network calls are handled by the HttpHelper class and the DataManager class does most of the operations involving saving, updating and deleting book information via CoreData.

## How to build

Download the source to your computer with XCode 11 installed
Open the project by double-clicking on "Text Story.xcodeproj"
When project is loaded, press the Run button to run the app in an emulator (or iPhone)

## Requirements

- Xcode 11.4
- Swift 4.0
- Simulator or iPhone for testing

