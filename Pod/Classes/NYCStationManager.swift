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

public class NYCStationManager: NSObject, StationManager {
    public var sourceFilePath: String?
    lazy var dbManager: DBManager = {
            let lazyManager = DBManager(sourcePath: self.sourceFilePath)
            return lazyManager
        }()
    public var allStations: Array<Station> = Array<Station>()
    public var routes: Array<Route> = Array<Route>()
    public var timeLimitForPredictions: Int32 = 20
    
    public init(sourceFilePath: String?) throws {
        super.init()
        
        if let file = sourceFilePath {
            self.sourceFilePath = file
        }
        
        do {
            var stationIds = Array<String>()
            for stopRow in try dbManager.database.prepare("SELECT stop_name, stop_id, parent_station FROM stops WHERE location_type = 1") {
                let stop = NYCStop(name: stopRow[0] as! String, objectId: stopRow[1] as! String, parentId: stopRow[2] as? String)
                if !stationIds.contains(stop.objectId) {
                    let station = NYCStation(name: stop.name)
                    station.stops.append(stop)
                    stationIds.append(stop.objectId)
                    let stationName = station.name.stringByReplacingOccurrencesOfString("'s", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
                    if let queryForName = queryForNameArray(stationName.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())) {
                        for parentRow in try dbManager.database.prepare("SELECT stop_name, stop_id, parent_station FROM stops WHERE location_type = 1" + queryForName) {
                            let parent = NYCStop(name: parentRow[0] as! String, objectId: parentRow[1] as! String, parentId: parentRow[2] as? String)
                            if station == NYCStation(name: parent.name) {
                                station.stops.append(parent)
                                stationIds.append(parent.objectId)
                            }
                        }
                    }
                    
                    allStations.append(station)
                }
            }
            
            for routeRow in try dbManager.database.prepare("SELECT route_id FROM routes") {
                let route = NYCRoute(objectId: routeRow[0] as! String)
                route.color = NYCRouteColorManager.colorForRouteId(route.objectId)
                routes.append(route)
            }
        }catch _ {
            
        }
    }
    
    public func stationsForSearchString(stationName: String!) -> Array<Station>? {
        return allStations.filter({$0.name!.lowercaseString.rangeOfString(stationName.lowercaseString) != nil})
    }
    
    public func predictions(station: Station!, time: NSDate!) throws -> Array<Prediction>{
        var predictions = Array<Prediction>()
        
        if let stops = try stopsForStation(station) {
            let timesQuery = "SELECT trip_id, departure_time FROM stop_times WHERE stop_id IN (" + questionMarksForStopArray(stops)! + ") AND departure_time BETWEEN ? AND ?"
            var stopIds: [Binding?] = stops.map({ (stop: Stop) -> Binding? in
                stop.objectId as Binding
            })
            stopIds.append(dateToTime(time))
            stopIds.append(dateToTime(time.incrementUnit(NSCalendarUnit.Minute, by: timeLimitForPredictions)))
            let stmt = try dbManager.database.prepare(timesQuery)
            for timeRow in stmt.bind(stopIds) {
                let tripId = timeRow[0] as! String
                let depTime = timeRow[1] as! String
                let prediction = Prediction(time: timeToDate(depTime, referenceDate: time))
                
                for tripRow in try dbManager.database.prepare("SELECT direction_id, route_id FROM trips WHERE trip_id = ?", [tripId]) {
                    let direction = tripRow[0] as! Int64
                    let routeId = tripRow[1] as! String
                    prediction.direction = direction == 0 ? .Uptown : .Downtown
                    let routeArray = routes.filter({$0.objectId == routeId})
                    prediction.route = routeArray[0]
                }
                
                if !predictions.contains(prediction) {
                    predictions.append(prediction)
                }
            }
        }
        
        return predictions
    }
    
    public func routeIdsForStation(station: Station) throws -> Array<String> {
        var routeIds = Array<String>()
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
        return routeIds
    }
    
    func dateToTime(time: NSDate!) -> String{
        let formatter: NSDateFormatter = NSDateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.stringFromDate(time)
    }
    
    func timeToDate(time: String!, referenceDate: NSDate!) -> NSDate?{
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-DD "
        let formatter: NSDateFormatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-MM-DD HH:mm:ss"
        let timeString = dateFormatter.stringFromDate(referenceDate) + time
        return formatter.dateFromString(timeString)
    }
    
    func questionMarksForStopArray(array: Array<Stop>?) -> String?{
        var qMarks: String = "?"
        if let stops = array {
            if stops.count > 1 {
                for _ in stops {
                    qMarks = qMarks + ",?"
                }
                let index = qMarks.endIndex.advancedBy(-2)
                qMarks = qMarks.substringToIndex(index)
            }
        }else{
            return nil
        }
        return qMarks
    }
    
    func queryForNameArray(array: Array<String>?) -> String? {
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
    
    func stopsForStation(station: Station) throws -> Array<Stop>? {
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
    
    public func predictions(station: Station!, time: NSDate!) -> Array<Prediction> {
        var predictions = Array<Prediction>()
        
        do {
            if let stops = try stopsForStation(station) {
                let timesQuery = "SELECT trip_id, departure_time FROM stop_times WHERE stop_id IN (" + questionMarksForStopArray(stops)! + ") AND departure_time BETWEEN ? AND ?"
                var stopIds: [Binding?] = stops.map({ (stop: Stop) -> Binding? in
                    stop.objectId as Binding
                })
                stopIds.append(dateToTime(time))
                stopIds.append(dateToTime(time.incrementUnit(NSCalendarUnit.Minute, by: timeLimitForPredictions)))
                var arguments = stopIds
                
                let stmt = try dbManager.database.prepare(timesQuery)
                for timeRow in stmt.bind(stopIds) {
                    let tripId = timeRow[0] as! String
                    let depTime = timeRow[1] as! String
                    var prediction = Prediction(time: timeToDate(depTime, referenceDate: time))
                    
                    for tripRow in try dbManager.database.prepare("SELECT direction_id, route_id FROM trips WHERE trip_id = ?", [tripId]) {
                        let direction = tripRow[0] as! Int64
                        let routeId = tripRow[1] as! String
                        prediction.direction = direction == 0 ? .Uptown : .Downtown
                        let routeArray = routes.filter({$0.objectId == routeId})
                        prediction.route = routeArray[0]
                    }
                    
                    if !predictions.contains({ $0 == prediction }) {
                        predictions.append(prediction)
                    }
                }
            }
        }catch _ {
            
        }
    
        return predictions
    }
}
