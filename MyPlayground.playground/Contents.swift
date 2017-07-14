//: Playground - noun: a place where people can play

import UIKit

var val: Float = 5.766

if (val - floor(val*1)/1) < 0.5 {
    val = floor(val*1)/1
}
else {val = round(val)}

