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
    open var name: String!
    open var stops: Array<Stop> = Array<Stop>()
    
    public init(name: String!) {
        self.name = name
    }
}
