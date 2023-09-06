//
//  ContentView.swift
//  InternalSensors
//
//  Created by Damiaan Dufaux on 05/09/2023.
//

import SwiftUI
import Charts

struct ContentView: View {
    @State private var multiSelection = Set<String>()
    @State private var services = createNameDictionary(of: getThermalEntries())
    @State private var temperatures = [String: [Double]]()
    @State private var uselessKeys = Set<String>()
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    let checker = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            VStack {
                Chart {
                    ForEach(temperatureArray) { entry in
                        LineMark(
                            x: .value("Time", entry.time),
                            y: .value("Temperature", entry.value),
                            series: .value("Sensor", entry.sensor)
                        ).foregroundStyle(by: .value("Sensor", entry.sensor))
                    }
                }
                .chartLegend(.hidden)
                List(sensorNames, id: \.self, selection: $multiSelection) { sensor in
                    Text(sensor + (uselessKeys.contains(sensor) ? " 🫥" : ""))
                }
                .environment(\.editMode, .constant(.active))
                .toolbar { quickSelectionButtons }
            }
        }
        .onReceive(timer, perform: storeCurrentTemperatures)
        .onReceive(checker, perform: markUselessServices)
    }
    
    var quickSelectionButtons: some View {
        Group {
            Button("Show all") {
                multiSelection.formUnion(services.keys)
            }
            Menu("Hide") {
                Button("Hide all") {
                    multiSelection.removeAll()
                }
                Button("Hide unchanged") {
                    multiSelection.subtract(uselessKeys)
                }
            }
        }
    }
    
    func storeCurrentTemperatures(at date: Date) {
        for (key, value) in getTemperatures(from: services) {
            if temperatures.keys.contains(key) {
                temperatures[key]!.append(value)
            } else {
                temperatures[key] = [value]
            }
        }
    }
    
    func markUselessServices(at date: Date) {
        var uselessServices = Set<String>()
        for (key, values) in temperatures {
            if values.isEmpty {
                uselessServices.insert(key)
            } else {
                let ref = values[0]
                var same = true
                for value in values.suffix(from: 1) {
                    if value != ref {
                        same = false
                        break
                    }
                }
                if same {
                    uselessServices.insert(key)
                }
            }
        }
        self.uselessKeys = uselessServices
    }
    
    var temperatureArray: [Entry] {
        multiSelection.flatMap { sensor in
            temperatures[sensor]!.enumerated().map {
                Entry(sensor: sensor, time: $0, value: $1)
            }
        }
    }
    
    var sensorNames: [String] {
        services.keys.sorted()
    }
    
    struct Entry: Identifiable {
        let sensor: String
        let time: Int
        let value: Double
        
        var id: String {
            sensor + "\(time)"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
