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

class NodeModel: NSObject {
    let name:String
    let creationDate:Date?
    let osImage: String
    let externalIP : String?
    
    let cpuAvailable: Int?
    var cpuUsed: Int?
    let memoryAvailable: Int?
    var memoryUsed: Int?
    
    init(name:String, creationDateStr:String, osImage:String,
         cpuCapStr:String?, cpuAllocableStr:String?, memCapStr:String?, memAllocableStr:String?, externalIP:String?) {
        self.name = name
        self.creationDate = DateFormatter.dateFromKubernetesStr(kubeFormattedStr: creationDateStr)
        self.osImage = osImage
        self.externalIP = externalIP
        
        //use allocatable if available, otherwise use capacity
        if let cpuAlloc = cpuAllocableStr?.cpuStringToInt() {
            self.cpuAvailable = cpuAlloc
        } else  {
            self.cpuAvailable = cpuCapStr?.cpuStringToInt()
        }
        if let memAlloc = memAllocableStr?.memStringToInt() {
            self.memoryAvailable = memAlloc
        } else {
            self.memoryAvailable = memCapStr?.memStringToInt()
        }
        //find the resources in use
        super.init()
        self.refreshResourceUsage()
    }
    
    //refresh cpu/memory usage info
    func refreshResourceUsage(){
        let resources = KubernetesMediator.topNode(node: self)
        self.cpuUsed = resources?.cpu
        self.memoryUsed = resources?.mem
    }
    

    
}
