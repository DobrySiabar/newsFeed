//
//  ViewController.swift
//  NewsFeed
//
//  Created by Philip on 10/22/19.
//  Copyright © 2019 Philip. All rights reserved.
//

import UIKit
import CoreData

struct TableViewCellIdentifiers {
    static let searchResultCell = "SearchResultCell"
    static let nothingFoundCell = "NothingFoundCell"
    static let loadingCell = "LoadingCell"
}

class SearchViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let apiKey = "664a359523d84287a4eac1c9289a0085"
    
    var searchResults: [SearchResult] = [] 
    var filteredSearchResults: [SearchResult] = []
    
    var dataTask: URLSessionDataTask?
    var managedObjectContext: NSManagedObjectContext!
    var refreshControl = UIRefreshControl()
    
    var isLoading = false
    var weeklyNewsOnPage = false
    var daysNews = 0

    let applicationDocumentsDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let lightGrayColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
        tableView.backgroundColor = lightGrayColor
        downloadJSON()
        handleGestures()
        
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        
        // Register new cells
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)

        tableView.reloadData()
    }
    
    func handleGestures() {
        // pull to refresh
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing")
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl)
        
        // hide keyboard on tap
        let hideKBTap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        hideKBTap.cancelsTouchesInView = false
        view.addGestureRecognizer(hideKBTap)
    }
    
    @objc func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer, for indexPath: IndexPath) {
        if longPressGestureRecognizer.state == .began   {
            guard let indexPath = tableView.indexPathForRow(at: longPressGestureRecognizer.location(in: self.tableView)) else { return }
            let cell = tableView.cellForRow(at: indexPath) as! SearchResultCell
    
            if saveData(for: indexPath, with: cell.previewImageView.image) {
                let hudView = HudView.hud(inView: view, animated: true)
                hudView.text = "Saved"
                afterDelay(0.7) {
                    hudView.hide()
                }
            }
        }
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
        searchBar.text = ""
        daysNews = 0
        weeklyNewsOnPage = false
        searchResults = []
        downloadJSON()
        sender.endRefreshing()
        tableView.reloadData()
    }
    
    func saveData(for indexPath: IndexPath, with image: UIImage?) -> Bool {
        let date = Date()
        let searchResult = searchResults[indexPath.row]
        let newsModel = News(context: managedObjectContext)
        newsModel.title = searchResult.title
        newsModel.shortDescr = searchResult.shortDescription
        newsModel.url = searchResult.imageUrl
        newsModel.date = date
        
        do {
            try managedObjectContext.save()
            if let image = image {
                let data = image.jpegData(compressionQuality: 1.0)
                try? data!.write(to: applicationDocumentsDirectory.appendingPathComponent("\(date).jpg"))
                
            }
        } catch {
            fatalError("Error: \(error)")
        }
        
        return true
    }

    func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
    }
    
    func downloadJSON() {
        let stringUrl = String(format:"https://newsapi.org/v2/everything")
        
        let currentDate = Calendar.current.date(byAdding: .day, value: (-daysNews), to: Date())!
        let format = DateFormatter()
        format.timeZone = TimeZone(abbreviation: "GMT")
        format.dateFormat = "yyyy-MM-dd"
        let formattedDateFrom = format.string(from: currentDate)
        let formattedDateTo = format.string(from: currentDate)
        
        var urlComponents = URLComponents(string: stringUrl)!
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: "world"),
            URLQueryItem(name: "from", value: formattedDateFrom),
            URLQueryItem(name: "to", value: formattedDateTo),
            URLQueryItem(name: "sortBy", value: "publishedAt"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        let url = urlComponents.url!
        dataTask?.cancel()
        let session = URLSession.shared
        dataTask = session.dataTask(with: url, completionHandler: { (data, response, error) in
            if error != nil {
                return
            }
            guard let data = data else { return }
            let results = self.parseJSON(data: data)
            self.searchResults += results
            self.filteredSearchResults = self.searchResults
            if self.daysNews == 7 {
                self.weeklyNewsOnPage = true
            }
            self.daysNews += 1
            DispatchQueue.main.async {
                self.isLoading = true
                self.tableView.reloadData()
            }
            
        })
        dataTask?.resume()
    }
    
    func parseJSON(data: Data) -> [SearchResult] {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ResultArray.self, from: data)
            return result.articles
        } catch {
            return []
        }
    }
    
    func preparedSources() -> (textReplacementType: ExpandableLabel.TextReplacementType, numberOfLines: Int, textAlignment: NSTextAlignment)? {
        return (.word, 3, .justified)
    }
    
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredSearchResults = searchResults.filter({ news -> Bool in
            if searchText.isEmpty { return true }
            return news.title!.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if filteredSearchResults.count == 0 {
            return 1
        } else {
            return filteredSearchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let allRows = tableView.numberOfRows(inSection: 0)
        if !isLoading {
            tableView.separatorStyle = .none
            let cell = tableView.dequeueReusableCell(withIdentifier:
                TableViewCellIdentifiers.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        } else if filteredSearchResults.count == 0 {
            tableView.separatorStyle = .none
            return tableView.dequeueReusableCell(withIdentifier:
                TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
        } else {
            tableView.separatorStyle = .singleLine
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            cell.shortDescriptionLabel.delegate = self
            cell.shortDescriptionLabel.setLessLinkWith(lessLink: "Hide", attributes: [.foregroundColor:UIColor.blue])
            cell.shortDescriptionLabel.numberOfLines = 3
            cell.shortDescriptionLabel.shouldCollapse = true
     
            let searcResult = filteredSearchResults[indexPath.row]
            cell.configure(for: searcResult)
    
            if let last = tableView.indexPathsForVisibleRows?.last?[1], searchBar.text == "" {
                let indexes = (searchResults.count-1 ..< allRows).map { $0 }
                if (indexes.contains(last)) {
                    if !weeklyNewsOnPage {
                        downloadJSON()
                    }
                }
            }
            
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
            cell.addGestureRecognizer(longPressRecognizer)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
}

extension SearchViewController: ExpandableLabelDelegate {
    
    func willExpandLabel(_ label: ExpandableLabel) {
        tableView.beginUpdates()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) as IndexPath? {
            filteredSearchResults[indexPath.row].expanded = false
            label.collapsed = false
        }
        tableView.endUpdates()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        tableView.beginUpdates()
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) as IndexPath? {
            filteredSearchResults[indexPath.row].expanded = true
        }
        tableView.endUpdates()
    }
    
}

