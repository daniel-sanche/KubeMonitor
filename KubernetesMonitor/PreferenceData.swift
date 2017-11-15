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

import Foundation

class PreferenceData {
    
    
    var kubePath : String
    var showSystemPods : Bool
    var showUnlabeledPods : Bool
    var groupingLabel : String
    var sshPath :String?
    
    private let kubePathDefault : String = "~/Documents/google-cloud-sdk/bin/kubectl"
    private let showSystemPodsDefault : Bool = true
    private let showUnlabeledPodsDefault : Bool = true
    private let groupingLabelDefault = "app"
    private let sshPathDefault: String? = nil
    
    
    private let kubeKey = "KubePath"
    private let systemPodsKey = "SystemPods"
    private let unlabeledPodsKey = "UnlabeledPods"
    private let groupLabelKey = "GroupingLabel"
    private let sshKey = "SSHKey"
    private let defaults = UserDefaults.standard
    
    private let NoTextError = "Error: No text entered"
    
    static let sharedInstance = PreferenceData()
    
    init() {
        if let path = defaults.value(forKey: self.kubeKey) as? String{
            self.kubePath = path
        } else {
            self.kubePath = kubePathDefault
        }
        if let label = defaults.value(forKey: self.groupLabelKey) as? String{
            self.groupingLabel = label
        } else {
            self.groupingLabel = groupingLabelDefault
        }
        if let state = defaults.value(forKey: self.systemPodsKey) as? Bool{
            self.showSystemPods = state
        } else {
            self.showSystemPods = showSystemPodsDefault
        }
        if let state = defaults.value(forKey: self.unlabeledPodsKey) as? Bool{
            self.showUnlabeledPods = state
        } else {
            self.showUnlabeledPods = showUnlabeledPodsDefault
        }
        if let ssh = defaults.value(forKey: self.sshKey) as? String{
            self.sshPath = ssh
        } else {
            self.sshPath = sshPathDefault
        }
    }
    
    func setKubePath(newPathOpt:String?) -> String? {
        if let newPath = newPathOpt, newPath != "" {
            if KubernetesMediator.kubectlExistsAtPath(kubectlPath: newPath){
                defaults.set(newPath, forKey: kubeKey)
                self.kubePath = newPath
                return nil
            } else {
                return "Error: Could not find kubectl at path " + newPath
            }
        } else {
            return NoTextError
        }
    }
    
    func setGroupingLabel(newLabelOpt:String?) -> String? {
        if let newLabel = newLabelOpt, newLabel != "" {
            defaults.set(newLabel, forKey: groupLabelKey)
            self.groupingLabel = newLabel
            return nil
        } else {
            return  NoTextError
        }
    }
    
    func setShowSystemPods(newState:Bool) -> String? {
        defaults.set(newState, forKey: systemPodsKey)
        self.showSystemPods = newState
        return nil
    }
    
    func setShowUnlabeledPods(newState:Bool) -> String? {
        defaults.set(newState, forKey: unlabeledPodsKey)
        self.showUnlabeledPods = newState
        return nil
    }
    
    func setSSHKeyPath(newPath:String?) -> String? {
        defaults.set(newPath, forKey: sshKey)
        self.sshPath = newPath
        return nil
    }
    
    //reset the preferences store to default values
    func resetPreferences(){
        if let domain = Bundle.main.bundleIdentifier {
            defaults.setPersistentDomain([:], forName: domain)
        }
        self.kubePath = kubePathDefault
        self.groupingLabel = groupingLabelDefault
        self.showUnlabeledPods = showUnlabeledPodsDefault
        self.showSystemPods = showSystemPodsDefault
        self.sshPath = sshPathDefault
    }
    

}
