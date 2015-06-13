//
//  StationManagerSpec.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/13/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import GTFS_Stations
import Quick
import Nimble

class StationManagerSpec: QuickSpec {
    override func spec() {
        describe("StationManager", { () -> Void in
            let stationManager: StationManager! = StationManager()
            var allStations: Array<Station>?
            
            beforeSuite {
                allStations = stationManager.allStations()
            }
            
            it("can find stations based on name") {
                let searchedStations: Array<Station>? = stationManager.stationsForSearchString("col")
                expect(searchedStations).toNot(beNil())
                if let stations = searchedStations {
                    expect(stations.count).to(beTruthy())
                    var hasColumbusCircle: Bool = false
                    for station in stations {
                        if let name = station.name {
                            if (name.hasPrefix("Columbus Circle")) {
                                hasColumbusCircle = true
                            }
                        }
                    }
                    expect(hasColumbusCircle).to(beTruthy())
                }
            }
            
            it("returns all stations") {
                expect(allStations).toNot(beNil())
                if let stations = allStations {
                    expect(stations.count > 400).to(beTruthy())
                }
            }
            
            it("has stations which all have names") {
                if let stations = allStations {
                    for station in stations {
                        expect(station.name).toNot(beNil())
                    }
                }
            }
            
            it("has stations which all have predictions") {
                if let stations = allStations {
                    for station in stations {
                        var stationPredictions: Array<Prediction>? = station.predictionsForTime(NSDate(timeIntervalSince1970:1434217843))
                        expect(stationPredictions).toNot(beNil())
                        if let predictions = stationPredictions {
                            expect(predictions.count).toNot(beTruthy())
                            if predictions.count != 0 {
                                let prediction: Prediction = predictions[0]
                                expect(prediction.timeOfArrival).toNot(beNil())
                                expect(prediction.secondsToArrival).toNot(beNil())
                                expect(prediction.secondsToArrival > 0).to(beTruthy())
                                expect(prediction.direction).toNot(beNil())
                                expect(prediction.route).toNot(beNil())
                                if let route = prediction.route {
                                    expect(route.color).toNot(beNil())
                                    expect(route.identifier).toNot(beNil())
                                }
                            }
                        }
                    }
                }
            }
        })
    }
}
