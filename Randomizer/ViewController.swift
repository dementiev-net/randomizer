//
//  ViewController.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 16.06.2022.
//
 
import Cocoa

class ViewController: NSViewController {
   
    var counter_g : TimeInterval = 0
    var counter_s : TimeInterval = 0
    let RANDINTERVAL = 10.0
    let ALERTTIME = 3600 // 1 Hour
    
    @IBOutlet weak var RndText: NSTextField!
    @IBOutlet weak var RaseLine: NSLevelIndicatorCell!
    @IBOutlet weak var TimeText: NSTextField!
    @IBOutlet weak var SessTimeText: NSTextField!
    
    @IBAction func Reset(_ sender: Any) {
        counter_g = 0
        self.TimeText.textColor = NSColor.systemGray
    }
    
    @IBAction func ResetColor(_ sender: Any) {
        Reset(sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // timer randomizer
        Timer.scheduledTimer(withTimeInterval: RANDINTERVAL, repeats: true) { (_) in

            let x = Int.random(in: 1..<100)
            self.RndText.stringValue = String(format: "%03d", x)

            var i = "0"
            if x >= 75 { i = "5" }
            else if x >= 66 { i = "4" }
            else if x >= 50 { i = "3" }
            else if x >= 33 { i = "2" }
            else if x >= 25 { i = "1" }
            else { i = "0" }
            self.RaseLine.stringValue = i
        }
        
        // timer time
        let dateFormatter : DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.zeroFormattingBehavior = .pad
            return formatter
        }()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
            self.counter_g += 1
            self.counter_s += 1
            self.TimeText.stringValue = dateFormatter.string(from: self.counter_g)!
            self.SessTimeText.stringValue = dateFormatter.string(from: self.counter_s)!
            if Int(self.counter_g) > self.ALERTTIME {
                self.TimeText.textColor = NSColor.red
            }
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

