//
//  Prediction.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/10/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit

enum Direction {
    case Uptown
    case Downtown
    case Eastbound
    case Westbound
}

class Prediction: NSObject {
    var secondsToArrival: Int?
    var timeOfArrival: NSDate?
    var direction: Direction?
    var route: Route?
}
