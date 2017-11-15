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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var rightClickMenu: NSMenu!
    private let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    private let popOver = NSPopover()
    private var eventMonitor: EventMonitor?
    private var mainController : MainViewController?

    
    // called when the process launches
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //set the status icon
        if let button = statusItem.button {
            let icon = NSImage(named:Constants.StatusImageName)
            icon?.isTemplate = true
            button.image = icon
            button.action = #selector(statusBtnPressed(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        //set up the view controller
        popOver.contentViewController = MainViewController.freshController()
        self.mainController = popOver.contentViewController as? MainViewController
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popOver.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
    }

    // show/hide the popover view
    func togglePopover(_ sender: Any?) {
        if popOver.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    //detect whether a right or left click was sent, and handle the action appropriately
    @objc func statusBtnPressed(_ sender: Any?){
        let event:NSEvent! = NSApp.currentEvent!
        if (event.type == .rightMouseUp) {
            statusItem.popUpMenu(self.rightClickMenu)
        }
        else {
            togglePopover(sender)
        }
    }
    
    //display the popover on screen, and start monitoring for click events
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popOver.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        self.eventMonitor?.start()
        self.refreshCycle()
        
    }
    
    //close the popover, and stop monitoring clicks
    public func closePopover(sender: Any?) {
        popOver.performClose(sender)
        self.eventMonitor?.stop()
    }
    
    //reloads the data on the main view controller
    func reloadData(){
        if let vc = self.mainController{
            vc.refreshData()
        }
    }
    
    //continuously refresh data, until the popover is closed
    func refreshCycle(){
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.RefreshInterval, execute: {
            if self.popOver.isShown {
                self.reloadData()
                print("Refreshed")
                self.refreshCycle()
            }
        })
    }


}

