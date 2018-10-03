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
                let primaryId: String = stop.objectId
                let ids = [ "\(primaryId)N", "\(primaryId)S" ]
                station.stops = ids.map { NYCStop(name: "", objectId: $0, parentId: primaryId) }
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
