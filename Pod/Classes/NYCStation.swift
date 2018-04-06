//
//  NYCStation.swift
//  Pods
//
//  Created by Elliot Schrock on 6/29/16.
//
//

import UIKit
import SubwayStations

open class NYCStation: Station {
    open var primaryId: String?
    open var name: String!
    open var stops: Array<Stop> = Array<Stop>()
    
    public init(name: String!) {
        self.name = name
    }
    
    public static func ==(lhs: NYCStation, other: NYCStation) -> Bool {
        if lhs.name != other.name {
            return false
        }
        
        for stop in other.stops {
            if lhs.stops.filter({ $0.objectId == stop.objectId }).count == 0 {
                return false
            }
        }
        
        return true
    }
}
