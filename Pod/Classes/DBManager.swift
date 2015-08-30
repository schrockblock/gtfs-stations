//
//  DBManager.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 7/25/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit
import SQLite

public class DBManager: NSObject {
    var filename: String!
    var documentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    }
    lazy var database: Database = {
        let components = self.filename.componentsSeparatedByString(".")
        let sourcePath = NSBundle.mainBundle().pathForResource(components[0], ofType: components[components.count - 1])
        let lazyDatabase = Database(sourcePath!)
        return lazyDatabase
    }()
    
    init(filename: String!) {
        super.init()
        self.filename = filename
    }
    
}
