//
//  NavigatorSpec.swift
//  GTFS StationsTests
//
//  Created by Elliot Schrock on 1/30/19.
//  Copyright © 2019 Elliot Schrock. All rights reserved.
//

import GTFSStations
import Quick
import Nimble
import SubwayStations

class NavigatorSpec: QuickSpec {
    override func spec() {
        describe("Navigator", { () -> Void in
            do {
                let nav: NYCNavigator = NYCNavigator()
                
                let path = Bundle.main.path(forResource: "gtfs", ofType: "db")
                let stationManager: NYCStationManager! = try NYCStationManager(sourceFilePath: path)
                var allStations: Array<Station>?
                
                beforeSuite {
                    allStations = stationManager.allStations
                    nav.transferStations = stationManager.transferStations
                }
                
                it("can find route between stops on same line") {
                    if let first = allStations?.first, let second = allStations?[2] {
                        let (stations, trips) = nav.getStationsAndTripsBetween(first, second, nil)
                        expect(stations.count).to(beTruthy())
                        expect(trips.count).to(beTruthy())
                    } else {
                        expect(true).to(beFalse())
                    }
                }
                
                it("can find route between stops on different lines") {
                    if let first = allStations?.first, let second = stationManager.stationsForSearchString("163")?.first {
                        let (stations, trips) = nav.getStationsAndTripsBetween(first, second, nil)
                        expect(stations.count).to(beTruthy())
                        expect(trips.count).to(beTruthy())
                    } else {
                        expect(true).to(beFalse())
                    }
                }
                
                it("can find shortest route between stops on different lines") {
                    if let first = allStations?.first, let second = stationManager.stationsForSearchString("163")?.first {
                        let (stations, trips) = nav.getStationsAndTripsBetween(first, second, nil)
                        expect(stations.count).to(equal(12))
                        expect(trips.count).to(equal(2))
                    } else {
                        expect(true).to(beFalse())
                    }
                }
            } catch {
                expect(true).to(beFalse())
            }
        })
    }
}
