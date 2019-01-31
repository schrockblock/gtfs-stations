//
//  GTFSDatabaseSpec.swift
//  GTFS StationsTests
//
//  Created by Elliot Schrock on 1/30/19.
//  Copyright © 2019 Elliot Schrock. All rights reserved.
//

import GTFSStations
import Quick
import Nimble
import SubwayStations

class GTFSDatabaseSpec: QuickSpec {
    override func spec() {
        describe("GTFSDatabase", { () -> Void in
            do {
                let path = Bundle.main.path(forResource: "gtfs", ofType: "db")
                let db: NYCGTFSDatabase! = NYCGTFSDatabase()
                db.sourceFilePath = path
                
                it("can find trips through given stop ids") {
                    let startTimeString = "11:00:00"
                    let endTimeString = "22:00:00"
                    let stopIds = ["A09N", "A09S"]
                    let trips = db.tripsThroughStops(stopIds, startTimeString, endTimeString)
                    expect(trips.isEmpty).to(beFalse())
                }
                
                it("can find trips that also pass through other stops") {
                    let startTimeString = "11:00:00"
                    let endTimeString = "22:00:00"
                    let stopId = "A09N"
                    let tripIds = db.tripsThroughStops([stopId], startTimeString, endTimeString).map { $0.objectId! }
                    let otherStopId = "A12N"
                    let trips = db.tripsAlsoThroughStops(tripIds, [otherStopId])
                    expect(trips.isEmpty).to(beFalse())
                }
                
                it("can find stop times for a trip") {
                    let startTimeString = "11:00:00"
                    let endTimeString = "22:00:00"
                    let stopId = "A09N"
                    let tripIds = db.tripsThroughStops([stopId], startTimeString, endTimeString).map { $0.objectId }
                    if let tripId = tripIds.first as? String {
                        let stopTimes = db.stopTimesForTrip(tripId)
                        expect(stopTimes.isEmpty).to(beFalse())
                    }
                }
            } catch {
                expect(true).to(beFalse())
            }
        })
    }
}
