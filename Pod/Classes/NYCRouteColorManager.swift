//
//  RouteColorManager.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 7/26/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit
import SubwayStations

public class NYCRouteColorManager: NSObject, RouteColorManager {
   
    public class func colorForRouteId(routeId: String!) -> UIColor {
        let color:UIColor = UIColor()
        
        if ["1","2","3"].contains(routeId) {
            
        }
        
        if ["4","5","5X","6"].contains(routeId) {
            
        }
        
        if ["7","7X"].contains(routeId) {
            
        }
        
        if ["A","C","E"].contains(routeId) {
            
        }
        
        if ["B","D","F","M"].contains(routeId) {
            
        }
        
        if ["N","Q","R"].contains(routeId) {
            
        }
        
        return color
    }
}
