//
//  News+CoreDataProperties.swift
//  NewsFeed
//
//  Created by Philip on 10/29/19.
//  Copyright © 2019 Philip. All rights reserved.
//
//

import Foundation
import CoreData


extension News {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<News> {
        return NSFetchRequest<News>(entityName: "News")
    }

    @NSManaged public var date: Date
    @NSManaged public var shortDescr: String?
    @NSManaged public var title: String?
    @NSManaged public var url: String?

}
