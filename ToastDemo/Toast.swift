//
//  Toast.swift
//  DemoNavigationMore
//
//  Created by 慧趣小歪 on 15/7/20.
//  Copyright © 2015年 慧趣小歪. All rights reserved.
//

import UIKit

//extension Set {
//    subscript (index:Int) -> Element {
//        return self[advance(self.startIndex, index)]
//    }
//}

func ==(lhs: Toast.Task, rhs: Toast.Task) -> Bool {
    return lhs.view == rhs.view
}

struct Toast {
    
    
    
    static var interval:CGFloat = 5
    // 即将显示的视图及控制器队列
    static var threadQueue = NSOperationQueue()
    
    static var tasksQueue:[Task] = []
    static var cleanQueue:[Task] = []
    static var activityTask:ActivityTask? = nil
    
    static func makeActivity(controller:UIViewController, message:String) -> ActivityTask {
        let task = ActivityTask(controller: controller, message: message)
        task.duration = 300000
        
        return task
    }
    
    static func makeText(controller:UIViewController, message:String, duration: NSTimeInterval) -> Task {
        
        let label:UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(13)
        label.numberOfLines = 0
        label.text = "  \(message)  "
        label.textColor = UIColor.whiteColor()
        label.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
        label.layoutMargins = UIEdgeInsets(top: 2, left: 15, bottom: 2, right: 15)
        label.sizeToFit()
        label.layer.masksToBounds = true
        label.layer.cornerRadius = label.frame.height / 2

        let task = Task(controller: controller, view:label)
        task.duration = duration
        
        return task
        
    }
    
    static private var afterBlock:dispatch_block_t?
    static private func animateTasks(isAfter:Bool = false) {
        
        let currentTime = CACurrentMediaTime()

        let screenSize = UIApplication.sharedApplication().keyWindow?.frame.size ?? UIScreen.mainScreen().bounds.size
        let startY = screenSize.height * 0.75
        
        // 处理队列中要显示的
        
        var minDismissTime:NSTimeInterval = 0
        var offsetY:CGFloat = 0
        
        // 将超时的 Toast.Task 都加入移除队列
        for var i:Int = tasksQueue.count - 1; i>=0; i-- {
            let task = tasksQueue[i]

            // 如果 Toast.Task 超时 则加入移除数组
            if currentTime > task.dismissTime {
                cleanQueue.append(task)
                tasksQueue.removeAtIndex(i)
            } else if minDismissTime > task.dismissTime || minDismissTime == 0 {
                // 否则获取最小消失时间
                minDismissTime = task.dismissTime
            }
        }
        
        // 所有需显示的
        for var i:Int = tasksQueue.count - 1; i>=0; i-- {
            let task = tasksQueue[i]
            //print("begin i:\(i)")
            
            var size = task.defaultSize
            var x = (screenSize.width - size.width) / 2
            var y = startY - offsetY
            offsetY += task.view.frame.height + interval

            if i > 2 {
                let side = task.view.layer.cornerRadius * 2
                y = startY + side + interval
                x = (screenSize.width - CGFloat(tasksQueue.count - 3) * (side + interval)) / 2 + CGFloat(i - 3) * (side + interval)
                size = CGSize(width: side, height: side)
                offsetY = 0
                
                // 给未显示的 Toast.Task 补时间
                if isAfter { tasksQueue[i].dismissTime += minDismissTime - currentTime }
                print("task i:\(i) time:\(tasksQueue[i].dismissTime)")

            }
            //print("task i:\(i) x:\(x) y:\(y) offsetY:\(offsetY)")

            // 如果尚未显示则动画出现
            if task.view.superview == nil {
                task.view.alpha = 0.2
                task.view.frame.origin = CGPointMake(x, y + 30)
                task.view.frame.size = size
                UIApplication.sharedApplication().keyWindow?.addSubview(task.view)
            }
            
            task.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            task.alpha = 1

        }
        
        
        if let task = activityTask {
            
            
            let size = task.view.frame.size
            task.frame.size = size
            task.frame.origin = CGPoint(x: (screenSize.width - size.width) / 2, y: (screenSize.height - size.height) / 2)
            
            if task.view.superview == nil {
                
                var frame = task.frame
                frame.origin.y = frame.midY + 30
                task.view.frame = frame
                UIApplication.sharedApplication().keyWindow?.addSubview(task.view)
            }
        }
        
        // 将要移除的列表
        for task in cleanQueue {
            task.alpha = 0
            task.frame = task.view.frame
            task.frame.origin.y = task.frame.minY - task.frame.height
        }
        
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
            
            // 显示活动状态 Activity
            if let task = activityTask {
                task.view.alpha = task.alpha
                task.view.frame = task.frame
            }
            
            // 对要显示的 Toast.Task 进行动画
            for task:Task in tasksQueue {
                task.view.alpha = task.alpha
                task.view.frame = task.frame
            }
            
            // 对要移除的 Toast.Task 进行动画
            for task:Task in cleanQueue {
                task.view.alpha = task.alpha
                task.view.frame = task.frame
            }
            
        }) { (finish) -> Void in
            // 动画结束时 将移除列表清空
            for task in cleanQueue {
                task.view.removeFromSuperview()
                task.viewController?.removeToastTask(task)
            }
            cleanQueue.removeAll()
        }
        
        // 如果没有延时回调 则计算最小延时回调时间
        if Toast.afterBlock == nil && minDismissTime > 0 {

            Toast.afterBlock = {
                //print("delay : \(CACurrentMediaTime())")
                Toast.afterBlock = nil
                Toast.animateTasks(true)
            }
            
            let delay:NSTimeInterval = (minDismissTime - currentTime + 0.01) * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            //print("begin : \(minDismissTime - currentTime)")

            dispatch_after(time, dispatch_get_main_queue(), Toast.afterBlock!)
        }
        
