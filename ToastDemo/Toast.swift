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
    
    static private var changes:[AnyClass] = []
    static private func isChange(cls:AnyClass) -> Bool {
        for objCls in changes {
            if objCls === cls { return true }
        }
        return false
    }

    static var fontSize:CGFloat = 13
    static var interval:CGFloat = 5     // 默认 Toast.Task 间隔
    
    static var tasksQueue:[Task] = []   // 显示 Toast.Task 队列
    static var cleanQueue:[Task] = []   // 移除 Toast.Task 队列
    static var activityTask:ActivityTask? = nil {
        willSet {
            if let task = activityTask {
                if task != newValue { cleanQueue.append(task) }
            }
        }
    }
    
    /// 显示活动等待视图
    static func makeActivity(controller:UIViewController, message:String) -> ActivityTask {
        return ActivityTask(controller: controller, message: message)
    }
    
    /// 显示自定义控制器的视图
    static func makeCustomView(controller:UIViewController, toastController:UIViewController, duration: NSTimeInterval = 8) -> Task {
        let task = Task(controller: controller, view:toastController.view)
        task.childController = toastController
        task.duration = duration
        
        return task
    }
    
    /// 显示带背景 View 的自定义控制器的视图
    static func makeView(controller:UIViewController, toastController:UIViewController, duration: NSTimeInterval = 8) -> Task {
        let task = makeView(controller, childView: toastController.view, duration: duration)
        task.childController = toastController
        return task
    }
    
    /// 显示自定义视图
    static func makeCustomView(controller:UIViewController, view:UIView, duration: NSTimeInterval = 8) -> Task {
        let task = Task(controller: controller, view:view)
        task.duration = duration
        
        return task
    }
    
    /// 显示带背景 View 的自定义视图
    static func makeView(controller:UIViewController, childView child:UIView, duration: NSTimeInterval = 8) -> Task {
        
        let insets = child.layoutMargins

        let view = UIView(frame: CGRect(x: 0, y: 0, width: child.frame.width + insets.left + insets.right, height: child.frame.height + insets.top + insets.bottom))
        
        view.backgroundColor = UIColor(white: 0.2, alpha: 0.6)
        view.layer.cornerRadius = view.frame.height / 2
        view.layer.shadowColor = UIColor.blackColor().CGColor
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.addSubview(child)
        
        return makeCustomView(controller, view: view, duration: duration)
    }
    
    /// 显示文本通知视图
    static func makeText(controller:UIViewController, message:String, duration: NSTimeInterval = 8) -> Task {
        
        let insets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
        
        let label:UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(Toast.fontSize)
        label.numberOfLines = 0
        label.text = message
        label.textColor = UIColor.whiteColor()
        label.layoutMargins = insets
        label.sizeToFit()
        label.frame.origin = CGPoint(x: insets.left, y: insets.top)
 
        return makeView(controller, childView: label, duration: duration)
    }
    
    static func taskFilterWithController(controller:UIContentContainer) -> [Task] {
        var tasks:[Task] = []
        
        // 显示活动状态 Activity
        if let task = activityTask where controller.isEqual(task.viewController) {
            tasks.append(task)
        }
        
        // 要显示的 Toast.Task
        for task:Task in tasksQueue where controller.isEqual(task.viewController) {
            tasks.append(task)
        }
        
        return tasks
    }
    
    static private func registerViewControllerClass<T : UIViewController>(cls:T.Type) {
        if !isChange(cls) {
            changes.append(cls)
            
            //print("register cls : \(cls)")
            
            let viewDidDisappearSelector = Selector("viewDidDisappear:")
            let taskDidDisappearSelector = Selector("taskDidDisappear:")
            let selfDidDisappearSelector = Selector("__selfDidDisappear:")
            
            let viewDidDisappearMethod = class_getInstanceMethod(cls, viewDidDisappearSelector)
            let taskDidDisappearMethod = class_getInstanceMethod(cls, taskDidDisappearSelector)
            
            let taskDidDisappearIMP = method_getImplementation(taskDidDisappearMethod)
            
            var viewDidDisappearIMP:IMP = nil
            // 如果对象 没有 override func viewDidDisappear 则创建一个 并跳转到 taskDidDisappear
            if !class_addMethod(cls, viewDidDisappearSelector, taskDidDisappearIMP, method_getTypeEncoding(viewDidDisappearMethod)) {
                
                // 如果 存在 override func viewDidDisappear 则将函数指针替换为 taskDidDisappear
                viewDidDisappearIMP = class_replaceMethod(cls, viewDidDisappearSelector, taskDidDisappearIMP, method_getTypeEncoding(viewDidDisappearMethod))
                
                // 并且 创建/替换 一个 __selfDidDisappear 函数为原 override func viewDidDisappear 的指针, 用于回调
                if !class_addMethod(cls, selfDidDisappearSelector, viewDidDisappearIMP, method_getTypeEncoding(viewDidDisappearMethod)) {
                    class_replaceMethod(cls, selfDidDisappearSelector, viewDidDisappearIMP, method_getTypeEncoding(viewDidDisappearMethod))
                }
            }

        }
    }
    
    static private var afterBlock:dispatch_block_t?
    static private func animateTasks(isAfter:Bool = false) {
        let currentTime = CACurrentMediaTime()

        let screenSize = UIApplication.sharedApplication().keyWindow?.frame.size ?? UIScreen.mainScreen().bounds.size
        let startY = screenSize.height * 0.75
        var offsetY:CGFloat = 0

        // 处理队列中要显示的
        
        var minDismissTime:NSTimeInterval = 0
        
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
                
                // 隐藏 等待状态 Toast.Task 的子视图
                for view in task.view.subviews where !view.hidden {
                    view.hidden = true
                }
            } else {
                // 显示 等待状态 Toast.Task 的子视图
                for view in task.view.subviews where view.hidden {
                    view.hidden = false
                }
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
                if let controller = task.childController {
                    task.viewController?.addChildViewController(controller)
                }
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
                task.childController?.removeFromParentViewController()
            }
            cleanQueue.removeAll()
        }
        
        // 如果没有延时回调 则计算最小延时回调时间
        if Toast.afterBlock == nil && minDismissTime > 0 {

            Toast.afterBlock = {
                Toast.afterBlock = nil
                Toast.animateTasks(true)
            }
            
            let delay:NSTimeInterval = (minDismissTime - currentTime + 0.01) * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))

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
            label.font = UIFont.systemFontOfSize(Toast.fontSize)
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
            view.backgroundColor = UIColor(white: 0.2, alpha: 0.6)

            view.layer.cornerRadius = 8
            
            view.layer.shadowColor = UIColor.blackColor().CGColor
            view.layer.shadowOpacity = 0.8
            view.layer.shadowOffset = CGSize(width: 0, height: 2)
            
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
        weak var childController:UIViewController?
        
        var duration:NSTimeInterval = 0
        var dismissTime:NSTimeInterval = 0
        var defaultSize:CGSize
        var frame:CGRect = CGRect.zeroRect
        var alpha:CGFloat = 1

        init(controller:UIViewController, view:UIView) {
            
            self.viewController = controller
            self.view = view
            self.defaultSize = view.bounds.size
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
 
    public override class func initialize() {
        Toast.registerViewControllerClass(self)
    }
    
    func __selfDidDisappear(animated: Bool) {
        print("此方法用于回调原 ViewController 的 viewDidDisappear 函数指针被替换")
    }
    
    final func taskDidDisappear(animated: Bool) {
        self.__selfDidDisappear(animated)  // 回调原 viewWillDisappear
        
        print("已还原 self=\(self)")
        // 视图离开时换回来 并删除 此视图控制器的 Toast.Task
        for task in Toast.taskFilterWithController(self) {
            task.hideLater()
        }
        Toast.animateTasks()

    }
}
