//
//  Stop.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 7/25/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit
import SubwayStations

public class NYCStop: NSObject, Stop {
    public var name: String!
    public var objectId: String!
    public var parentId: String!
    public var station: Station!
   
    init(name: String!, objectId: String!, parentId: String?) {
        super.init()
        self.name = name
        self.objectId = objectId
        self.parentId = parentId
    }
}
