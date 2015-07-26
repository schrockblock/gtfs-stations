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
                allStations = stationManager.allStations
            }
            
            it("can find stations based on name") {
                let searchedStations: Array<Station>? = stationManager.stationsForSearchString("col")
                expect(searchedStations).toNot(beNil())
                if let stations = searchedStations {
                    expect(stations.count).to(beTruthy())
                    var hasColumbusCircle: Bool = false
                    for station in stations {
                        if let name = station.name {
                            let isColumbus: String = name.hasPrefix("59 St") ? "true" : "false"
                            if (name.hasPrefix("59 St")) {
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
                }else{
                    expect(false).to(beTruthy());
                }
            }
            
            it("has stations which all have predictions") {
                if let stations = allStations {
                    for station in stations {
                        let date = NSDate(timeIntervalSince1970:1434217843)
                        var stationPredictions: Array<Prediction>? = stationManager.predictions(station, time: date)
                        expect(stationPredictions).toNot(beNil())
                        if let predictions = stationPredictions {
                            expect(predictions.count > 0).to(beTruthy())
                            if predictions.count != 0 {
                                let prediction: Prediction = predictions[0]
                                expect(prediction.timeOfArrival).toNot(beNil())
                                expect(prediction.secondsToArrival).toNot(beNil())
                                expect(prediction.timeOfArrival?.timeIntervalSinceDate(date) < 20 * 60).to(beTruthy())
                                expect(prediction.direction).toNot(beNil())
                                expect(prediction.route).toNot(beNil())
                                if let route = prediction.route {
                                    expect(route.color).toNot(beNil())
                                    expect(route.objectId).toNot(beNil())
                                }
                            }else{
                                println(station.name)
                            }
                        }
                    }
                }else{
                    expect(false).to(beTruthy())
                }
            }
        })
    }
}
