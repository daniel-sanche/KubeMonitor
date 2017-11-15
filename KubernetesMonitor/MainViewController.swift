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
import CorePlot

class MainViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource, CPTPieChartDataSource, CPTPieChartDelegate {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var clusterLabel: NSTextField!
    @IBOutlet weak var cpuChartView: CPTGraphHostingView!
    @IBOutlet weak var memoryChartView: CPTGraphHostingView!


    
    private var podGrouplist : [GroupModel] = KubernetesMediator.getPods()
    private var clusterInfo : ClusterModel = KubernetesMediator.getCluster()
    
    
    // MARK:  initialization
    static func freshController() -> MainViewController {

        let storyboard = NSStoryboard(name: Constants.StoryBoardName, bundle: nil)
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: Constants.ViewControllerName) as? MainViewController else {
            fatalError("Could not instantiate MainViewController")
        }
        return viewcontroller
    }
    
    //always refresh data when the view appears
    override func viewWillAppear() {
        super.viewWillAppear()
        self.refreshData()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    //refresh all the models used to represent the kubernetes system
    func refreshData() {
        self.clusterLabel.stringValue = self.clusterInfo.getNameString()
        
        //refresh pod info
        DispatchQueue.global().async {
            //do tasks in background
            let oldGroup = self.podGrouplist
            let newGroup  = KubernetesMediator.getPods()
            if newGroup != oldGroup{
                //retain collapsed state
                let minListSize = min(newGroup.count, oldGroup.count)
                for i in 0..<minListSize{
                    newGroup[i].collapsed = oldGroup[i].collapsed
                }
                self.podGrouplist = newGroup
                //update UI on main thread
                DispatchQueue.main.async(execute: { self.collectionView.reloadData() })
            }
            //refressh resource info for all groups
            for thisGroup in self.podGrouplist{
                thisGroup.refreshResourceInfo()
            }
        }
        
        //refresh cluster/node info
        DispatchQueue.global().async {
            //do tasks in background
            self.clusterInfo = KubernetesMediator.getCluster()
            DispatchQueue.main.async(execute: {
                //update UI on main thread
                self.clusterLabel.stringValue = self.clusterInfo.getNameString()
                self.clusterLabel.toolTip = self.clusterInfo.getNameString()
                self.cpuChartView.hostedGraph?.reloadData()
                self.memoryChartView.hostedGraph?.reloadData()
                self.cpuChartView.toolTip = self.clusterInfo.infoStr(groups: self.podGrouplist).cpu
                self.memoryChartView.toolTip = self.clusterInfo.infoStr(groups: self.podGrouplist).memory
            })
        }
    }

    //add charts to view
    override func viewDidLayout() {
        super.viewDidLayout()
        createChart(hostingView: self.cpuChartView, titleText:Constants.CPUChartTitle)
        createChart(hostingView: self.memoryChartView, titleText:Constants.MemoryChartTitle)
    }
    
    //initialize chart and add it to the hostingview
    private func createChart(hostingView:CPTGraphHostingView, titleText:String){
        let graph = CPTXYGraph(frame: hostingView.bounds)
        hostingView.hostedGraph = graph
        graph.paddingLeft = 0.0
        graph.paddingTop = 0.0
        graph.paddingRight = 0.0
        graph.paddingBottom = 0.0
        graph.axisSet = nil
        graph.title = titleText
        graph.titlePlotAreaFrameAnchor = CPTRectAnchor.bottom
        graph.titleDisplacement = CGPoint(x: 0, y: -5)
        
        // Create the chart
        let pieChart = CPTPieChart()
        pieChart.delegate = self
        pieChart.dataSource = self
        pieChart.pieRadius = (min(hostingView.bounds.size.width,
                                  hostingView.bounds.size.height) * 0.7) / 2
        pieChart.startAngle = CGFloat(Double.pi/2)
        pieChart.sliceDirection = .counterClockwise
        pieChart.identifier = NSString(string: graph.title!)
        
        graph.add(pieChart)
    }

    // MARK: collection view
    
    //each GroupModel represents a section in the collection view
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return podGrouplist.count
    }
    
    //the section will have a single item if it's collaped, or have an item for each pod if it's open
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        let model = podGrouplist[section]
        if model.collapsed{
            return 1
        } else {
            return model.numPods() + 1
        }
    }
    
    //returns the CollectionView item for the index
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        var item : NSCollectionViewItem
        let group = podGrouplist[indexPath.section]
        
        if indexPath.item == 0{
            //display group header
            item = collectionView.makeItem(withIdentifier: Constants.HeaderItemName, for: indexPath)
            guard let headerItem = item as? HeaderItem else {return item}
            headerItem.setUpWithGroup(model: group)
        } else {
            //display pod cell
            item = collectionView.makeItem(withIdentifier: Constants.PodItemName, for: indexPath)
            guard let podItem = item as? PodItem else {return item}
            podItem.textLabel.textColor = NSColor.Kube.Gray
            if let thisPod = group.getPodAtIdx(idx: indexPath.item-1){
                podItem.setUpWithPod(pod: thisPod, cluster:self.clusterInfo)
            }
        }
        return item
    }
    
    // MARK: CPTPieChart
    
    //we always have only 2 slices in the pie chart
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return 2
    }
    
    //returns the number the pie chart slice represents
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        let (cpuTotalOpt, memTotalOpt, cpuUsedOpt, memUsedOpt) = self.clusterInfo.resourceSummary
        //TODO: what if cpu/memory info is missing? Display warning
        if plot.identifier as? String == Constants.CPUChartTitle, let cpuTotal = cpuTotalOpt, let cpuUsed = cpuUsedOpt {
            //if free <= 0, return a very small number, so it still shows a pie chart
            let cpuFree = max((cpuTotal - cpuUsed), 1)
            if idx == Constants.PieChartUsedIdx {
                return cpuUsed
            } else if idx == Constants.PieChartFreeIdx {
                return cpuFree
            }
        }
        if plot.identifier as? String == Constants.MemoryChartTitle, let memTotal = memTotalOpt, let memUsed = memUsedOpt {
            let memFree = max((memTotal - memUsed), 1)
            if idx == Constants.PieChartUsedIdx {
                return memUsed
            } else if idx == Constants.PieChartFreeIdx {
                return memFree
            }
        }
        return 0
    }
    
    //determines the color for each piechart slice
    //color is based on % utilization of the resource
    func sliceFill(for pieChart: CPTPieChart, record idx: UInt) -> CPTFill? {
        if idx == Constants.PieChartUsedIdx {
            var color = CPTFill(color: CPTColor(cgColor: NSColor.Kube.Green.cgColor))
            if let used = number(for: pieChart, field: 0, record: Constants.PieChartUsedIdx) as? Int,
                let free = number(for: pieChart, field: 0, record: Constants.PieChartFreeIdx) as? Int{
                let percent = Double(used)/Double(used+free)
                if percent > Constants.PieChartRedThreshold {
                    color = CPTFill(color: CPTColor(cgColor: NSColor.Kube.Red.cgColor))
                } else if percent > Constants.PieChartYellowThreshold {
                    color = CPTFill(color: CPTColor(cgColor: NSColor.Kube.Yellow.cgColor))
                }
                
            }
            return color
        }
        return CPTFill(color: CPTColor(cgColor: NSColor.Kube.DullGreen.cgColor))
    }

    
}
