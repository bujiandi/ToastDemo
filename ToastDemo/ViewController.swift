//
//  ViewController.swift
//  ToastDemo
//
//  Created by 招利 李 on 15/7/21.
//  Copyright © 2015年 招利 李. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var index:Int = 0
    @IBAction func onToast(sender:AnyObject!) {
        Toast.makeText(self, message: "Toast \(++index)", duration: 3).show()
    }

    override func viewWillDisappear(animated: Bool) {
        print("viewWillDisappear View")
    }
}

