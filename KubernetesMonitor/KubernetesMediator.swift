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

class KubernetesMediator: NSObject {
    
    //checks whether the kubectl command exists at a given path
    class func kubectlExistsAtPath(kubectlPath: String) -> Bool{
        return kubectlPath.contains("kubectl") && TerminalInterface.commandExists(path: kubectlPath)
    }
    
    //launches an ssh session to a node
    class func launchTerminalToNode(node: NodeModel){
        if let ip = node.externalIP {
            var commandStr = "ssh " + ip
            if let keyPath = PreferenceData.sharedInstance.sshPath {
                commandStr +=  " -i " + keyPath
            }
            TerminalInterface.launchTerminalSession(command: commandStr)
        }
    }
    
    //launch a kubectl exec /bin/sh session into a container
    class func launchTerminalToPod(pod: PodModel, containerName: String){
        let commandStr = PreferenceData.sharedInstance.kubePath + " exec -it " + pod.name + " --container " + containerName + " --namespace=" + pod.namespace + " -- /bin/sh"
        TerminalInterface.launchTerminalSession(command: commandStr)
    }
    
    //delete a pod from the cluster
    class func deletePod(pod: PodModel) -> String?{
        return TerminalInterface.run(commandName: PreferenceData.sharedInstance.kubePath, arguments: ["--namespace", pod.namespace, "delete", "pod", pod.name])
    }
    
    //gets the set of pods running on the cluster, divided into groups based on label
    class func getPods(groupingLabel:String=PreferenceData.sharedInstance.groupingLabel) -> [GroupModel] {
        var labelDict: [String:[PodModel]] = [Constants.UnlabeledKey:[]]
        var groupList : [GroupModel] = []
        if let podList = KubernetesMediator.kubectlJsonHelper(arguments: ["get", "pods","--all-namespaces"]) {
            for pod in podList {
                if let metadata = pod[Constants.JSONKeys.metadata] as? [String: Any],
                    let namespace = metadata[Constants.JSONKeys.namespace] as? String,
                    let spec = pod[Constants.JSONKeys.spec] as? [String:Any],
                    let name = metadata[Constants.JSONKeys.name] as? String,
                    let status = pod[Constants.JSONKeys.status] as? [String:Any],
                    let phaseStr = status[Constants.JSONKeys.phase] as? String,
                    let startTimeStr = metadata[Constants.JSONKeys.creationtime] as? String,
                    let containerJSON = status[Constants.JSONKeys.containers] as? [[String:Any]] {
                    
                    let hostIP = status[Constants.JSONKeys.hostIP] as? String
                    let podIP = status[Constants.JSONKeys.podIP] as? String
                    let nodeID = spec[Constants.JSONKeys.nodeID] as? String
                    
                    let model = PodModel(name:name, phaseStr:phaseStr, startTimeStr:startTimeStr, namespace:namespace,
                                         hostIP:hostIP, podIP:podIP, nodeID:nodeID, containerJSON:containerJSON)
                    //assign a label (or uncategorized
                    var podLabel = Constants.UnlabeledKey
                    if let metadata = pod[Constants.JSONKeys.metadata] as? [String: Any],
                        let labels = metadata[Constants.JSONKeys.labels] as? [String:String],
                        let foundLabel = labels[groupingLabel]{
                        podLabel = foundLabel
                    } else if namespace == Constants.SystemNamespaceKey{
                        //group kube-system pods together
                        podLabel = namespace
                    }
                    var oldPodList = labelDict[podLabel] ?? []
                    oldPodList.append(model)
                    labelDict[podLabel] = oldPodList
                }
            }
            //create GroupModels
            for (key, value) in labelDict{
                if (key != Constants.SystemNamespaceKey || PreferenceData.sharedInstance.showSystemPods),
                    (key != Constants.UnlabeledKey || PreferenceData.sharedInstance.showUnlabeledPods) {
                    let model = GroupModel(name: key, pods: value)
                    groupList.append(model)
                }
            }
        }
        return groupList.sorted(by: GroupModel.sortFunc)
    }
    
    //gets the set of nodes in the cluster
    private class func getNodes() -> [NodeModel] {
        var foundNodes : [NodeModel] = []
        
        if let nodeList = KubernetesMediator.kubectlJsonHelper(arguments: ["get", "nodes"]){
            for node in nodeList {
                if let status = node[Constants.JSONKeys.status] as? [String:Any],
                    let metadata = node[Constants.JSONKeys.metadata] as? [String:Any],
                    let name = metadata[Constants.JSONKeys.name] as? String,
                    let startTimeStr = metadata[Constants.JSONKeys.creationtime] as? String,
                    let info = status[Constants.JSONKeys.nodeInfo] as? [String: Any],
                    let image = info[Constants.JSONKeys.image] as? String,
                    let capDict = status[Constants.JSONKeys.capacity] as? [String: Any],
                    let cpuCap = capDict[Constants.JSONKeys.cpu] as? String,
                    let memCap = capDict[Constants.JSONKeys.memory] as? String,
                    let addresses = status[Constants.JSONKeys.addressList] as? [[String:String]]{
                    var externalIP : String?
                    for thisDict in addresses {
                        if thisDict[Constants.JSONKeys.type] == Constants.JSONKeys.externalIP {
                            externalIP = thisDict[Constants.JSONKeys.address]
                        }
                    }
                    
                    var memAlloc : String?
                    var cpuAlloc : String?
                    if let allocDict = status[Constants.JSONKeys.allocatable] as? [String:Any] {
                        memAlloc = allocDict[Constants.JSONKeys.memory] as? String
                        cpuAlloc = allocDict[Constants.JSONKeys.cpu] as? String
                    }
                    let model = NodeModel(name:name, creationDateStr:startTimeStr, osImage:image, cpuCapStr:cpuCap,
                                          cpuAllocableStr:cpuAlloc, memCapStr:memCap, memAllocableStr:memAlloc, externalIP:externalIP)
                    foundNodes.append(model)
                }
            }
        }
        return foundNodes
    }
    
