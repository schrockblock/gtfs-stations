//
//  Station.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/10/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit

public class Station: NSObject, Equatable {
    public var objectId: String!
    public var name: String!
    public var stops: Array<Stop> = Array<Stop>()
    
    init(objectId: String!) {
        super.init()
        self.objectId = objectId
    }
    
}

public func ==(lhs: Station, rhs: Station) -> Bool {
    return lhs.objectId == rhs.objectId
}
