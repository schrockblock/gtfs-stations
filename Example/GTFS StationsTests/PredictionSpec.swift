//
//  PredictionSpec.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 7/30/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import GTFS_Stations
import Quick
import Nimble
import SubwayStations

class PredictionSpec: QuickSpec {
    override func spec() {
        describe("Prediction", { () -> Void in
            
            it("is equal when everything matches") {
                let route = NYCRoute(objectId: "1")
                let time = NSDate()
                
                let first = Prediction(time: time)
                let second = Prediction(time: time)
                
                first.route = route
                first.direction = .Downtown
                
                second.route = route
                second.direction = .Downtown
                
                expect([first].contains({second == $0})).to(beTruthy())
            }
        })
    }
}
