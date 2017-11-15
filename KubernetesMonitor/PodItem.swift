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

class PodItem: NSCollectionViewItem {

    @IBOutlet weak var textLabel: NSTextField!
    @IBOutlet weak var disclosureBtn: NSPopUpButton!
    @IBOutlet weak var disclosureMenu: NSMenu!
    private var associatedModel : PodModel?
    private var associatedNode : NodeModel?
    
    private static let NodeMenuTitle = "Node"
    private static let DeleteMenuTitle = "Delete Pod"
    
    //MARK: Initialization
    
    //change the model associated with the cell. Update the view
    func setUpWithPod(pod:PodModel, cluster:ClusterModel?){
        
        //add a menu option to connect to the pod's node
        self.associatedNode = pod.findNodeForPod(cluster: cluster)
        //set up the disclosure menu
        if let menu = self.disclosureMenu {
            PodItem.setUpMenu(menu: menu, node: self.associatedNode, containerInfo: pod.containers, target: self)
        }
        
        
        self.textLabel.textColor = NSColor.colorForPhase(phase: pod.phase)
        self.textLabel.stringValue = pod.name
        self.textLabel.toolTip = pod.infoStr()
        self.associatedModel = pod
    }
    
    
    //helper function to initialize the disclosure menu
    private static func setUpMenu(menu:NSMenu, node:NodeModel?, containerInfo:[String:String], target:AnyObject) {
        //reset the menu
        menu.removeAllItems()
        
         //add a menu option to connect to the pod's node
        let nodeItem = NSMenuItem(title: self.NodeMenuTitle, action: #selector(sshNode(_:)), keyEquivalent: "")
        if node?.externalIP != nil{
            //only enable the option if we actually know the node's IP
            nodeItem.target = target
        }
        menu.addItem(nodeItem)
        menu.addItem(NSMenuItem.separator())
        
        //add options to connect to each container
        for (name, state) in containerInfo{
            let newItem = NSMenuItem(title: name, action: #selector(sshContainer(_:)), keyEquivalent: "")
            if state != Constants.ContainerCreationState {
                //only enable connection if the container is in an active state
                newItem.target = target
            }
            menu.addItem(newItem)
        }
        
        //add the menu option to
        menu.addItem(NSMenuItem.separator())
        let deleteItem = NSMenuItem(title: self.DeleteMenuTitle, action: #selector(deletePressed(_:)), keyEquivalent: "")
        deleteItem.target = target
        menu.addItem(deleteItem)
    }
    
    //MARK: Menu Buttons
    
    //launch a shell session into a container
    @objc private func sshContainer(_ sender:NSMenuItem){
        let containerName = sender.title
        if let pod = associatedModel {
            KubernetesMediator.launchTerminalToPod(pod: pod, containerName: containerName)
            (NSApp.delegate as? AppDelegate)?.closePopover(sender: self)
        }
    }
    
    //launch a shell session into the node
    @objc private func sshNode(_ sender:NSMenuItem){
        if let node = self.associatedNode,  node.externalIP != nil{
            KubernetesMediator.launchTerminalToNode(node: node)
            (NSApp.delegate as? AppDelegate)?.closePopover(sender: self)
        }
    }
    
    //delete the associated pod
    @objc private func deletePressed(_ sender:NSMenuItem){
        if let pod = associatedModel{
            if let resultStr = KubernetesMediator.deletePod(pod: pod){
                print(resultStr)
            }
        }
    }
    
    
}
