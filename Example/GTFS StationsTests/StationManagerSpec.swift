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
import SubwayStations

class StationManagerSpec: QuickSpec {
    override func spec() {
        describe("StationManager", { () -> Void in
            do {
                let path = Bundle.main.path(forResource: "gtfs", ofType: "db")
                let stationManager: NYCStationManager! = try NYCStationManager(sourceFilePath: path)
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
                                if (name.hasPrefix("59 St")) {
                                    hasColumbusCircle = true
                                }
                            }
                        }
                        expect(hasColumbusCircle).to(beTruthy())
                    }
                }
                
                it("returns route ids for a station") {
                    do {
                        let firstStation = allStations?.first
                        expect(firstStation).notTo(beNil())
                        if let station = firstStation {
                            let routeIds = try stationManager.routeIdsForStation(station)
                            expect(routeIds.count).notTo(equal(0))
                        }
                    }catch {
                        expect(true).to(beFalse())
                    }
                }
                
                it("returns all stations") {
                    expect(allStations).toNot(beNil())
                    if let stations = allStations {
                        expect(stations.count > 350).to(beTruthy())
                    }
                }
                
                it("returns all stations for a route") {
                    let route = NYCRoute(objectId: "A")
                    let stations = stationManager.stationsForRoute(route)
                    expect(stations).toNot(beNil())
                    if let theStations = stations {
                        expect(theStations.count > 0).to(beTruthy())
                        expect(theStations.first?.name).to(equal("Inwood - 207 St"))
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
                    do {
                        if let stations = allStations {
                            for station in stations {
                                let date = NSDate(timeIntervalSince1970:1434217843)
                                let stationPredictions: Array<Prediction>? = try stationManager.predictions(station, time: date as Date!)
                                expect(stationPredictions).toNot(beNil())
                                if let predictions = stationPredictions {
                                    expect(predictions.count > 0).to(beTruthy())
                                    if predictions.count != 0 {
                                        let prediction: Prediction = predictions[0]
                                        expect(prediction.timeOfArrival).toNot(beNil())
                                        expect(prediction.secondsToArrival).toNot(beNil())
                                        expect((prediction.timeOfArrival as NSDate?)?.timeIntervalSince(date as Date)).to(beLessThan(20 * 60))
                                        expect(prediction.direction).toNot(beNil())
                                        expect(prediction.route).toNot(beNil())
                                        if let route = prediction.route {
                                            expect(route.color).toNot(beNil())
                                            expect(route.objectId).toNot(beNil())
                                        }
                                    }
                                }
                            }
                        }else{
                            expect(false).to(beTruthy())
                        }
                        
                    }catch{
                        expect(true).to(beFalse())
                    }
                }
            } catch {
                expect(true).to(beFalse())
            }
        })
    }
}
