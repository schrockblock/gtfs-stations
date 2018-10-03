//
//  StationManager.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/13/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit
import SQLite
import SubwayStations

open class NYCStationManager: NSObject, StationManager {
    @objc open var sourceFilePath: String?
    @objc lazy var dbManager: DBManager = {
            let lazyManager = DBManager(sourcePath: self.sourceFilePath)
            return lazyManager
        }()
    open var allStations: [Station] = [Station]()
    open var transferStations: [Station] = [Station]()
    open var routes: [Route] = [Route]()
    @objc open var timeLimitForPredictions: Int32 = 20
    
    @objc public init(sourceFilePath: String?) throws {
        super.init()
        
        if let file = sourceFilePath {
            self.sourceFilePath = file
        }
        
        do {
            var stationIds = Array<String>()
            let parentStops = try dbManager.database.prepare("SELECT stop_name, stop_id, parent_station, stop_lat, stop_lon FROM stops WHERE location_type = 1")
            for stopRow in parentStops {
                let stop = NYCStop(name: stopRow[0] as! String, objectId: stopRow[1] as! String, parentId: stopRow[2] as? String)
                if !stationIds.contains(stop.objectId) {
                    let station = stationForParentStop(stop: stop)
                    stationIds.append(stop.objectId)
                    
                    if !station.stops.isEmpty {
                        if allStations.filter({ ($0 as! NYCStation) == (station as! NYCStation) }).count == 0 {
                            allStations.append(station)
                        }
                    }
                }
            }
            
            transferStations = allStations.filter { $0.stops.count > 1 }
            
            for routeRow in try dbManager.database.prepare("SELECT route_id FROM routes") {
                let route = NYCRoute(objectId: routeRow[0] as! String)
                route.color = NYCRouteColorManager().colorForRouteId(route.objectId)
                routes.append(route)
            }
        }catch _ {
            
        }
    }
    
    open func stationsForSearchString(_ stationName: String!) -> Array<Station>? {
        return allStations.filter({$0.name!.lowercased().range(of: stationName.lowercased()) != nil})
    }
    
    open func predictions(_ station: Station!, time: Date!) -> Array<Prediction>{
        var predictions = Array<Prediction>()
        
        do {
            if let stops = try stopsForStation(station) {
                let timesQuery = "SELECT trip_id, departure_time FROM stop_times WHERE stop_id IN (" + questionMarksForArray(stops)! + ") AND departure_time BETWEEN ? AND ?"
                var stopIds: [Binding?] = stops.map({ (stop: Stop) -> Binding? in
                    stop.objectId as Binding
                })
                stopIds.append(dateToTime(time))
                stopIds.append(dateToTime((time as NSDate!).incrementUnit(NSCalendar.Unit.minute, by: timeLimitForPredictions)))
                let stmt = try dbManager.database.prepare(timesQuery)
                for timeRow in stmt.bind(stopIds) {
                    let tripId = timeRow[0] as! String
                    let depTime = timeRow[1] as! String
                    let prediction = Prediction(time: timeToDate(depTime, referenceDate: time))
                    
                    for tripRow in try dbManager.database.prepare("SELECT direction_id, route_id FROM trips WHERE trip_id = ?", [tripId]) {
                        let direction = tripRow[0] as! Int64
                        let routeId = tripRow[1] as! String
                        prediction.direction = direction == 0 ? Direction.uptown : Direction.downtown
                        let routeArray = routes.filter({$0.objectId == routeId})
                        prediction.route = routeArray[0]
                    }
                    
                    if !predictions.contains(where: {$0 == prediction}) {
                        predictions.append(prediction)
                    }
                }
            }
        }catch _ {
            
        }
        
        return predictions
    }
    
    open func stationsForRoute(_ route: Route) -> Array<Station>? {
        var stations = Array<Station>()
        do {
            let sqlString = "SELECT stops.parent_station,stop_times.stop_sequence FROM stops " +
                "INNER JOIN stop_times ON stop_times.stop_id = stops.stop_id " +
                "INNER JOIN trips ON stop_times.trip_id = trips.trip_id " +
                "WHERE trips.route_id = ? AND trips.direction_id = 0 AND stop_times.departure_time BETWEEN ? AND ? " +
                "GROUP BY stops.parent_station " +
                "ORDER BY stop_times.stop_sequence DESC "
            for stopRow in try dbManager.database.prepare(sqlString, [route.objectId, "10:00:00", "15:00:00"]) {
                let parentId = stopRow[0] as? String
                for station in allStations {
                    var foundOne = false
                    for stop in station.stops {
                        if stop.objectId == parentId {
                            stations.append(station)
                            foundOne = true
                            break
                        }
                    }
                    if foundOne {
                        break
                    }
                }
            }
        }catch _ {
            
        }
        return stations
    }
    
    open func routeIdsForStation(_ station: Station) -> Array<String> {
        var routeIds = Array<String>()
        do {
            if let stops = try stopsForStation(station) {
                let sqlStatementString = "SELECT trips.route_id FROM trips INNER JOIN stop_times ON stop_times.trip_id = trips.trip_id WHERE stop_times.stop_id IN (" + questionMarksForArray(stops)! + ") GROUP BY trips.route_id"
                let sqlStatement = try dbManager.database.prepare(sqlStatementString)
                let stopIds: [Binding?] = stops.map({ (stop: Stop) -> Binding? in
                    stop.objectId as Binding
                })
                for routeRow in sqlStatement.bind(stopIds) {
                    routeIds.append(routeRow[0] as! String)
                }
            }
        }catch _ {
            
        }
        return routeIds
    }
    
