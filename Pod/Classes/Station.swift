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
    if lhs.objectId == rhs.objectId {
        return true
    }
    
    if let lhsName = lhs.name {
        if let rhsName = rhs.name {
            let lhsArray = lhsName.lowercaseString.componentsSeparatedByString(" ")
            let rhsArray = rhsName.lowercaseString.componentsSeparatedByString(" ")
            
            if lhsArray.count == rhsArray.count {
                for lhsComponent in lhsArray {
                    if !contains(rhsArray, lhsComponent){
                        return false
                    }
                }
                
                for rhsComponent in rhsArray {
                    if !contains(lhsArray, rhsComponent) {
                        return false
                    }
                }
            }else{
                return false
            }
            
            return true;
        }else{
            return false
        }
    }else{
        return false
    }
}
