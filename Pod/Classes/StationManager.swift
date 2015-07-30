//
//  StationManager.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/13/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit
import SQLite

public class StationManager: NSObject {
    public var filename = "gtfs.db"
    lazy var dbManager: DBManager = {
            let lazyManager = DBManager(filename: self.filename)
            return lazyManager
        }()
    public var allStations: Array<Station> = Array<Station>()
    public var routes: Array<Route> = Array<Route>()
    public var timeLimitForPredictions: Int32 = 20
    
    public init(filename: String?) {
        super.init()
        
        if let file = filename {
            self.filename = file
        }
        
        for stopRow in dbManager.database.prepare("SELECT stop_name, stop_id, parent_station FROM stops") {
            let stop = Stop(name: stopRow[0] as! String, objectId: stopRow[1] as! String, parentId: stopRow[2] as? String)
            if stop.parentId != "" {
                var station: Station = Station(objectId: stop.parentId)
                if contains(allStations, station) {
                    let index = find(allStations, station)
                    if let stationIndex = index {
                        allStations[stationIndex].stops.append(stop)
                    }
                }
            }else{
                var station = Station(objectId: stop.objectId)
                station.name = stop.name
                allStations.append(station)
            }
        }
        
        for routeRow in dbManager.database.prepare("SELECT route_id FROM routes") {
            let route = Route(objectId: routeRow[0] as! String)
            route.color = RouteColorManager.colorForRouteId(route.objectId)
            routes.append(route)
        }
    }
    
    public func stationsForSearchString(stationName: String!) -> Array<Station>? {
        return allStations.filter({$0.name!.lowercaseString.rangeOfString(stationName.lowercaseString) != nil})
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
        var timeString = dateFormatter.stringFromDate(referenceDate) + time
        return formatter.dateFromString(timeString)
    }
    
    func questionMarksForStopArray(array: Array<Stop>?) -> String?{
        var qMarks: String = "?"
        if let stops = array {
            if stops.count > 1 {
                for stop in stops {
                    qMarks = qMarks + ",?"
                }
                var index = advance(qMarks.endIndex, -2)
                qMarks = qMarks.substringToIndex(index)
            }
        }else{
            return nil
        }
        return qMarks
    }
    
    public func predictions(station: Station!, time: NSDate!) -> Array<Prediction>{
        var predictions = Array<Prediction>()
        
        let timesQuery = "SELECT trip_id, departure_time FROM stop_times WHERE stop_id IN (" + questionMarksForStopArray(station.stops)! + ") AND departure_time BETWEEN ? AND ?"
        var stopIds: [Binding?] = station.stops.map({ (stop: Stop) -> Binding? in
            stop.objectId as Binding
        })
        stopIds.append(dateToTime(time))
        stopIds.append(dateToTime(time.incrementUnit(NSCalendarUnit.CalendarUnitMinute, by: timeLimitForPredictions)))
        var arguments = stopIds
        let stmt = dbManager.database.prepare(timesQuery)
        for timeRow in stmt.bind(stopIds) {
            let tripId = timeRow[0] as! String
            let depTime = timeRow[1] as! String
            var prediction = Prediction(time: timeToDate(depTime, referenceDate: time))
            
            for tripRow in dbManager.database.prepare("SELECT direction_id, route_id FROM trips WHERE trip_id = ?", [tripId]) {
                let direction = tripRow[0] as! Int64
                let routeId = tripRow[1] as! String
                prediction.direction = direction == 0 ? .Uptown : .Downtown
                let routeArray = routes.filter({$0.objectId == routeId})
                prediction.route = routeArray[0]
            }
            
            predictions.append(prediction)
        }
        
        return predictions
    }
}
