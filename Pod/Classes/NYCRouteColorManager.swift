//
//  RouteColorManager.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 7/26/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit
import SubwayStations

open class NYCRouteColorManager: NSObject, RouteColorManager {
   
    @objc open func colorForRouteId(_ routeId: String!) -> UIColor {
        var color: UIColor = UIColor.darkGray
        
        if ["1","2","3"].contains(routeId) {
            color = UIColor(rgba: "#EE352E")
        }
        
        if ["4","5","5X","6","6X"].contains(routeId) {
            color = UIColor(rgba: "#00933C")
        }
        
        if ["7","7X"].contains(routeId) {
            color = UIColor(rgba: "#B933AD")
        }
        
        if ["A","C","E"].contains(routeId) {
            color = UIColor(rgba: "#0039A6")
        }
        
        if ["B","D","F","M"].contains(routeId) {
            color = UIColor(rgba: "#FF6319")
        }
        
        if routeId == "G" {
            color = UIColor(rgba: "#6CBE45")
        }
        
        if routeId == "L" {
            color = UIColor(rgba: "#A7A9AC")
        }
        
        if ["N","Q","R","W"].contains(routeId) {
            color = UIColor(rgba: "#FCCC0A")
        }
        
        if ["J","Z","JZ"].contains(routeId) {
            color = UIColor(rgba: "#996633")
        }
        
        return color
    }
}

extension UIColor {
    @objc public convenience init(rgba: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        if rgba.hasPrefix("#") {
            let index   = rgba.characters.index(rgba.startIndex, offsetBy: 1)
            let hex     = rgba.substring(from: index)
            let scanner = Scanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexInt64(&hexValue) {
                switch (hex.characters.count) {
                case 3:
                    red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                    green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                    blue  = CGFloat(hexValue & 0x00F)              / 15.0
                case 4:
                    red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                    green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                    blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                    alpha = CGFloat(hexValue & 0x000F)             / 15.0
                case 6:
                    red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
                case 8:
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                default:
                    print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8", terminator: "")
                }
            } else {
                print("Scan hex error")
            }
        } else {
            print("Invalid RGB string, missing '#' as prefix", terminator: "")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}
