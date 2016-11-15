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
    var contents = [
        "克里斯蒂就发了看电视",
        "凌空街道史莱克吉林省卡机佛问尽量快点发咯问j",
        "刻录机付了款撒点击离开的介绍了控件凯利斯大姐夫两点上课就离开绝对是离开家唠嗑束带结发凌空街道撒龙卷风拉德斯",
        "可怜的撒就发了控件",
        "唠嗑解放啦看数据发连哭都是就离开发就萨拉丁就发了;as 角度来看家乐福就是大立科技发流口水就打了看附近连哭都是",
        "连哭都是积分唠嗑受打击了看发就是大立科技发"
        
    ]
    var index:Int = 0
    @IBAction func onToast(_ sender:AnyObject!) {
        if index >= contents.count { index = 0 }
        Toast.makeText(self, message: "Toast \(contents[index])", duration: 3).show()
        index += 1
    }
    @IBAction func onClose(_ sender:AnyObject!) {
        if Toast.windowModalTask === nil {
//            if Toast.windowTask === nil {
//                Toast.makeNotificationOnTop(self, message: "notification content:\(++index)").show()
//            } else {
//                Toast.windowTask?.hide()
//            }
            index += 1
            Toast.makeNotificationOnBottom(self, message: "notification content:\(index)").show()
        } else {
            Toast.windowModalTask?.hide()
        }
    }
    @IBAction func onNotificationClick(_ sender:AnyObject!) {
        //Toast.makeNotification(self, message: "notification \(++index)", style: .ModalCanCancel([.Up, .Down])).show()
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "TestTableController")// as! ViewController
        controller.view.frame.size = CGSize(width: 300, height: 250)
        controller.view.frame.origin.x = (UIScreen.main.bounds.width - 300) / 2
        controller.view.frame.origin.y = (UIScreen.main.bounds.height - 250) / 2
        
        Toast.makeWindow(self, toastController: controller, style: .modalCanCancel(cancelDirection: [.up, .down]))
            .setAutoresizingMask([.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin])
            .show()
    }
    @IBAction func onButtonClick(_ sender:AnyObject!) {
        switch textBox.highlightState {
        case .default:
            textBox.highlightState = UITextBoxHighlightState.validator("ok")
        case .validator:
            textBox.highlightState = UITextBoxHighlightState.warning("warning")
        case .warning:
            textBox.highlightState = UITextBoxHighlightState.wrong("wrong")
        case .wrong:
            textBox.highlightState = UITextBoxHighlightState.default
        }
        if let activityToast = Toast.activityTask {
            activityToast.hide()
        } else {
            index += 1
            Toast.makeActivity(self, message: "activity view is show:\(index)", style: .none(timeout: 300)).show()
        }
        //textBox.highlightState = UITextBoxHighlightState.Validator("ok")
        //Toast.makeActivity(self, message: "This is a activity toast").show()
//        if let controller = self.storyboard?.instantiateViewControllerWithIdentifier("TosatViewController") {
//            controller.view.frame.size = CGSize(width: 100, height: 40)
//            Toast.makeView(self, toastController: controller).show()
//        }
    }
    
    @IBOutlet var textBox:UITextBox!

    override func viewDidDisappear(_ animated: Bool) {
        //super.viewWillDisappear(animated)
        print("viewDidDisappear View")
    }
}