    //takes in a list of kubectl arguments, and returns the results in the "items" field of the resulting json
    private class func kubectlJsonHelper(arguments:[String]) -> [[String: Any]]?{
        do {
            if let result = TerminalInterface.run(commandName: PreferenceData.sharedInstance.kubePath, arguments: arguments + ["-o=json"]),
                let data = result.data(using: .utf8),
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let itemList = json[Constants.JSONKeys.items] as? [[String: Any]]{
                return itemList
            }
        } catch {
            print("Error deserializing JSON: \(error)")
        }
        return nil
    }
    
    //gets the resource info for a given node
    class func topNode(node:NodeModel) -> (cpu:Int, mem:Int)?{
        let cpuCol =  Constants.KubeTop.cpuColumn
        let memCol = Constants.KubeTop.memColumnNode
        let type = Constants.KubeTop.TopType.Node
        
        return topHelper(name: node.name, type: type, cpuCol: cpuCol, memCol: memCol, namespace: nil)
    }
    
    //gets the resource info for a given pod
    class func topPod(pod:PodModel) -> (cpu:Int, mem:Int)?{
        let cpuCol =  Constants.KubeTop.cpuColumn
        let memCol = Constants.KubeTop.memColumnPod
        let type = Constants.KubeTop.TopType.Pod
        
        return topHelper(name: pod.name, type: type, cpuCol: cpuCol, memCol: memCol, namespace: pod.namespace)
    }
    
    private class func topHelper(name:String,type:Constants.KubeTop.TopType,cpuCol:Int,memCol:Int,namespace:String?)->(cpu:Int, mem:Int)?{
        //this function involves parsing strings. If anything seems different than we expect, give up and return nil
        var args = ["top", type.rawValue, name]
        if type == .Pod, let ns = namespace {
            args.append("--namespace=" + ns)
        }
        if let result = TerminalInterface.run(commandName: PreferenceData.sharedInstance.kubePath, arguments: args){
            let lineArr = result.components(separatedBy: "\n")
            if (lineArr.count==Constants.KubeTop.numRowsExpected){
                let topLine = lineArr[1].condensedWhitespace
                let spaceArr = topLine.components(separatedBy: .whitespaces)
                for thisOption in Constants.KubeTop.numColsExpected{
                    if spaceArr.count == thisOption{
                        let cpuVal = spaceArr[cpuCol].cpuStringToInt()
                        let memVal = spaceArr[memCol].memStringToInt()
                        if let c = cpuVal, let m = memVal {
                            return (cpu:c, mem:m)
                        }
                    }
                }
            }
        }
        return nil
    }
    
    //gets information about the cluster as a whole
    class func getCluster() -> ClusterModel{
        let nodeList = self.getNodes()
        let clusterName = TerminalInterface.run(commandName: PreferenceData.sharedInstance.kubePath, arguments: ["config", "view", "-o=template", "--template='{{ index . \"current-context\" }}'"])
        let formatted = clusterName?.replacingOccurrences(of: "'", with: "")
        return ClusterModel(name:formatted, nodeList:nodeList)
    }
    
}


private class TerminalInterface {
    /**
     *  Handles interfacing with the system's CLI
     */
    
    
    //returns whether the command could be found
    class func commandExists(path:String) -> Bool{
        return which(commandName: path) != nil
    }
    
    //runs a command and returns the results as a string
    class func run(commandName: String, arguments: [String]) -> String? {
        if let path = self.which(commandName: commandName){
            return runHelper(command: path, arguments: arguments)
        } else {
            return nil
        }
    }
    
    class func launchTerminalSession(command:String){
        let tmpFile = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("kubelaunch.scpt")
        print(tmpFile!)
        
        let applescriptStr = "tell application \"Terminal\"\n\tactivate\n\tdo script \"\(command)\"\nend tell"
        
        do {
            try applescriptStr.write(to:tmpFile!, atomically: false, encoding: .utf8)
            let task = Process()
            task.launchPath = which(commandName: "osascript")
            task.arguments = [tmpFile!.path]
            task.launch()
        }
        catch {
            print("Error opening terminal. Is osascript installed?")
        }
    }
    
    //returns the path for a command
    private class func which(commandName: String) -> String?{
        if let whichPathForCommand = runHelper(command: "/bin/bash" , arguments:[ "-l", "-c", "which \(commandName)" ]) {
            return whichPathForCommand.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        }
        return nil
    }
    
    private class func runHelper(command: String, arguments: [String] = []) -> String? {
        let task = Process()
        task.launchPath = command
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String? = String(data: data, encoding: String.Encoding.utf8)
        
        if output == "" {
            return nil
        }
        return output
    }
}
