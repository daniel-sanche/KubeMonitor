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

class ClusterModel: NSObject {
    private let name : String?
    let nodes : [NodeModel]
    var resourceSummary : (cpuTotal:Int?, memTotal:Int?, cpuUsed:Int?, memUsed:Int?)
    
    init(name:String?, nodeList:[NodeModel]) {
        self.name = name
        self.nodes = nodeList
        self.resourceSummary = (nil, nil, nil, nil)
        super.init()
        self.resourceSummary = getResources()
    }
    
    
    //returns the name of thje cluster, or a constant if there is none
    func getNameString() -> String {
        if self.name != nil {
            return self.name!
        } else {
            return Constants.MissingClusterNameText
        }
    }
    
    //MARK: infoStr
    
    
    //return information about the resource usage of the cluster
    func infoStr(groups:[GroupModel]?) -> (cpu:String?, memory:String?) {
        var cpuStr :String? = nil
        var memStr :String? = nil
        if let cpuTot = self.resourceSummary.cpuTotal, let cpuUsed = self.resourceSummary.cpuUsed {
            let utilizationStr = String(format: "%.1f", Double(cpuUsed)/Double(cpuTot) * 100)
            cpuStr = "Total:\t\t\(cpuTot.cpuToString())\nIn Use:\t\t\(cpuUsed.cpuToString())\nUtulization:\t\(utilizationStr)%"
        }
        if let memTot = self.resourceSummary.memTotal, let memUsed = self.resourceSummary.memUsed {
            let utilizationStr = String(format: "%.1f", Double(memUsed)/Double(memTot) * 100)
            memStr = "Total:\t\t\(memTot.memToString())\nIn Use:\t\t\(memUsed.memToString())\nUtulization:\t\(utilizationStr)%"
        }
        if let arr = groups, cpuStr != nil, memStr != nil{
            cpuStr = cpuStr! + "\n" + Constants.VeritcalSeperator
            memStr = memStr! + "\n" + Constants.VeritcalSeperator
            for group in arr {
                cpuStr = cpuStr! + "\n" + group.getCombinedResourceInfo().cpu
                memStr = memStr! + "\n" + group.getCombinedResourceInfo().mem
            }
        }
        return (cpuStr, memStr)
    }
    
    
    //get information about the resouce usage of the cluster
    private func getResources() -> (cpuTotal:Int?, memTotal:Int?, cpuUsed:Int?, memUsed:Int?) {
        var cpuTotal : Int? = 0
        var cpuUsed : Int? = 0
        var memTotal : Int? = 0
        var memUsed : Int? = 0
        
        for thisNode in self.nodes{
            cpuTotal = resourceHelper(thisNodeVal: thisNode.cpuAvailable, oldTotal: cpuTotal)
            cpuUsed = resourceHelper(thisNodeVal: thisNode.cpuUsed, oldTotal: cpuUsed)
            memTotal = resourceHelper(thisNodeVal: thisNode.memoryAvailable, oldTotal: memTotal)
            memUsed = resourceHelper(thisNodeVal: thisNode.memoryUsed, oldTotal: memUsed)
        }
        return  (cpuTotal, memTotal, cpuUsed, memUsed)
    }
    
    //helper function to add up resources, and return nil when encountered
    private func resourceHelper(thisNodeVal:Int?, oldTotal:Int?) -> Int? {
        if thisNodeVal != nil && oldTotal != nil {
            return oldTotal! + thisNodeVal!
        }
        return nil
    }

}
