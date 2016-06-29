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
import SubwayStations

class StationSpec: QuickSpec {
    override func spec() {
        describe("Station", { () -> Void in
            
            it("is equal when names match") {
                let firstStation = NYCStation(name: "Union")
                let secondStation = NYCStation(name: "union")
                
                expect(firstStation == secondStation).to(beTruthy())
            }
            
            it("is equal when names are word permutations of eachother") {
                let firstStation = NYCStation(name: "14th Union")
                let secondStation = NYCStation(name: "union 14th")
                
                expect(firstStation == secondStation).to(beTruthy())
            }
            
            it("is not equal when names are not word permutations of eachother") {
                let firstStation = NYCStation(name: "Union Sq")
                let secondStation = NYCStation(name: "union 14th")
                
                expect(firstStation == secondStation).to(beFalsy())
            }
        })
    }
}
