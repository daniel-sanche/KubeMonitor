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

struct Constants {
    static let UnlabeledKey = "Unlabeled"
    static let SystemNamespaceKey = "kube-system"
    static let MissingClusterNameText = "Not Found"
    static let ToolTipTruncationSize = 30
    static let DateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    static let RefreshInterval = 5.0
    static let StatusImageName = "Status"
    
    static let PieChartUsedIdx : UInt = 0
    static let PieChartFreeIdx : UInt = 1
    static let PieChartYellowThreshold = 0.9
    static let PieChartRedThreshold = 0.99
    static let MemoryChartTitle = "Memory"
    static let CPUChartTitle = "CPU"
    static let UnknownText = "Unknown"
    static let VeritcalSeperator = "---"
    static let HorizontalSeperator = " : "
    static let MemoryPrefixes = [("Ki", 1e3), ("Mi", 1e6), ("Gi", 1e9)]
    
    static let StoryBoardName = "Main"
    static let ViewControllerName = "MainViewController"
    static let PodItemName = "PodItem"
    static let HeaderItemName = "HeaderItem"
    
    static let ContainerCreationState = "ContainerCreating"
    
    struct KubeTop {
        static let numRowsExpected = 3
        static let numColsExpected = [3, 5]
        static let cpuColumn = 1
        static let memColumnNode = 3
        static let memColumnPod = 2
        enum TopType : String {
            case Pod = "pod"
            case Node = "node"
        }
    }
    
    struct JSONKeys {
        static let metadata = "metadata"
        static let items = "items"
        static let spec = "spec"
        static let namespace = "namespace"
        static let name = "name"
        static let phase = "phase"
        static let status = "status"
        static let creationtime = "creationTimestamp"
        static let containers = "containerStatuses"
        static let hostIP = "hostIP"
        static let podIP = "podIP"
        static let nodeID = "nodeName"
        static let nodeInfo = "nodeInfo"
        static let labels = "labels"
        static let image = "osImage"
        static let capacity = "capacity"
        static let cpu = "cpu"
        static let memory = "memory"
        static let addressList = "addresses"
        static let externalIP = "ExternalIP"
        static let address = "address"
        static let type = "type"
        static let allocatable = "allocatable"
    }
}

enum PodPhase: Int, Comparable {
    case Succeeded
    case Running
    case Pending
    case Unknown
    case Failed

    public static func < (a: PodPhase, b: PodPhase) -> Bool {
        return a.rawValue < b.rawValue
    }
}

extension NSColor {
    struct Kube {
        static let Red = NSColor(calibratedRed: 0.863, green: 0.314, blue: 0.278, alpha: 1)
        static let Yellow = NSColor(calibratedRed: 0.969, green: 0.761, blue: 0.243, alpha: 1)
        static let Green = NSColor(calibratedRed: 0.302, green: 0.651, blue: 0.392, alpha: 1)
        static let Gray = NSColor(calibratedRed: 0.459, green: 0.439, blue: 0.42, alpha: 1)
        static let DullGreen = NSColor(calibratedRed: 0.561, green: 0.631, blue: 0.549, alpha: 0.5)
    }
    
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
