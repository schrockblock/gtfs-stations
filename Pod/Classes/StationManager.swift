//
//  StationManager.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/13/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit

class StationManager: NSObject {
    var filename = "gtfs.db"
    lazy var dbManager: DBManager = {
            let lazyManager = DBManager(filename: self.filename)
            return lazyManager
        }()
    var allStations: Array<Station> = Array<Station>()
    var routes: Array<Route> = Array<Route>()
    var timeLimitForPredictions: Int32 = 20
    
    override init() {
        super.init()
        
        dbManager.database.open()
        
        let stopsQuery = "SELECT * FROM stops"
        var results: FMResultSet? = dbManager.database.executeQuery(stopsQuery, withArgumentsInArray: [])
        if let stopsResults = results {
            while stopsResults.next() {
                let stop = Stop(name: stopsResults.stringForColumn("stop_name"), objectId: stopsResults.stringForColumn("stop_id"), parentId: stopsResults.stringForColumn("parent_station"))
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
        }
        
        let routesQuery = "SELECT * FROM routes"
        results = dbManager.database.executeQuery(routesQuery, withArgumentsInArray: [])
        if let routesResults = results {
            while routesResults.next() {
                let route = Route(objectId: routesResults.stringForColumn("route_id"))
                route.color = RouteColorManager.colorForRouteId(route.objectId)
                routes.append(route)
            }
        }
        
        dbManager.database.close()
    }
    
    func stationsForSearchString(stationName: String!) -> Array<Station>? {
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
    
    func predictions(station: Station!, time: NSDate!) -> Array<Prediction>{
        var predictions = Array<Prediction>()
        
        dbManager.database.open()
        
        let timesQuery = "SELECT * FROM stop_times WHERE stop_id IN (" + questionMarksForStopArray(station.stops)! + ") AND departure_time BETWEEN ? AND ?"
        var stopIds = station.stops.map({ (stop: Stop) -> String in
            stop.objectId
        })
        stopIds.append(dateToTime(time))
        stopIds.append(dateToTime(time.incrementUnit(NSCalendarUnit.CalendarUnitMinute, by: timeLimitForPredictions)))
        var arguments = stopIds
        let results: FMResultSet? = dbManager.database.executeQuery(timesQuery, withArgumentsInArray: arguments)
        if let timeResults = results {
            while timeResults.next() {
                let tripId = timeResults.stringForColumn("trip_id")
                let depTime = timeResults.stringForColumn("departure_time")
                var prediction = Prediction(time: timeToDate(depTime, referenceDate: time))
                
                let tripsQuery = "SELECT * FROM trips WHERE trip_id = ?"
                let tripsSet = dbManager.database.executeQuery(tripsQuery, withArgumentsInArray: [tripId])
                if let tripsResults = tripsSet {
                    while tripsResults.next() {
                        let direction = tripsResults.intForColumn("direction_id")
                        let routeId = tripsResults.stringForColumn("route_id")
                        prediction.direction = direction == 0 ? .Uptown : .Downtown
                        let routeArray = routes.filter({$0.objectId == routeId})
                        prediction.route = routeArray[0]
                    }
                }
                
                predictions.append(prediction)
            }
        }
        
        dbManager.database.close()
        
        return predictions
    }
}
