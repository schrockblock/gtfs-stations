//
//  NYCStation.swift
//  Pods
//
//  Created by Elliot Schrock on 6/29/16.
//
//

import UIKit
import SubwayStations

public class NYCStation: Station {
    public var name: String!
    public var stops: Array<Stop> = Array<Stop>()
    
    public init(name: String!) {
        self.name = name
    }
}
