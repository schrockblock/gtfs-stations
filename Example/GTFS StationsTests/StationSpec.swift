//
//  StationSpec.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 7/30/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import GTFS_Stations
import Quick
import Nimble

class StationSpec: QuickSpec {
    override func spec() {
        describe("Station", { () -> Void in
            
            it("is equal when names match") {
                var firstStation = Station(name: "Union")
                var secondStation = Station(name: "union")
                
                expect(firstStation == secondStation).to(beTruthy())
            }
            
            it("is equal when names are word permutations of eachother") {
                var firstStation = Station(name: "14th Union")
                var secondStation = Station(name: "union 14th")
                
                expect(firstStation == secondStation).to(beTruthy())
            }
            
            it("is not equal when names are not word permutations of eachother") {
                var firstStation = Station(name: "Union Sq")
                var secondStation = Station(name: "union 14th")
                
                expect(firstStation == secondStation).to(beFalsy())
            }
        })
    }
}
