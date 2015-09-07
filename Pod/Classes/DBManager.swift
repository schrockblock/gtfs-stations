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
    var sourcePath: String!
    lazy var database: Database = {
        let lazyDatabase = Database(self.sourcePath)
        return lazyDatabase
    }()
    
    init(sourcePath: String!) {
        super.init()
        self.sourcePath = sourcePath
    }
}
