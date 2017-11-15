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

class PodModel: NSObject {
    let name: String
    let phase : PodPhase
    let namespace: String
    let startDate : Date?
    let hostIP : String?
    let podIP : String?
    let nodeID : String?
    let containers : [String:String]
    
    var cpuUsed: Int?
    var memoryUsed: Int?
    
    init(name:String, phase:PodPhase, startTimeStr:String, namespace:String,
         hostIP:String?=nil, podIP:String?=nil, nodeID:String?=nil, containerJSON:[[String:Any]]?=nil) {
        self.name = name
        self.namespace = namespace
        self.phase = phase
        self.hostIP = hostIP
        self.podIP = podIP
        self.nodeID = nodeID
        self.containers = PodModel.parseContainerStateFromJSON(containerJSON: containerJSON)
        
        self.startDate = DateFormatter.dateFromKubernetesStr(kubeFormattedStr: startTimeStr)
        //find the resources in use
        super.init()
    }
    
    convenience init(name:String, phaseStr:String,  startTimeStr:String, namespace:String,
                     hostIP:String?=nil, podIP:String?=nil, nodeID:String?=nil, containerJSON:[[String:Any]]?=nil) {
        var phase : PodPhase = .Unknown
        switch phaseStr {
        case "Pending":
            phase = .Pending
        case "Running":
            phase = .Running
        case "Succeeded":
            phase = .Succeeded
        case "Failed":
            phase = .Failed
        default:
            phase = .Unknown
        }
        self.init(name:name, phase:phase, startTimeStr:startTimeStr, namespace:namespace,
                  hostIP:hostIP, podIP:podIP, nodeID:nodeID, containerJSON:containerJSON)
    }
    
    //helper function to parse JSON into a state for each container
    private static func parseContainerStateFromJSON(containerJSON:[[String:Any]]?) -> [String:String]{
        var containerDict : [String:String] = [:]
        if let json = containerJSON{
            for thisContainer in json {
                if let name = thisContainer["name"] as? String,
                    let stateDict = thisContainer["state"] as? [String:Any],
                    let (state, value) = stateDict.first{
                    var stateString = state
                    if let valueDict = value as? [String:Any],
                        let reason = valueDict["reason"] as? String {
                        stateString = reason
                    }
                    containerDict[name] = stateString
                }
            }
        }
        return containerDict
    }

    //refresh cpu/memory resource information for all pods
    func refreshResourceInfo(){
        if self.phase == .Running {
            let resources = KubernetesMediator.topPod(pod: self)
            self.cpuUsed = resources?.cpu
            self.memoryUsed = resources?.mem
        }
    }
    
    //given the cluster of nodes, find the one this pod is running in
    func findNodeForPod(cluster:ClusterModel?) -> NodeModel?{
        var foundNode : NodeModel?
        if let nodeList = cluster?.nodes, let nodeId = self.nodeID  {
            for thisNode in nodeList{
                if thisNode.name == nodeId{
                    foundNode = thisNode
                }
            }
        }
        return foundNode
    }
    
    //MARK: infoStr
    
    func infoStr() -> String{
        var infoStr = "Name:\t\(self.name.truncateMiddle(truncationSize: Constants.ToolTipTruncationSize))\nPhase:\t\(self.phase)"
        if let s = startDateStr(){
            infoStr += "\nCreated:\t\(s)"
        }
        if let s = self.timeRunningStr(){
            infoStr += "\n\t\t(\(s) ago)"
        }
        if let s = self.hostIP {
            infoStr += "\nHost IP:\t\(s)"
        }
        if let s = self.podIP {
            infoStr += "\nPod IP:\t\(s)"
        }
        if let s = self.nodeID {
            infoStr += "\nNode:\t\(s.truncateMiddle(truncationSize: Constants.ToolTipTruncationSize))"
        }
        if let s = self.cpuUsed?.cpuToString(){
            infoStr += "\nCPU:\t\t\(s)"
        }
        if let s = self.memoryUsed?.memToString(){
            infoStr += "\nMemory:\t\(s)"
        }
        infoStr += "\n\nContainers:" + self.containerInfoStr()
        return infoStr
    }
    
    private func containerInfoStr() -> String {
        if self.containers.count == 0 {
            return "No containers"
        }
        var containerStr = ""
        for (key, value) in self.containers{
            containerStr += "\n\t\(key) : \(value)"
        }
        return containerStr
    }
    
    private func startDateStr() -> String?{
        if let date = self.startDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let startDateStr = formatter.string(from: date)
            return startDateStr
        }
        return nil
    }
    
    private func timeRunningStr() -> String?{
        if let date = self.startDate {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.year, .month, .day, .hour, .minute]
            formatter.unitsStyle = .full
            let timeSinceStart = formatter.string(from: date, to: Date.init(timeIntervalSinceNow: 0))
            
            if let wordArr = timeSinceStart?.components(separatedBy: ", "),
                wordArr.count > 2 {
                //only show up to 2 significant digits
                return "\(wordArr[0]) and \(wordArr[1])"
            }
            return timeSinceStart
        }
        return nil
    }
    
    
    //MARK: Comparing Groups
    
    //defines how pods are ordered
    //in this case, pods are sorted by start time, with alphebetical name used to break ties
    class func sortFunc(this:PodModel, that:PodModel) -> Bool {
        var thisAbove:Bool
        if let thisStart=this.startDate, let thatStart=that.startDate{
            //put older date on top
            thisAbove = thisStart < thatStart
        } else if this.startDate != nil{
            //this one has a date, other doesn't. Put this on top
            thisAbove = true
        } else if that.startDate != nil {
            //other one has a date, this doesn't. Put other on top
            thisAbove = false
        } else {
            //neither has start date. Sort by name
            thisAbove = this.name < that.name
        }
        return thisAbove
    }
    
    //determines whether two pods are the same
    override func isEqual(_ object: Any?) -> Bool {
        if let o = object as? PodModel {
            return self.name == o.name &&
                self.namespace==o.namespace &&
                self.phase == o.phase &&
                self.hostIP == o.hostIP &&
                self.nodeID == o.nodeID &&
                self.podIP == o.podIP &&
                self.startDate == o.startDate &&
                self.containers == o.containers
        }
        return false
    }
}
