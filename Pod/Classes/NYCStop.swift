//
//  Stop.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 7/25/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit
import SubwayStations

open class NYCStop: NSObject, Stop {
    open var name: String!
    open var objectId: String!
    open var parentId: String!
    open var station: Station!
   
    init(name: String!, objectId: String!, parentId: String?) {
        super.init()
        self.name = name
        self.objectId = objectId
        self.parentId = parentId
    }
}
