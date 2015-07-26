//
//  Station.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/10/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit

class Station: NSObject, Equatable {
    var objectId: String!
    var name: String!
    var stops: Array<Stop> = Array<Stop>()
    
    init(objectId: String!) {
        super.init()
        self.objectId = objectId
    }
    
    func predictionsForTime(time: NSDate!) -> Array<Prediction>? {
        return nil
    }
    
}

func ==(lhs: Station, rhs: Station) -> Bool {
    return lhs.objectId == rhs.objectId
}
