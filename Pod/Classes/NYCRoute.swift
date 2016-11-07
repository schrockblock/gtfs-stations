//
//  Route.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/10/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit
import SubwayStations

open class NYCRoute: Route {
    open var color: UIColor!
    open var objectId: String!
    
    public init(objectId: String!) {
        self.objectId = objectId
    }
}
