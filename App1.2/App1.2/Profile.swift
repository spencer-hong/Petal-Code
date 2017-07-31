//
//  Profile.swift
//  App1.2
//
//  Created by Bhai Jaiveer Singh on 7/27/17.
//  Copyright © 2017 Jaiveer. All rights reserved.
//

import Foundation

public struct Profile {
    public let name: String
    public let temperatureSP: Int
    public let humiditySP: Int
    public let light: Int
    public let blue: Int
    
    init?(name: String, temperatureSP: Int, humiditySP: Int, light: Int, blue: Int) {
        if name.isEmpty || temperatureSP < 10 || temperatureSP > 60 ||
            humiditySP < 10 || humiditySP > 90 || light < 0 ||
            light > 100 || blue < 0 || blue > 100 {
            return nil
        }
        self.name = name
        self.temperatureSP = temperatureSP
        self.humiditySP = humiditySP
        self.light = light
        self.blue = blue
    }
}
