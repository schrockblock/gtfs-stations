//
//  StationManagerSpec.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/13/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import GTFSStations
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
                    let firstStation = allStations?.first
                    expect(firstStation).notTo(beNil())
                    if let station = firstStation {
                        let routeIds = stationManager.routeIdsForStation(station)
                        expect(routeIds.count).notTo(equal(0))
                    }
                }
                
                it("returns all stations") {
                    expect(allStations).toNot(beNil())
                    if let stations = allStations {
                        expect(stations.count).to(beGreaterThan(350))
                    }
                }
                
                it("includes Central Park North") {
                    expect(allStations).toNot(beNil())
                    if let stations = allStations {
                        expect(stations.filter { $0.name.contains("Central Park North")}.count).to(beGreaterThan(0))
                    }
                }
                
                it("includes 135 on the 2/3") {
                    expect(allStations).toNot(beNil())
                    
                    if let stations = allStations {
                        expect(stations.filter { $0.name.contains("135")}.count).to(beGreaterThan(1))
                    }
                }
                
                it("returns all transfer stations") {
                    expect(stationManager.transferStations.count).to(beLessThan(stationManager.allStations.count))
                }
                
                it("has 168 as a transfer") {
                    if let station = stationManager.stationsForSearchString("168")?.first {
                        expect(stationManager.transferStations.filter { $0.name == station.name }.count).to(equal(1))
                    }
                }
                
                it("has Pennsylvania not as a transfer") {
                    if let station = stationManager.stationsForSearchString("Pennsylvania")?.first {
                        expect(stationManager.transferStations.filter { $0.name == station.name }.count).to(equal(0))
                    }
                }
                
                it("gives C for 163 routes") {
                    if let station = stationManager.stationsForSearchString("163")?.first {
                        expect(stationManager.routeIdsForStation(station).count).to(equal(2))
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
                                if let stationName = station.name, stationName != "Broad Channel" && stationName != "S.B. Coney Island" && stationName != "Atlantic" && stationName != "Nassau" {
                                    let date = NSDate(timeIntervalSince1970:1434217843)
                                    let stationPredictions: Array<Prediction>? = stationManager.predictions(station, time: date as Date)
                                    expect(stationPredictions).toNot(beNil())
                                    if let predictions = stationPredictions {
                                        if predictions.count == 0 {
                                            print(stationName)
                                        }
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
