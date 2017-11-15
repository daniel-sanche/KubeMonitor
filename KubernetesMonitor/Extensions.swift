//
// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Cocoa

extension NSColor {
    //colors chosen for the interface
    struct Kube {
        static let Red = NSColor(calibratedRed: 0.863, green: 0.314, blue: 0.278, alpha: 1)
        static let Yellow = NSColor(calibratedRed: 0.969, green: 0.761, blue: 0.243, alpha: 1)
        static let Green = NSColor(calibratedRed: 0.302, green: 0.651, blue: 0.392, alpha: 1)
        static let Gray = NSColor(calibratedRed: 0.459, green: 0.439, blue: 0.42, alpha: 1)
        static let DullGreen = NSColor(calibratedRed: 0.561, green: 0.631, blue: 0.549, alpha: 0.5)
    }
    
    //return a color representation for a given pod phase
    static func colorForPhase(phase:PodPhase) -> NSColor{
        switch phase {
        case .Running:
            return NSColor.Kube.Green
        case .Pending:
            return NSColor.Kube.Yellow
        case .Failed, .Unknown:
            return NSColor.Kube.Red
        case .Succeeded:
            return NSColor.Kube.Gray
        }
    }
}


extension String {
    //truncate a string so that it is rouchly truncationSize
    func truncateMiddle(truncationSize:Int) -> String {
        var result = self
        let length = self.characters.count
        if(length>truncationSize){
            let halfSize = truncationSize/2
            let startEnd = self.index(self.startIndex, offsetBy: halfSize)
            let endStart = self.index(self.endIndex, offsetBy: -halfSize)
            
            result = self.substring(to: startEnd) + "..." + self.substring(from:endStart)
        }
        return result
    }
    
    //given a string representing memory resources, attempt to turn it into an int representation
    func cpuStringToInt() -> Int? {
        //rule: if it ends in an m, drop the m
        //if there is no m, multiply by 1000
        let splitArr = self.components(separatedBy: "m")
        if let floatVal = Float(splitArr[0]) {
            if splitArr.count == 1 {
                return Int(floatVal * 1000)
            } else {
                return Int(floatVal)
            }
        }
        return nil
    }
    
    //given a string representing cpu resources, attempt to turn it into an int representation
    func memStringToInt() -> Int? {
        //rule: assume memory is given as Ki, Mi, or Gi
        let allowedPrefixes = Constants.MemoryPrefixes
        for (thisPrefix, scaleFactor) in allowedPrefixes{
            let splitArr = self.components(separatedBy: thisPrefix)
            if splitArr.count == 2 {
                if let base = Int(splitArr[0]){
                    return base * Int(scaleFactor)
                }
            }
        }
        return nil
    }
    
    
    var condensedWhitespace: String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}

extension Int {
    // return the number formatted as memory
    func memToString() -> String{
        var currentStr = ""
        for (title, value) in Constants.MemoryPrefixes{
            let scaledValue = Double(self)/value
            if scaledValue >= 100 || currentStr == "" {
                currentStr = String(format: "%.0f", scaledValue) + " " + title
            } else if scaledValue >= 1 {
                currentStr = String(format: "%.2f", scaledValue) + " " + title
            }
        }
        return currentStr
    }
    
    // return the number formatted as CPU resources
    func cpuToString() -> String {
        let f = Float(self) / 1000.0
        return String(f)
    }
}

extension DateFormatter {
    static func dateFromKubernetesStr(kubeFormattedStr:String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.DateFormat
        return dateFormatter.date(from: kubeFormattedStr)
    }
}
