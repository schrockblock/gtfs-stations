//
//  Route.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/10/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit
import SubwayStations

public class NYCRoute: NSObject, Route {
    public var color: UIColor!
    public var objectId: String!
    
    init(objectId: String!) {
        super.init()
        self.objectId = objectId
        
        
    }
}
