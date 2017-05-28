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
    open var sourceFilePath: String?
    lazy var dbManager: DBManager = {
            let lazyManager = DBManager(sourcePath: self.sourceFilePath)
            return lazyManager
        }()
    open var allStations: Array<Station> = Array<Station>()
    open var routes: Array<Route> = Array<Route>()
    open var timeLimitForPredictions: Int32 = 20
    
    public init(sourceFilePath: String?) throws {
        super.init()
        
        if let file = sourceFilePath {
            self.sourceFilePath = file
        }
        
        do {
            var stationIds = Array<String>()
            for stopRow in try dbManager.database.prepare("SELECT stop_name, stop_id, parent_station, stop_lat, stop_lon FROM stops WHERE location_type = 1") {
                let stop = NYCStop(name: stopRow[0] as! String, objectId: stopRow[1] as! String, parentId: stopRow[2] as? String)
                let stopLat = stopRow[3] as! Double
                let stopLon = stopRow[4] as! Double
                if !stationIds.contains(stop.objectId) {
                    let station = NYCStation(name: stop.name)
                    station.stops.append(stop)
                    stationIds.append(stop.objectId)
                    
                    let partial = stopBetweenQueryPartial(column: "stop_lat", coordinate: stopLat) + stopBetweenQueryPartial(column: "stop_lon", coordinate: stopLon)
                    let rows = try dbManager.database.prepare("SELECT stop_name, stop_id, parent_station FROM stops WHERE location_type = 1" + partial)
                    for parentRow in rows {
                        let parent = NYCStop(name: parentRow[0] as! String, objectId: parentRow[1] as! String, parentId: parentRow[2] as? String)
                        if station == NYCStation(name: parent.name) {
                            station.stops.append(parent)
                            stationIds.append(parent.objectId)
                        }
                    }
                    
                    allStations.append(station)
                }
            }
            
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
                let timesQuery = "SELECT trip_id, departure_time FROM stop_times WHERE stop_id IN (" + questionMarksForStopArray(stops)! + ") AND departure_time BETWEEN ? AND ?"
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
    
    open func routeIdsForStation(_ station: Station) -> Array<String> {
        var routeIds = Array<String>()
        do {
            if let stops = try stopsForStation(station) {
                let sqlStatementString = "SELECT trips.route_id FROM trips INNER JOIN stop_times ON stop_times.trip_id = trips.trip_id WHERE stop_times.stop_id IN (" + questionMarksForStopArray(stops)! + ") GROUP BY trips.route_id"
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
    
    func stopBetweenQueryPartial(column: String, coordinate: Double) -> String {
        var partial = " AND " + column + " < " + String(coordinate + 0.005)
        partial += " AND " + column + " > " + String(coordinate - 0.005)
        return partial
    }
    
    func dateToTime(_ time: Date!) -> String{
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: time)
    }
    
    func timeToDate(_ time: String!, referenceDate: Date!) -> Date?{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-DD "
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-DD HH:mm:ss"
        let timeString = dateFormatter.string(from: referenceDate) + time
        return formatter.date(from: timeString)
    }
    
    func questionMarksForStopArray(_ array: Array<Stop>?) -> String?{
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
    
    func queryForNameArray(_ array: Array<String>?) -> String? {
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
