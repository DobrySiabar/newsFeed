//
//  SearchResultCell.swift
//  NewsFeed
//
//  Created by Philip on 10/22/19.
//  Copyright © 2019 Philip. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var shortDescriptionLabel: ExpandableLabel!
    
    var downloadTask: URLSessionDownloadTask?
    
    let applicationDocumentsDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }()
    
    func configure(for searchResult: SearchResult) {
        titleLabel.text = searchResult.title ?? " as "
        shortDescriptionLabel.text = searchResult.shortDescription
        
        previewImageView.image = UIImage(named: "Placeholder")
        guard let imageStringUrl = searchResult.imageUrl else { return }
        if let url = URL(string: imageStringUrl) {
            downloadTask = previewImageView.loadImage(url: url)
        }
    }
    
    func configureFavourite(for news: News) {
        titleLabel.text = news.title ?? " as "
        shortDescriptionLabel.text = news.shortDescr
        shortDescriptionLabel.collapsed = true
        shortDescriptionLabel.numberOfLines = 0
        
        previewImageView.image = UIImage(named: "Placeholder")
        guard let imageStringUrl = news.url else { return }
        if let url = URL(string: imageStringUrl) {
            downloadTask = previewImageView.loadImage(url: url)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        downloadTask?.cancel()
        downloadTask = nil
    }
    
}

extension UIImageView {
    func loadImage(url: URL) -> URLSessionDownloadTask {
        let session = URLSession.shared
        let downloadTask = session.downloadTask(with: url, completionHandler: {
            [weak self] url, response, error in
            if error == nil, let url = url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    if let strongSelf = self {
                        strongSelf.image = image
                    }
                }
            }
        })
        downloadTask.resume()
        return downloadTask
    }
}
