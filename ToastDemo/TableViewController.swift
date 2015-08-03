//
//  TableViewController.swift
//  ToastDemo
//
//  Created by 招利 李 on 15/7/21.
//  Copyright © 2015年 招利 李. All rights reserved.
//

import UIKit

struct TestData {
    var hasValue:Int
    var text:String
    init (_ hasValue:Int, _ text:String) {
        self.hasValue = hasValue
        self.text = text
    }
}

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorInset.left = 0
        //tableView.layoutMargins.left = 0
        
        var startTime = CACurrentMediaTime()
        let length = 10000000
        
        
        let pointer = UnsafeMutablePointer<Int>.alloc(length)
        for var i:Int=0; i<length; i++ {
            pointer.advancedBy(i).initialize(i)
        }
        print("指针初始化时间:\(CACurrentMediaTime() - startTime)")
        
        startTime = CACurrentMediaTime()
        var dataPointer = UnsafeMutablePointer<TestData>.alloc(length)
        for var i:Int=0; i<length; i++ {
            dataPointer.advancedBy(i).initialize(TestData(i,"abc"))
        }
        print("指针对象初始化时间:\(CACurrentMediaTime() - startTime)")

        startTime = CACurrentMediaTime()
        var array:Array<Int> = []
        for var i:Int=0; i<length; i++ {
            array.append(i)
        }
        print("数组初始化时间:\(CACurrentMediaTime() - startTime)")
        
        startTime = CACurrentMediaTime()
        let oarray:OArray<Int> = OArray<Int>()
        for var i:Int=0; i<length; i++ {
            oarray.append(i)
        }
        print("自定义数组初始化时间:\(CACurrentMediaTime() - startTime)")
        
        startTime = CACurrentMediaTime()
        for var i:Int=0; i<length; i++ {
            if oarray[i] == length { break }
        }
        print("自定义数组比较时间:\(CACurrentMediaTime() - startTime)")
        
        startTime = CACurrentMediaTime()
        for var i:Int=0; i<length; i++ {
            if array[i] == length { break }
        }
        print("数组比较时间:\(CACurrentMediaTime() - startTime)")

        startTime = CACurrentMediaTime()
        for var i:Int=0; i<length; i++ {
            if pointer.advancedBy(i).memory == length { break }
        }
        print("指针比较时间:\(CACurrentMediaTime() - startTime)")
        
        startTime = CACurrentMediaTime()
        for var i:Int=0; i<length; i++ {
            if dataPointer.advancedBy(i).memory.hasValue == length { break }
        }
        print("指针对象比较时间:\(CACurrentMediaTime() - startTime)")
        //let a:OrderedSet<String> = OrderedSet<String>()
//        var dict:Dictionary<String, String> = [:]
//        dict["3"] = "三"
//        dict["1"] = "一"
//        dict["2"] = "二"
//        dict["4"] = "四"
//        let pointer = UnsafeMutablePointer<Dictionary<String, String>>(unsafeAddressOf(dict))
//        //let pointer = UnsafeMutablePointer<Dictionary<String, String>>(&dict)
//        //dict.keys.array[1] = "9"
//        print(dict)
//        dict["1"] = nil
//        dict["6"] = "六"
//        dict["7"] = "七"
//
//        for (key, value) in dict {
//            print("\(key):\(value)")
//        }
//        for value in dict.values {
//            print("value:\(value)")
//        }
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.separatorInset.left = 0
        cell.layoutMargins.left = 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var index:Int = 0
    @IBAction func onToast(sender:AnyObject!) {
        //print("showToast")
        //Toast.makeActivity(self, message: "activity view \(++index)").show()
        //Toast.makeNotification(self, message: "isadlkfjlkadsjflkasdjlkf jsdlkajflkadsjflkjadslfjal;sdkj ljdsklajf lkjasljf s to later = \(++index)", style: .None(5)).show()
        //Toast.makeActivity(self, message: "need activity : \(++index)", style: .None(300)).show()
        if let activityToast = Toast.activityTask {
            activityToast.hide()
        } else {
            Toast.makeActivity(self, message: "activity view is show:\(++index)", style: .None(timeout: 300)).show()
        }
        
        //Toast.makeText(self, message: "Toast \(++index)", duration: 3).show()

    }
    
    @IBAction func onActivityToast(sender:AnyObject) {
        if let activityToast = Toast.activityTask {
            activityToast.hide()
        } else {
            Toast.makeActivity(self, message: "activity view is show:\(++index)", style: .None(timeout: 300)).show()
        }
    }
//    override func viewDidDisappear(animated: Bool) {
//        super.viewWillDisappear(animated)
//        print("viewDidDisappear Table")
//    }


    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
