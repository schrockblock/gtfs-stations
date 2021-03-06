//
//  PredictionSpec.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 7/30/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import GTFSStations
import Quick
import Nimble
import SubwayStations

class PredictionSpec: QuickSpec {
    override func spec() {
        describe("Prediction", { () -> Void in
            
            it("is equal when everything matches") {
                let route = NYCRoute(objectId: "1")
                let time = NSDate()
                
                let first = Prediction(time: time as Date)
                let second = Prediction(time: time as Date)
                
                first.route = route
                first.direction = .downtown
                
                second.route = route
                second.direction = .downtown
                
                expect([first].contains(where: {second == $0})).to(beTruthy())
            }
        })
    }
}