    open func stopsNearby(station: Station) -> [String] {
        var stopIds = [String]()
        let childStopIds = self.childStopIds(for: station)
        let stopTimes = Table("stop_times")
        let sequenceExp = Expression<Int64>("stop_sequence")
        let stopIdExp = Expression<String>("stop_id")
        let tripIdExp = Expression<String>("trip_id")
        let filteredStopTimes = stopTimes.select(sequenceExp, tripIdExp).filter(childStopIds.contains(stopIdExp)).group(tripIdExp)
        var tripStopIds = [String]()
        do {
            for stopTime in try dbManager.database.prepare(filteredStopTimes) {
                let sequence = stopTime[sequenceExp]
                var sequences = [Int64]()
                if sequence > 2 { sequences.append(sequence - 2) }
                if sequence > 1 { sequences.append(sequence - 1) }
                sequences.append(sequence + 1)
                sequences.append(sequence + 2)
                let nearbyIdsStatement = stopTimes.filter(tripIdExp == stopTime[tripIdExp] && sequences.contains(sequenceExp))
                let nearbyIdResults = try dbManager.database.prepare(nearbyIdsStatement)
                let nearbyIds = nearbyIdResults.map({ String($0[stopIdExp].prefix($0[stopIdExp].count - 1)) })
                tripStopIds.append(contentsOf: nearbyIds)
            }
            for stopId in Array(Set(tripStopIds)) {
                stopIds.append(contentsOf: transferIds(for: stopId))
            }
        } catch {
            print(error)
        }
        return Array(Set(stopIds))
    }
    
    open func numberOfStopsBetween(_ station: Station, _ stopId: String, _ routeId: String, _ directionId: Int64) -> Int64 {
        let otherStation = stationForParentStop(stop: NYCStop(name: "", objectId: stopId, parentId: nil))
        let stopTimes = Table("stop_times")
        let trips = Table("trips")
        let sequenceExp = Expression<Int64>("stop_sequence")
        let directionIdExp = Expression<Int64>("direction_id")
        let tripIdExp = Expression<String>("trip_id")
        let stopIdExp = Expression<String>("stop_id")
        let routeIdExp = Expression<String>("route_id")
        
        let stationChildren = childStopIds(for: station)
        let otherChildren = childStopIds(for: otherStation)
        
        let timesJoinTrips = stopTimes.join(trips, on: stopTimes[tripIdExp] == trips[tripIdExp])
        let otherStopTimesStatement = timesJoinTrips.filter(routeId == routeIdExp && directionId == directionIdExp && otherChildren.contains(stopIdExp)).limit(1)
        let stationStopTimesStatement = timesJoinTrips.filter(routeId == routeIdExp && directionId == directionIdExp && stationChildren.contains(stopIdExp)).limit(1)
        do {
            let otherStopTimes = try dbManager.database.prepare(otherStopTimesStatement)
            let stationStopTimes = try dbManager.database.prepare(stationStopTimesStatement)
            for stationTime in stationStopTimes {
                for otherTime in otherStopTimes {
                    return stationTime[sequenceExp] as Int64 - otherTime[sequenceExp] as Int64
                }
            }
        } catch {
            print(error)
        }
        return -1
    }
    
    func childStopIds(for station: Station) -> [String] {
        var ids = [String]()
        for stop in station.stops {
            ids.append("\(stop.objectId!)N")
            ids.append("\(stop.objectId!)S")
        }
        return ids
    }
    
    func transferIds(for stopId: String) -> [String]  {
        let transfers = Table("transfer")
        let fromId = Expression<String>("from_id")
        let toId = Expression<String>("to_id")
        let statement = transfers.filter(fromId == stopId)
        do {
            return try dbManager.database.prepare(statement).map({ $0[toId] })
        } catch {
            return [String]()
        }
    }
    
    func stationForParentStop(stop: Stop) -> Station {
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
    
    @objc func stopBetweenQueryPartial(column: String, coordinate: Double) -> String {
        var partial = " AND " + column + " < " + String(coordinate + 0.005)
        partial += " AND " + column + " > " + String(coordinate - 0.005)
        return partial
    }
    
    @objc func dateToTime(_ time: Date!) -> String{
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: time)
    }
    
    @objc func timeToDate(_ time: String!, referenceDate: Date!) -> Date?{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-DD "
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-DD HH:mm:ss"
        let timeString = dateFormatter.string(from: referenceDate) + time
        return formatter.date(from: timeString)
    }
    
    @objc func questionMarksForArray(_ array: Array<Any>?) -> String?{
        var qMarks: String = "?"
        if let stops = array {
            if stops.count > 1 {
                for _ in stops {
                    qMarks = qMarks + ",?"
                }
                let index = qMarks.characters.index(qMarks.endIndex, offsetBy: -2)
                qMarks = qMarks.substring(to: index)
            }
        }else{
            return nil
        }
        return qMarks
    }
    
    @objc func queryForNameArray(_ array: Array<String>?) -> String? {
        var query = ""
        if let nameArray = array {
            for nameComponent in nameArray {
                query += " AND stop_name LIKE '%\(nameComponent)%'"
            }
        }else{
            return nil
        }
        return query
    }
    
    func stopsForStation(_ station: Station) throws -> Array<Stop>? {
        var stops = Array<Stop>()
        for parent in station.stops {
            do {
                for relevantStop in try dbManager.database.prepare("SELECT stop_name, stop_id FROM stops WHERE parent_station = ?", [parent.objectId]){
                    stops.append(NYCStop(name: relevantStop[0] as! String, objectId: relevantStop[1] as! String, parentId: parent.objectId))
                }
            }catch _ {
                
            }
        }
        if stops.count == 0 {
            return nil
        }else{
            return stops
        }
    }
}
