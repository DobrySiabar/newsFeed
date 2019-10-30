//
//  Model.swift
//  NewsFeed
//
//  Created by Philip on 10/22/19.
//  Copyright © 2019 Philip. All rights reserved.
//

import Foundation

struct ResultArray: Codable {
    var status: String = ""
    var totalResults = 0
    var articles = [SearchResult]()
}

struct SearchResult: Codable, CustomStringConvertible {
    enum CodingKeys: String, CodingKey {
        case title = "title"
        case shortDescription = "description"
        case imageUrl = "urlToImage"
    }
    
    let title: String?
    let shortDescription: String?
    var imageUrl: String?
    var expanded: Bool = false

    var description: String {
        return "Title: \(title ?? "None") \nDescription: \(shortDescription ?? "None") \nImage link: \(String(describing: imageUrl))\n"
    }
}
