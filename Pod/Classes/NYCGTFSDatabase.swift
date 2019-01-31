//
//  NYCGTFSDatabase.swift
//  GTFSStations
//
//  Created by Elliot Schrock on 1/30/19.
//

import SubwayStations
import SQLite

open class NYCGTFSDatabase {
    @objc open var sourceFilePath: String?
    @objc lazy var dbManager: DBManager = {
        let lazyManager = DBManager(sourcePath: self.sourceFilePath)
        return lazyManager
    }()
    
    public init() {}
    
    open func tripsThroughStops(_ stopIds: [String], _ startTime: String, _ endTime: String) -> [Trip] {
        let trips = Table("trips")
        let stopTimes = Table("stop_times")
        let tripIdExp = Expression<String>("trip_id")
        let routeIdExp = Expression<String>("route_id")
        let stopIdExp = Expression<String>("stop_id")
        let departureTimeExp = Expression<String>("departure_time")
        
        let statement = trips
            .join(.inner, stopTimes, on: stopTimes[tripIdExp] == trips[tripIdExp])
            .filter(stopIds.contains(stopIdExp) && startTime...endTime ~= departureTimeExp)
            .group(routeIdExp)
        
        var tripResults = [Trip]()
        do {
            tripResults = try dbManager.database.prepare(statement).map({ (row) -> Trip in
                let trip = NYCTrip()
                trip.objectId = row[trips[tripIdExp]]
                trip.routeId = row[routeIdExp]
                return trip
            })
        } catch {
            print(error)
        }
        return tripResults
    }
    
    open func tripsAlsoThroughStops(_ tripIds: [String], _ stopIds: [String]) -> [Trip] {
        let trips = Table("trips")
        let stopTimes = Table("stop_times")
        let tripIdExp = Expression<String>("trip_id")
        let routeIdExp = Expression<String>("route_id")
        let stopIdExp = Expression<String>("stop_id")
        
        let statement = trips
            .join(.inner, stopTimes, on: stopTimes[tripIdExp] == trips[tripIdExp])
            .filter(stopIds.contains(stopIdExp) && tripIds.contains(trips[tripIdExp]))
            .group(routeIdExp)
        
        var tripResults = [Trip]()
        do {
            tripResults = try dbManager.database.prepare(statement).map({ (row) -> Trip in
                let trip = NYCTrip()
                trip.objectId = row[trips[tripIdExp]]
                trip.routeId = row[routeIdExp]
                return trip
            })
        } catch {
            print(error)
        }
        return tripResults
    }
    
    open func stopsForIds(_ stopIds: [String]) -> [NYCStop] {
        let stops = Table("stops")
        let stopIdExp = Expression<String>("stop_id")
        let stopNameExp = Expression<String>("stop_name")
        let parentIdExp = Expression<String>("parent_station")
        
        let statement = stops.filter(stopIds.contains(stopIdExp))
        
        var stopResults = [NYCStop]()
        do {
            stopResults = try dbManager.database.prepare(statement).map({ (row) -> NYCStop in
                return NYCStop(name: row[stopNameExp], objectId: row[stopIdExp], parentId: row[parentIdExp])
            })
        } catch {
            print(error)
        }
        return stopResults
    }
    
    open func stopTimesForTrip(_ tripId: String) -> [StopTime] {
        let stopTimes = Table("stop_times")
        let sequenceExp = Expression<Int64>("stop_sequence")
        let tripIdExp = Expression<String>("trip_id")
        let stopIdExp = Expression<String>("stop_id")
        
        let statement = stopTimes.filter(tripId == tripIdExp)
        
        var stopTimeResults = [StopTime]()
        do {
            stopTimeResults = try dbManager.database.prepare(statement).map({ (row) -> StopTime in
                let stopTime = NYCStopTime()
                stopTime.stopId = row[stopIdExp]
                stopTime.stopSequence = row[sequenceExp]
                return stopTime
            })
        } catch {
            print(error)
        }
        return stopTimeResults
    }
    
    open func stationForStopId(_ stopId: String) -> Station {
        let subStop = stopsForIds([stopId]).first!
        return stationForParentStopId(subStop.parentId!)
    }
    
    open func stationForParentStopId(_ stopId: String) -> Station {
        let parentStop = stopsForIds([stopId]).first!
        return stationForParentStop(parentStop)
    }
    
    open func stationForParentStop(_ stop: Stop) -> Station {
        let station = NYCStation(name: stop.name)
        station.primaryId = stop.objectId
        do {
            let idStmt = "SELECT from_id, to_id FROM transfer WHERE from_id = '\(stop.objectId!)'"
            var ids = [Binding?]()
            for row in try dbManager.database.prepare(idStmt) {
                ids.append(row[1])
            }
            
            let statement = "SELECT stop_name, stop_id, parent_station FROM stops WHERE stop_id IN ( \(questionMarksForArray(ids)!) )"
            let sql = try dbManager.database.prepare(statement)
            let stops = sql.bind(ids).map { NYCStop(name: $0[0] as! String, objectId: $0[1] as! String, parentId: $0[2] as? String) }
            if stops.count == 0 {
                station.stops = [stop]
            } else {
                station.stops = stops
            }
        } catch _ {
            
        }
        return station
    }
    
    @objc func questionMarksForArray(_ array: Array<Any>?) -> String?{
        var qMarks: String = "?"
        if let stops = array {
            if stops.count > 1 {
                for _ in stops {
                    qMarks = qMarks + ",?"
                }
                let index = qMarks.index(qMarks.endIndex, offsetBy: -2)
                qMarks = qMarks.substring(to: index)
            }
        }else{
            return nil
        }
        return qMarks
    }
    
    func childStopIdsForStation(_ station: Station) -> [String] {
        var ids = [String]()
        ids.append(contentsOf: station.stops.map { $0.objectId + "N" })
        ids.append(contentsOf: station.stops.map { $0.objectId + "S" })
        return ids
    }
    
    func dateToTime(_ time: Date) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: time)
    }
}
