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

class PreferencesViewController: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var unlabeledPodsOff: NSButton!
    @IBOutlet weak var unlabeledPodsOn: NSButton!
    @IBOutlet weak var systemPodsOff: NSButton!
    @IBOutlet weak var systemPodsOn: NSButton!
    @IBOutlet weak var groupingLabelField: NSTextField!
    @IBOutlet weak var kubectlPathField: NSTextField!
    @IBOutlet weak var errorTextField: NSTextField!
    @IBOutlet weak var sshPathTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFromPreferenceStore()
        if let del = NSApp.delegate as? AppDelegate {
            del.closePopover(sender: nil)
        }
    }
    
    //reload UI to match the data found in PreferenceData
    func loadFromPreferenceStore(){
        self.kubectlPathField.stringValue = PreferenceData.sharedInstance.kubePath
        self.groupingLabelField.stringValue = PreferenceData.sharedInstance.groupingLabel
        if let sshpath = PreferenceData.sharedInstance.sshPath {
            self.sshPathTextField.stringValue = sshpath
        } else {
            self.sshPathTextField.stringValue = ""
        }
        if PreferenceData.sharedInstance.showUnlabeledPods {
            unlabeledPodsOn.state = NSControl.StateValue(rawValue: 1)
        } else {
            unlabeledPodsOff.state = NSControl.StateValue(rawValue: 1)
        }
        if PreferenceData.sharedInstance.showSystemPods {
            systemPodsOn.state = NSControl.StateValue(rawValue: 1)
        } else {
            systemPodsOff.state = NSControl.StateValue(rawValue: 1)
        }
        kubectlPathField.textColor = NSColor(calibratedWhite: 0, alpha: 1)
        groupingLabelField.textColor = NSColor(calibratedWhite: 0, alpha: 1)
        sshPathTextField.textColor = NSColor(calibratedWhite: 0, alpha: 1)
    }
    
    @IBAction func systemPodsBtnPressed(_ sender: NSButton) {
        let selectedState = sender == self.systemPodsOn
        let errorStr = PreferenceData.sharedInstance.setShowSystemPods(newState: selectedState)
        dataUpdateHelper(errorStr: errorStr, associatedTxtField: nil)
    }
    
    @IBAction func unlabeledPodsBtnPressed(_ sender: NSButton) {
        let selectedState = sender == self.unlabeledPodsOn
        let errorStr = PreferenceData.sharedInstance.setShowUnlabeledPods(newState: selectedState)
        dataUpdateHelper(errorStr: errorStr, associatedTxtField: nil)
    }
    
    @IBAction func groupingLabelUpdateBtnPressed(_ sender: Any) {
        let currValue = self.groupingLabelField.stringValue
        let errorStr = PreferenceData.sharedInstance.setGroupingLabel(newLabelOpt: currValue)
        dataUpdateHelper(errorStr: errorStr, associatedTxtField: self.groupingLabelField)
    }
    
    @IBAction func kubectlUpdateBtnPressed(_ sender: Any) {
        let currValue = self.kubectlPathField.stringValue
        let errorStr = PreferenceData.sharedInstance.setKubePath(newPathOpt: currValue)
        dataUpdateHelper(errorStr: errorStr, associatedTxtField: self.kubectlPathField)
    }
    
    @IBAction func sshUpdateBtnPressed(_ sender: Any) {
        let currValue = self.sshPathTextField.stringValue
        let errorStr =  PreferenceData.sharedInstance.setSSHKeyPath(newPath: currValue)
        dataUpdateHelper(errorStr:errorStr, associatedTxtField: self.sshPathTextField)
    }
    
    //used to update the UI after attempting to change a field
    private func dataUpdateHelper(errorStr:String?, associatedTxtField:NSTextField?){
        if let field = associatedTxtField{
            field.textColor = NSColor(calibratedWhite: 0, alpha: 1)
        }
        self.errorTextField.stringValue = errorStr ?? ""
        loadFromPreferenceStore()
    }
    
    
    @IBAction func quitBtnPressed(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        if let field = obj.object as? NSTextField{
            field.textColor = NSColor(calibratedWhite: 0.4, alpha: 1)
        }
    }
    
    @IBAction func resetBtnPressed(_ sender: Any) {
        self.errorTextField.stringValue = ""
        PreferenceData.sharedInstance.resetPreferences()
        loadFromPreferenceStore()
    }
    
}
