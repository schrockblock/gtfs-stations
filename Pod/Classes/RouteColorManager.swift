//
//  RouteColorManager.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 7/26/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit

public class RouteColorManager: NSObject {
   
    public class func colorForRouteId(routeId: String!) -> UIColor {
        var color:UIColor = UIColor()
        
        if contains(["1","2","3"], routeId) {
            
        }
        
        if contains(["4","5","5X","6"], routeId) {
            
        }
        
        if contains(["7","7X"], routeId) {
            
        }
        
        if contains(["A","C","E"], routeId) {
            
        }
        
        if contains(["B","D","F","M"], routeId) {
            
        }
        
        if contains(["N","Q","R"], routeId) {
            
        }
        
        return color
    }
}
