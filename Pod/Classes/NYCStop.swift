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
    public var latitude: Double?
    public var longitude: Double?
    @objc open var name: String!
    @objc open var objectId: String!
    @objc open var parentId: String!
    open var station: Station!
   
    @objc init(name: String!, objectId: String!, parentId: String?, latitude: Double, longitude: Double) {
        super.init()
        self.name = name
        self.objectId = objectId
        self.parentId = parentId
        self.latitude = latitude
        self.longitude = longitude
    }
}
