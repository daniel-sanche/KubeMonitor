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
