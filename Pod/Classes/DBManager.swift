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
    lazy var database: Connection = try! {
        let lazyDatabase = try Connection(self.sourcePath)
        return lazyDatabase
    }()
    
    init(sourcePath: String!) {
        super.init()
        self.sourcePath = sourcePath
    }
}
