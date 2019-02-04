//
//  NYCNavigator.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 1/29/19.
//  Copyright © 2019 Elliot Schrock. All rights reserved.
//

import SubwayStations

open class ProgressCallback {}
extension Station {
    func stopsHashCode() -> Int {
        return stops.map { $0.objectId! as String }.sorted().reduce("", +).hash
    }
    
    func containsStopWithId(_ stopId: String) -> Bool {
        return stops.filter { stopId.contains($0.objectId ?? "aaa") }.count > 0
    }
}

open class NYCNavigator {
    public var transferStations: [Station]!
    var db: NYCGTFSDatabase = NYCGTFSDatabase()
    
    public init() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/nav.db"
        db.sourceFilePath = path
    }
    
    open func getStationsAndTripsBetween(_ first: Station, _ second: Station, _ callback: ProgressCallback?) -> ([Station], [Trip]) {
        var attempts = [Int]()
        var successes = [Int: Int]()
        var cache = [Int: [Trip]]()
        return getStationsAndTripsBetween(&attempts, &successes, &cache, first, second, callback)
    }
    
    open func getStationsAndTripsBetween(_ attemptedStations: inout [Int],
                                         _ successStations: inout [Int: Int],
                                         _ tripsCache: inout [Int: [Trip]],
                                         _ first: Station,
                                         _ second: Station,
                                         _ callback: ProgressCallback?) -> ([Station], [Trip]) {
        //        callback.onProgressUpdate("first: " + first.name)
        
        var newAttemptedStations = attemptedStations
        var stationsAndTrips: ([Station], [Trip]) = ([Station](), [Trip]())
        var trips: [Trip] = tripsThrough(first)
        if !attemptedStations.contains(first.stopsHashCode()) {
            newAttemptedStations.append(first.stopsHashCode())
            
            tripsCache[first.stopsHashCode()] = trips
        } else {
            trips = tripsCache[first.stopsHashCode()]!
        }
        
        let stationsToThere = stationsBetween(first, second, trips, callback)
        
        if stationsToThere.1 != nil {
            //            callback.onProgressUpdate("  trip found!")
            return (stationsToThere.0, [stationsToThere.1!])
        }
        
        var relevantTransfers = [String: Station]()
        var tripCenterIndices = [String: Int64]()
        var relevantTrips = [String: [Trip]]()
        var stationsAndTrip: ([Station], Trip?)
        var transferStopTimes = [StopTime]()
        for trip in trips {
            let stopTimes = db.stopTimesForTrip(trip.objectId)
            
            //            callback.onProgressUpdate("times")
            
            // find where `first` is on this trip
            let centerIndex = stopTimes.filter { first.containsStopWithId($0.stopId) }.first!.stopSequence!
            tripCenterIndices[trip.objectId] = centerIndex
            
            // find transfer stations for this trip
            var (_, transferTimes) = relevantTransfersIn(stopTimes, attemptedStations, successStations, &relevantTransfers)
            
            //            callback.onProgressUpdate("transfer filter")
            
            // sort transfers by distance to `first`
            transferTimes.sort { (one, two) -> Bool in
                return abs(one.stopSequence! - centerIndex) < abs(two.stopSequence! - centerIndex)
            }
            
            //            callback.onProgressUpdate("sorted")
            
            // go through transfers and check if second is on that line
            let (relevantStationsAndTrip, sequenceOfTransfer) = stationsBetweenTransferAnd(second, &attemptedStations, &tripsCache, transferTimes, centerIndex, &relevantTrips, relevantTransfers, callback)
            stationsAndTrip = relevantStationsAndTrip
            
            // wrap up if we found something
            if stationsAndTrip.1 != nil {
                successStations[stationsAndTrip.0.first!.stopsHashCode()] = complexity((stationsAndTrip.0, [stationsAndTrip.1!]))
                let total = totalStationsAndTrip(stationsAndTrip, stopTimes, centerIndex, sequenceOfTransfer, callback)
                return (total.0, [trip, total.1])
            } else {
                // else add all the transfers for this trip
                transferStopTimes.append(contentsOf: transferTimes)
            }
        }
        
        for stopTime in transferStopTimes {
            let transfer = relevantTransfers[stopTime.stopId]!
            let candidateStationsAndTrips = getStationsAndTripsBetween(&newAttemptedStations, &successStations, &tripsCache, transfer, second, callback)
            
            if !candidateStationsAndTrips.1.isEmpty {
                var (stations, optTrip) = stationsBetween(first, transfer, trips, callback)
                if let trip = optTrip {
                    stations.append(contentsOf: candidateStationsAndTrips.0)
                    var totalTrips = [Trip]()
                    totalTrips.append(trip)
                    totalTrips.append(contentsOf: candidateStationsAndTrips.1)
                    let totals = (stations, totalTrips)
                    if stationsAndTrips.1.isEmpty {
                        stationsAndTrips = totals
                    } else {
                        let totalComplexity = complexity(totals)
                        let oldComplexity = complexity(stationsAndTrips)
                        if totalComplexity <= oldComplexity {
                            stationsAndTrips = totals
                        }
                    }
                }
            }
        }
        
        return stationsAndTrips
    }
    
    open func complexity(_ stationsAndTrips: ([Station], [Trip])) -> Int {
        return stationsAndTrips.0.count + stationsAndTrips.1.count * 4
    }
    
    open func totalStationsAndTrip(_ stationsAndTrip: ([Station], Trip?),
                                   _ stopTimes: [StopTime],
                                   _ centerIndex: Int64,
                                   _ sequenceOfTransfer: Int64,
                                   _ callback: ProgressCallback?) -> ([Station], Trip) {
        var filteredStopTimes: [StopTime]
        if centerIndex < sequenceOfTransfer {
            filteredStopTimes = stopTimes.filter { (centerIndex...sequenceOfTransfer).contains($0.stopSequence) }
        } else {
            filteredStopTimes = stopTimes.filter { (sequenceOfTransfer...centerIndex).contains($0.stopSequence) }.reversed()
        }
        
        var totalStations = [Station]()
        for stopTime in filteredStopTimes {
            totalStations.append(db.stationForStopId(stopTime.stopId))
        }
        
        //        callback.onProgressUpdate("created stations")
        
        totalStations.append(contentsOf: stationsAndTrip.0)
        
        return (totalStations, stationsAndTrip.1!)
    }
    
    open func relevantTransfersIn(_ stopTimes: [StopTime],
                                  _ attemptedStations: [Int],
                                  _ successStations: [Int: Int],
                                  _ relevantTransfers: inout [String: Station]) -> ([String: Station], [StopTime]) {
        var irrelevantTransfers = transferStations!
        var transferTimes = [StopTime]()
        for stopTime in stopTimes {
            var didAddTransfer = false
            var addedTransfer: Station? = nil
            for transfer in irrelevantTransfers {
                if transfer.containsStopWithId(stopTime.stopId) && (!attemptedStations.contains(transfer.stopsHashCode()) || successStations.keys.contains(transfer.stopsHashCode())) {
                    addedTransfer = transfer
                    relevantTransfers[stopTime.stopId] = transfer
                    break
                }
            }
            if let transfer = addedTransfer {
                irrelevantTransfers = irrelevantTransfers.filter({ ($0 as! NYCStation) != (transfer as! NYCStation) })
                transferTimes.append(stopTime)
            }
        }
        return (relevantTransfers, transferTimes)
    }
    
    open func stationsBetweenTransferAnd(_ second: Station,
                                         _ attemptedStations: inout [Int],
                                         _ tripsCache: inout [Int: [Trip]],
                                         _ transferTimes: [StopTime],
                                         _ centerIndex: Int64,
                                         _ relevantTrips: inout [String: [Trip]],
                                         _ relevantTransfers: [String: Station],
                                         _ callback: ProgressCallback?) -> (([Station], Trip?), Int64) {
        var sequenceOfTransfer: Int64 = -1
        for stopTime in transferTimes {
            // if not first station
            if stopTime.stopSequence != centerIndex {
                // get the station for this stop (which is a transfer)
                let transferStation = relevantTransfers[stopTime.stopId]!
                if !attemptedStations.contains(transferStation.stopsHashCode()) {
                    attemptedStations.append(transferStation.stopsHashCode())
                    //                    callback.onProgressUpdate("  considering ${transferStation.name}")
                    // get the trips through this station (which is a transfer)
                    let transferTrips = tripsThrough(transferStation)
                    tripsCache[transferStation.stopsHashCode()] = transferTrips
                    relevantTrips[stopTime.stopId] = transferTrips
                    //                    callback.onProgressUpdate("  trips")
                    // get the the stations and trip between the transfer station and second
                    let stationsFromTransfer = stationsBetween(transferStation, second, transferTrips, callback)
                    //                    callback.onProgressUpdate("stations")
                    // if we found a trip that links the transfer with second, mark it so
                    if stationsFromTransfer.1 != nil {
                        sequenceOfTransfer = stopTime.stopSequence
                        return (stationsFromTransfer, sequenceOfTransfer)
                    }
                }
            }
        }
        return (([Station](), nil), sequenceOfTransfer)
    }
    
    open func tripsThrough(_ first: Station) -> [Trip] {
        let startTime = "11:00:00" //dateToTime(time)
        //        let minutesInMillis = (60 * 60 * 1000).toLong()
        let endTimeString = "22:00:00" //dateToTime(Date(time.time + minutesInMillis))
        
        let firstStops = db.childStopIdsForStation(first)
        return db.tripsThroughStops(firstStops, startTime, endTimeString)
    }
    
    open func stationsBetween(_ first: Station,
                              _ second: Station,
                              _ trips: [Trip],
                              _ callback: ProgressCallback?) -> ([Station], Trip?) {
        let secondStops = candidateStopIds(first, second)
        if !secondStops.isEmpty {
            let mutualTrips = db.tripsAlsoThroughStops(trips.map { $0.objectId }, secondStops)
            //            callback.onProgressUpdate("  mutual trips")
            if !mutualTrips.isEmpty {
                return stationsBetweenOnTrips(first, second, mutualTrips, callback)
            }
        }
        
        return ([Station](), nil)
    }
    
    open func candidateStopIds(_ first: Station, _ second: Station) -> [String] {
        var stopIds = [String]()
        //        let prefixes = first.stops.map { it.objectId.substring(0,1) }
        let stops = second.stops//.filter { prefixes.contains(it.objectId.substring(0,1)) }
        stopIds.append(contentsOf: stops.map { $0.objectId + "N" })
        stopIds.append(contentsOf: stops.map { $0.objectId + "S" })
        return stopIds
    }
    
    open func stationsBetweenOnTrips(_ first: Station,
                                     _ second: Station,
                                     _ mutualTrips: [Trip],
                                     _ callback: ProgressCallback?) -> ([Station], Trip?) {
        var stationsAndTrip: ([Station], Trip?) = ([Station](), nil)
        for trip in mutualTrips {
            let stopTimes = db.stopTimesForTrip(trip.objectId)
            //            callback.onProgressUpdate(trip.objectId + " stop times")
            
            var shouldReverse = false
            var addedFirst = false
            var stationsCandidate = [Station]()
            for stopTime in stopTimes {
                var station: Station
                if first.containsStopWithId(stopTime.stopId) {
                    station = first
                    addedFirst = true
                } else if second.containsStopWithId(stopTime.stopId) {
                    station = second
                    shouldReverse = !addedFirst
                } else {
                    station = db.stationForStopId(stopTime.stopId)
                }
                
                stationsCandidate.append(station)
            }
            
            if shouldReverse {
                stationsCandidate.reverse()
            }
            
            if let firstIndex = stationsCandidate.firstIndex(where: { ($0 as! NYCStation) == (first as! NYCStation) }), let secondIndex = stationsCandidate.firstIndex(where: { ($0 as! NYCStation) == (second as! NYCStation) }) {
                var filteredStations = stationsCandidate.filter { outerStation -> Bool in return (firstIndex...secondIndex).contains(stationsCandidate.firstIndex(where: { (testStation) -> Bool in
                    return testStation == outerStation
                }) ?? -1) }
                
                if filteredStations.count > 0 && (filteredStations.first as! NYCStation) != (first as! NYCStation) {
                    filteredStations.insert(first, at: 0)
                }
                
                if filteredStations.count < stationsAndTrip.0.count || stationsAndTrip.0.count == 0 {
                    stationsAndTrip = (filteredStations, trip)
                }
            }
        }
        return stationsAndTrip
    }
}
