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
        let lazyDatabase = Database(self.documentsDirectory + "/" + self.filename)
        return lazyDatabase
    }()
    
    init(filename: String!) {
        super.init()
        self.filename = filename
        copyDBToDocDirectory()
    }
    
    func copyDBToDocDirectory(){
        let destinationPath = documentsDirectory + "/" + filename
        if !NSFileManager.defaultManager().fileExistsAtPath(destinationPath) {
            let components = filename.componentsSeparatedByString(".")
            let sourcePath = NSBundle.mainBundle().pathForResource(components[0], ofType: components[components.count - 1])
            var error: NSError?
            NSFileManager.defaultManager().copyItemAtPath(sourcePath!, toPath: destinationPath, error: &error)
            let fileUrl = NSURL(fileURLWithPath: destinationPath)
            if let copyError = error{
                print(copyError.debugDescription)
            }else{
                fileUrl?.setResourceValue(NSNumber(bool: true), forKey: NSURLIsExcludedFromBackupKey, error: &error)
            }
        }
    }
    
}