//        CACurrentMediaTime()
//        mach_absolute_time()
//        CFAbsoluteTimeGetCurrent()
    }
    
    class ActivityTask : Task {
        
        var activityView:UIActivityIndicatorView
        var label:UILabel
        
        init(controller:UIViewController, message:String) {
            let view = UIView()
            
            label = UILabel()
            label.font = UIFont.systemFontOfSize(13)
            label.numberOfLines = 1
            label.text = "  \(message)  "
            label.textColor = UIColor.whiteColor()
            label.layoutMargins = UIEdgeInsets(top: 2, left: 15, bottom: 2, right: 15)
            label.sizeToFit()
            label.lineBreakMode = NSLineBreakMode.ByTruncatingTail
            
            activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
            activityView.sizeToFit()
            activityView.startAnimating()
            
            
            //print("activityView.frame.height:\(activityView.frame.width)")
            view.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
            view.layer.masksToBounds = true
            view.layer.cornerRadius = 7
            view.frame.size = CGSize(width: max(label.frame.width, activityView.frame.width), height: label.frame.height + activityView.frame.height + Toast.interval * 4)
            
            activityView.frame.origin = CGPoint(x: (view.frame.width - activityView.frame.width) / 2, y: Toast.interval * 2)
            label.frame.origin = CGPoint(x: (view.frame.width - label.frame.width) / 2, y: view.bounds.maxY - Toast.interval - label.frame.height)
            
            view.addSubview(activityView)
            view.addSubview(label)
            
            super.init(controller: controller, view: view)
        }
        
        override func show() {
            hideLater()
            Toast.activityTask = self
            Toast.animateTasks()
        }
        
        override func hide() {
            hideLater()
            Toast.animateTasks()
        }
        
        override func hideLater() {
            if let currentTask = Toast.activityTask {
                Toast.cleanQueue.append(currentTask)
                Toast.activityTask = nil
            }
        }
    }
    
    class Task : Equatable {
        
        let view:UIView
        weak var viewController:UIViewController?
        
        var duration:NSTimeInterval = 0
        var dismissTime:NSTimeInterval = 0
        var defaultSize:CGSize
        var frame:CGRect = CGRect.zeroRect
        var alpha:CGFloat = 1

        init(controller:UIViewController, view:UIView) {
            
            self.viewController = controller
            self.view = view
            self.defaultSize = view.bounds.size

            controller.addToastTask(self)
        }
        
        func show() {
            dismissTime = CACurrentMediaTime() + duration   // 计算消失时间
            if let _ = Toast.tasksQueue.indexOf(self) {
                return
            }
            Toast.tasksQueue.append(self)
            Toast.animateTasks()
        }
        
        func hide() {
            hideLater()
            Toast.animateTasks()
        }
        
        func hideLater() {
            if let index = Toast.tasksQueue.indexOf(self) {
                Toast.tasksQueue.removeAtIndex(index)
            }
            if let _ = Toast.cleanQueue.indexOf(self) {
                return
            }
            Toast.cleanQueue.append(self)
        }
        
    }
}

extension UIViewController {
    
    private struct AssociatedKeys {
        static var ToastTaskName = "ttk_ToastTaskKey"
    }
    
    private var toastTasks:NSMutableArray {
        set(tasks) {
            objc_setAssociatedObject(self, &AssociatedKeys.ToastTaskName, tasks, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let tasks = objc_getAssociatedObject(self, &AssociatedKeys.ToastTaskName) as? NSMutableArray {
                return tasks
            }
            let tasks:NSMutableArray = []
            objc_setAssociatedObject(self, &AssociatedKeys.ToastTaskName, tasks, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return tasks
        }
    }
    
    func addToastTask(task:Toast.Task) {
        if toastTasks.count == 0 {
            // 第一次进入时 交换 viewWillDisappear 函数
            let viewDidDisappearMethod = class_getInstanceMethod(object_getClass(self), Selector("viewDidDisappear:"))
            let toastDidDisappearMethod = class_getInstanceMethod(object_getClass(self), Selector("toastDidDisappear:"))
            
            method_exchangeImplementations(viewDidDisappearMethod, toastDidDisappearMethod)

            print("已替换")
        }
        toastTasks.addObject(task)
    }
    
    func removeToastTask(task:Toast.Task) {
        let index = toastTasks.indexOfObject(task)
        if index != NSNotFound  {
            toastTasks.removeObjectAtIndex(index)
        }
    }
    
    func toastDidDisappear(animated: Bool) {
        print("viewDidDisappear Toast")
        self.toastDidDisappear(animated) // 回调原 viewWillDisappear
        
        // 视图离开时换回来 并删除 此视图控制器的 Toast.Task
        for task:AnyObject in toastTasks {
            (task as! Toast.Task).hide()
        }
        toastTasks = []
        Toast.animateTasks()

        let viewDidDisappearMethod = class_getInstanceMethod(object_getClass(self), Selector("viewDidDisappear:"))
        let toastDidDisappearMethod = class_getInstanceMethod(object_getClass(self), Selector("toastDidDisappear:"))
        
        method_exchangeImplementations(viewDidDisappearMethod, toastDidDisappearMethod)
    }
}
