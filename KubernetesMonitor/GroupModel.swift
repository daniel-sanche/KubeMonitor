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

class GroupModel: NSObject {
    private let podList : [PodModel]
    let name : String
    var collapsed = true
    
    init(name:String, pods:[PodModel]) {
        self.name = name
        let sortedPods = pods.sorted(by: PodModel.sortFunc)
        self.podList = sortedPods
    }
    
    //look through all pods, and return the most critical phase of all pods
    //serves as an indicator for health of the group
    func getWorstPhase() -> PodPhase {
        var worstState : PodPhase = .Succeeded
        for thisPod in self.podList {
            if worstState < thisPod.phase{
                worstState = thisPod.phase
            }
        }
        return worstState
    }
    
    //get the numer of pods that are currently active
    func numberRunning() -> Int {
        var n = 0
        for thisPod in self.podList {
            if thisPod.phase == .Running {
                n += 1
            }
        }
        return n
    }
    
    // get the number of pods in the group
    func numPods() -> Int{
        return self.podList.count
    }
    
    // get a pod out of the group
    func getPodAtIdx(idx:Int) -> PodModel?{
        if idx >= 0, idx < self.podList.count {
            return podList[idx]
        }
        return nil
    }
    
    //MARK: Resources
    
    //refresh cpu/memory resource information for all pods
    func refreshResourceInfo() {
        for thisPod in self.podList {
            thisPod.refreshResourceInfo()
        }
    }
    
    //get information about the cpu/memory used by the group
    func getCombinedResourceInfo() -> (cpu:String, mem:String) {
        var cpuTotal : Int?
        var memTotal : Int?
        for pod in self.podList{
            if let cpu = pod.cpuUsed {
                if let oldVal = cpuTotal {
                    cpuTotal = cpu + oldVal
                } else {
                    cpuTotal = cpu
                }
            }
            if let mem = pod.memoryUsed {
                if let oldVal = memTotal {
                    memTotal = oldVal + mem
                } else {
                    memTotal = mem
                }
            }
        }
        let prefixStr = self.name + Constants.HorizontalSeperator
        let cpuStr = cpuTotal?.cpuToString() ?? Constants.UnknownText
        let memStr = memTotal?.memToString() ?? Constants.UnknownText
        return (cpu:prefixStr+cpuStr, mem:prefixStr+memStr)
    }
    
    //MARK: Comparing Groups
    
    //defines how groups are ordered
    //in this case, groups are sorted alphabetically, with kube-system pods and unlabeled pods pushed to the bottom
    class func sortFunc(this:GroupModel, that:GroupModel) -> Bool {
        if this.name == Constants.SystemNamespaceKey {
            return false
        } else if that.name == Constants.SystemNamespaceKey {
            return true
        } else if this.name == Constants.UnlabeledKey {
            return false
        } else if that.name == Constants.UnlabeledKey {
            return true
        } else {
            return this.name < that.name
        }
    }
    
    //compare two groups to see if they are the same
    override func isEqual(_ object: Any?) -> Bool {
        if let o = object as? GroupModel {
            return self.name == o.name && self.podList == o.podList
        }
        return false
    }
    
}
