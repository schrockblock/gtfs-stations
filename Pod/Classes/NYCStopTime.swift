//
//  NYCStopTime.swift
//  GTFSStations
//
//  Created by Elliot Schrock on 1/30/19.
//

import SubwayStations

open class NYCStopTime: NSObject, StopTime {
    public var stopId: String!
    public var tripId: String!
    public var departureTime: String!
    public var stopSequence: Int64!
}
