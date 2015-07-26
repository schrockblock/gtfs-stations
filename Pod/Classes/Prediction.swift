//
//  Prediction.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/10/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit

enum Direction: Int {
    case Uptown = 0
    case Downtown = 1
}

class Prediction: NSObject {
    var secondsToArrival: Int? {
        if let arrival = timeOfArrival {
            return Int(arrival.timeIntervalSinceNow)
        }else{
            return nil
        }
    }
    var timeOfArrival: NSDate?
    var direction: Direction?
    var route: Route?
    
    init(time: NSDate?) {
        super.init()
        timeOfArrival = time
    }
}
