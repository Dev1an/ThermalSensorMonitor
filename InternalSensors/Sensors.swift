//
//  sensors.swift
//  InternalSensors
//
//  Created by Damiaan Dufaux on 05/09/2023.
//

import Foundation
import CoreFoundation

let temperatureQuery = getQueryFor(page: 0xff00, usage: 5)
let kIOHIDEventTypeTemperature = Int64(15)

func getQueryFor(page: Int32, usage: Int32) -> CFDictionary {
    [
        "PrimaryUsagePage": page,
        "PrimaryUsage": usage
    ] as CFDictionary
}

func getThermalEntries() -> [HIDServiceClient] {
    let system = IOHIDEventSystemClientCreate(kCFAllocatorDefault)
    IOHIDEventSystemClientSetMatching(system, temperatureQuery)
    let matchingServices = IOHIDEventSystemClientCopyServices(system)
    
    let services = matchingServices?.takeRetainedValue() as? Array<HIDServiceClient>
    return services ?? []
}

func createNameDictionary(of entries: [HIDServiceClient]) -> [String: HIDServiceClient] {
    let keyValuePairs = entries.compactMap { client -> (String, HIDServiceClient)? in
        guard let product = client.product else { return nil }
        guard client.temperature != nil else { return nil }
        return (product, client)
    }
    return Dictionary(keyValuePairs) { left, right in left }
}

func getTemperatures(from dictionary: [String: HIDServiceClient]) -> [(String, Double)] {
    dictionary.map { ($0, $1.temperature!) }
}

extension HIDServiceClient {
    var product: String? {
        IOHIDServiceClientCopyProperty(self, "Product" as CFString)?.takeRetainedValue() as? String
    }
    
    var temperature: Double? {
        if let event = IOHIDServiceClientCopyEvent(self, kIOHIDEventTypeTemperature, 0, 0) {
            return IOHIDEventGetFloatValue(event, Int32(kIOHIDEventTypeTemperature << 16))
        } else {
            return nil
        }
    }
}
