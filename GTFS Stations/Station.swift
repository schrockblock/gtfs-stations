//
//  Station.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/10/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit

class Station: NSObject {
    var name: String?
    
    func predictionsForTime(time: NSDate!) -> Array<Prediction>? {
        return nil
    }
}
