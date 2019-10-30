//
//  NewsViewController.swift
//  NewsFeed
//
//  Created by Philip on 10/29/19.
//  Copyright © 2019 Philip. All rights reserved.
//

import UIKit
import CoreData

class FavouriteViewController: UITableViewController {
    
    var managedObjectContext: NSManagedObjectContext!
    
    let applicationDocumentsDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let lightGrayColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
        tableView.backgroundColor = lightGrayColor
        
        let cellNib = UINib(nibName: "SearchResultCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "SearchResultCell")
        performFetch()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    // Using NSFetchedResultsController
    lazy var fetchedResultsController:
        NSFetchedResultsController<News> = {
            let fetchRequest = NSFetchRequest<News>()
            let entity = News.entity()
            fetchRequest.entity = entity
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            fetchRequest.fetchBatchSize = 20
            let fetchedResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: self.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: "NewsCache")
            fetchedResultsController.delegate = self
            return fetchedResultsController
    }()
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
    }

    func deleteImage(with date: Date) {
        let fileManager = FileManager.default
        let applicationDocumentsDirectory: URL = {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }()
        let urlString = String(format: "\(applicationDocumentsDirectory.path)/\(date).jpg")
        do {
            try fileManager.removeItem(atPath: urlString)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavouriteNewsCell", for: indexPath)
        let news = fetchedResultsController.object(at: indexPath)
        let imageView = cell.viewWithTag(1000) as! UIImageView
        if let _ = news.url {
            let date = news.date
            let filePath = applicationDocumentsDirectory.appendingPathComponent("\(date).jpg").path
            if FileManager.default.fileExists(atPath: filePath) {
                imageView.image =  UIImage(contentsOfFile: filePath)
            }
        } else {
            imageView.image = UIImage(named: "Placeholder")
        }
        
        let titleLabel = cell.viewWithTag(1001) as! UILabel
        titleLabel.text = news.title
        
        let descriptionLabel = cell.viewWithTag(1002) as! UILabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = news.shortDescr
        
        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let news = fetchedResultsController.object(at: indexPath)
            let date = news.date
            deleteImage(with: date)
            managedObjectContext.delete(news)
            do {
                try managedObjectContext.save()
            } catch {
                print(error)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
}

extension FavouriteViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
         switch type {
         case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
         case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
         case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? SearchResultCell {
                let news = controller.object(at: indexPath!) as! News
                cell.configureFavourite(for: news)
            }
         case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
         }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
         switch type {
             case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
             case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
             default:
                return
         }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
          tableView.endUpdates()
    }
}
