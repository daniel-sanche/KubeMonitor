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

class HeaderItem: NSCollectionViewItem {

    @IBOutlet weak var textLabel: NSTextField!
    @IBOutlet weak var image: NSImageView!
    @IBOutlet weak var disclosureButton: NSButton!
    private var associatedModel : GroupModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    // called when the disclosure arrow is pressed. Flips the collapsed state in the model, and reload the table
    @IBAction func disclosurePressed(_ sender: NSControl) {
        let newState = !Bool(sender.integerValue as NSNumber)
        associatedModel?.collapsed = newState
        self.collectionView!.reloadData()
    }
    
     // change the model associated with the cell. Update the view
     func setUpWithGroup(model:GroupModel){
        self.textLabel.stringValue = model.name + " (\(model.numberRunning())/\(model.numPods()))"
        self.associatedModel = model
        self.disclosureButton.state = Int(!model.collapsed as NSNumber)
        self.textLabel.textColor = NSColor.colorForPhase(phase: model.getWorstPhase())
    }
    
}
