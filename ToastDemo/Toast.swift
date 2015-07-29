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

public func ==(lhs: Toast.Task, rhs: Toast.Task) -> Bool {
    return lhs.view === rhs.view
}

public func ==(lhs: ToastWindowStyle, rhs: ToastWindowStyle) -> Bool {
    switch (lhs, rhs) {
    case (.None , .None ): return true
    case (.Modal, .Modal): return true
    case (.ModalCanCancel(let lDirection), .ModalCanCancel(let rDirection)):
        return lDirection == rDirection
    default: return false
    }
}

extension UISwipeGestureRecognizerDirection {
    static var Tap: UISwipeGestureRecognizerDirection { return UISwipeGestureRecognizerDirection(rawValue: 0) }
}

public enum ToastWindowStyle : Equatable {
    case None, Modal, ModalCanCancel (UISwipeGestureRecognizerDirection)
    var isModal:Bool { return self != .None }
}

public struct Toast {
    
    static private var changes:[AnyClass] = []
    static private func isChange(cls:AnyClass) -> Bool {
        for objCls in changes {
            if objCls === cls { return true }
        }
        return false
    }

    static public var fontSize:CGFloat = 13
    static public var interval:CGFloat = 5     // 默认 Toast.Task 间隔
    
    static public var tasksQueue:[Task] = []   // 显示 Toast.Task 队列
    static public var cleanQueue:[Task] = []   // 移除 Toast.Task 队列
    static public var windowQueue:[WindowTask] = [] // 窗口式 Toast.WindowTask 等待显示队列
    static public var activityTask:ActivityTask? = nil {
        willSet {
            if let task = activityTask {
                if task != newValue { cleanQueue.append(task) }
            }
        }
    }
    static public var windowTask:WindowTask? = nil {
        willSet {
            if let task = windowTask {
                if task != newValue { cleanQueue.append(task) }
            }
        }
    }
    static private var _overlayWindow:UIWindow? = nil
    static private var overlayWindow:UIWindow {
        
        if _overlayWindow == nil {
            let window = UIWindow(frame: UIApplication.sharedApplication().keyWindow?.frame ?? UIScreen.mainScreen().bounds)
            window.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            window.userInteractionEnabled = true    // 支持手势
            window.windowLevel = UIWindowLevelStatusBar
            window.transform = UIApplication.sharedApplication().keyWindow?.transform ?? CGAffineTransformIdentity
            _overlayWindow = window
        }
        return _overlayWindow!
    }
    
    static public func makeNotification(controller:UIViewController, message:String, style:ToastWindowStyle = .Modal) -> WindowTask {
        let label = makeLabel(message)
        label.backgroundColor = UIColor.darkGrayColor()
        //label.frame.origin = CGPoint(x: 100, y: 200)
        return makeNotification(controller, view: label, style: style)
    }
    
    static public func makeNotification(controller:UIViewController, view:UIView, style:ToastWindowStyle = .Modal) -> WindowTask {
        
        
        let insets = view.layoutMargins
        let screenSize = UIApplication.sharedApplication().keyWindow?.frame.size ?? UIScreen.mainScreen().bounds.size
        let backgroundView = UIView(frame: CGRect(x: 0, y: view.frame.minY, width: screenSize.width, height: view.frame.height + insets.top + insets.bottom))

        view.frame.origin = CGPoint(x: (screenSize.width - view.frame.width) / 2, y: insets.top)
        backgroundView.addSubview(view)
        backgroundView.backgroundColor = view.backgroundColor
        backgroundView.layer.shadowColor = UIColor(white: 0.2, alpha: 1).CGColor
        backgroundView.layer.shadowOpacity = 0.8
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        let notification = WindowTask(controller: controller, view: backgroundView, style:style)
        
        return notification
    }
    
    /// 显示活动等待视图
    static public func makeActivity(controller:UIViewController, message:String) -> ActivityTask {
        return ActivityTask(controller: controller, message: message)
    }
    
    /// 显示自定义控制器的视图
    static public func makeCustomView(controller:UIViewController, toastController:UIViewController, duration: NSTimeInterval = 8) -> Task {
        let task = Task(controller: controller, view:toastController.view)
        task.childController = toastController
        task.duration = duration
        
        return task
    }
    
    /// 显示带背景 View 的自定义控制器的视图
    static public func makeView(controller:UIViewController, toastController:UIViewController, duration: NSTimeInterval = 8) -> Task {
        let task = makeView(controller, childView: toastController.view, duration: duration)
        task.childController = toastController
        return task
    }
    
    /// 显示自定义视图
    static public func makeCustomView(controller:UIViewController, view:UIView, duration: NSTimeInterval = 8) -> Task {
        let task = Task(controller: controller, view:view)
        task.duration = duration
        
        return task
    }
    
    /// 显示带背景 View 的自定义视图
    static public func makeView(controller:UIViewController, childView child:UIView, duration: NSTimeInterval = 8) -> Task {
        
        let insets = child.layoutMargins
        let font = UIFont.systemFontOfSize(Toast.fontSize)
        let maxHeight = font.lineHeight * 2
        
        child.frame.origin = CGPoint(x: insets.left, y: insets.top)

        let view = UIView(frame: CGRect(x: 0, y: 0, width: child.frame.width + insets.left + insets.right, height: child.frame.height + insets.top + insets.bottom))
        
        view.backgroundColor = UIColor(white: 0.2, alpha: 0.6)
        view.layer.cornerRadius = (view.frame.height > maxHeight ? font.lineHeight : view.frame.height) / 2
        view.layer.shadowColor = UIColor.blackColor().CGColor
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.addSubview(child)
        
        return makeCustomView(controller, view: view, duration: duration)
    }
    
    /// 显示文本通知视图
    static public func makeText(controller:UIViewController, message:String, duration: NSTimeInterval = 8) -> Task {
        return makeView(controller, childView: makeLabel(message), duration: duration)
    }
    
    // 根据文本内容创建 UILabel
    static private func makeLabel(message:String) -> UILabel {
        let screenSize = UIApplication.sharedApplication().keyWindow?.frame.size ?? UIScreen.mainScreen().bounds.size
        let insets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
        let screenWidth = screenSize.width - insets.left - insets.right
        
        let label:UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(Toast.fontSize)
        label.numberOfLines = 3
        label.text = message
        label.textColor = UIColor.whiteColor()
        label.layoutMargins = insets
        //label.sizeToFit()
        let size = label.sizeThatFits(CGSize(width: screenWidth, height: label.font.lineHeight * CGFloat(label.numberOfLines)))
        
        //label.frame.origin = CGPoint(x: insets.left, y: insets.top)
        label.frame.size = size

        return label
    }
    static private func indexOfFirstNoneStyleWindowTask() -> Int {
        for var i:Int = 0; i<windowQueue.count; i++ {
            if !windowQueue[i].style.isModal { return i }
        }
        return 0
    }
    static private func taskFilterWithController(controller:UIViewController) -> [Task] {
        var tasks:[Task] = []
        
        // 显示活动状态 Activity
        if let task = activityTask {
            if let viewController = task.viewController where controller.isEqual(viewController) {
                tasks.append(task)
            }
        }
        
        // 要显示的 Toast.Task
        for task:Task in tasksQueue {
            if let viewController = task.viewController where controller.isEqual(viewController) {
                tasks.append(task)
            }
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
    
    static private var minDismissTime:NSTimeInterval {
        var minDismissTime:NSTimeInterval = 0
        let currentTime = CACurrentMediaTime()

        for task in tasksQueue {
            if currentTime > task.dismissTime {
            } else if minDismissTime > task.dismissTime || minDismissTime == 0 {
                // 否则获取最小消失时间
                minDismissTime = task.dismissTime
            }
        }
        return minDismissTime - currentTime
    }
    static private var _afterBlock:dispatch_block_t?
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
        
        // 计算最小更新时间
        for task in windowQueue where !task.style.isModal {
            if minDismissTime > task.dismissTime { minDismissTime = task.dismissTime }
        }
        
        // 下次动画时间 不小于一次动画的间隔
        let animateTime = max(minDismissTime - currentTime + 0.05, 0.351)
        
        // 所有需显示的
        for var i:Int = tasksQueue.count - 1; i>=0; i-- {
            let task = tasksQueue[i]
            
            var size = task.defaultSize
            var x:CGFloat = (screenSize.width - size.width) / 2
            var y:CGFloat = startY - offsetY - size.height
            offsetY += task.view.frame.height + interval

            if i > 2 {
                // 计算等待的 Toast.Task 位置
                task.view.layer.cornerRadius = 8
                let side:CGFloat = 16//task.view.layer.cornerRadius * 2
                y = startY + interval
                x = (screenSize.width - CGFloat(tasksQueue.count - 3) * (side + interval)) / 2 + CGFloat(i - 3) * (side + interval)
                size = CGSize(width: side, height: side)
                offsetY = 0
                
                // 给未显示的 Toast.Task 补时间
                if isAfter {
                    tasksQueue[i].dismissTime += animateTime
                }
                
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
                if let controller = task.childController {
                    task.viewController?.addChildViewController(controller)
                }
            }
            
            task.frame.origin = CGPoint(x: x, y: y)
            task.frame.size = size
            task.alpha = 1

        }
        
        // 如果当前显示的 Toast.WindowTask 非模态 则判断其是否超时
        if let task = windowTask where !task.style.isModal {
            if currentTime > task.dismissTime {
                windowTask = windowQueue.count > 0 ? windowQueue.removeAtIndex(0) : nil
            }
        }
        
        // 给未显示的 Toast.WindowTask 补时
        if isAfter {
            for task in windowQueue where !task.style.isModal {
                task.dismissTime += animateTime
            }
        }
        
        // 给将显示的 Toast.WindowTask 显示出来
        if let task = windowTask {
            if task.view.superview === nil {
                let window = overlayWindow
                
                if task.style.isModal {
                    window.frame = CGRect(origin: CGPoint.zeroPoint, size: screenSize)
                    window.backgroundColor = UIColor(white: 0.2, alpha: 0.6)
                    
                    if case .ModalCanCancel(let direction) = task.style {
                        // 如果是可自动终止的
                        let tap = UITapGestureRecognizer(target: task, action: Selector("hide:"))
                        let swipe = UISwipeGestureRecognizer(target: task, action: Selector("hide:"))
                        swipe.direction = direction
                        window.addGestureRecognizer(tap)
                        window.addGestureRecognizer(swipe)
                    }

                    task.frame = task.view.frame
                    task.view.frame.origin.y -= 30
                    print("这是模态窗口动画1")
                } else {
                    let frame = task.view.frame
                    window.frame = CGRect(x: frame.minX, y: frame.minY, width: min(frame.width, screenSize.width), height: min(frame.height, screenSize.height))
                    window.gestureRecognizers = nil
                    window.backgroundColor = task.view.backgroundColor
                    task.view.frame.origin = CGPoint(x: (screenSize.width - frame.width) / 2, y: 0)
                    task.frame = window.frame
                    window.frame.origin.y -= 30
                }
                window.alpha = 0
                task.alpha = 1
                window.addSubview(task.view)
            }
            _overlayWindow!.hidden = false
        }
        
/*
        if let task = notificationTask {
            if task.view.superview == nil {
                
                task.frame = task.view.frame
                task.view.frame.origin.y = task.mode.isTop ? -task.frame.height : screenSize.height
                UIApplication.sharedApplication().keyWindow?.addSubview(task.view)

                if task.mode.isModal {
                    let view = UIView(frame: CGRect(origin: CGPoint.zeroPoint, size: screenSize))
                    view.alpha = 0
                    view.backgroundColor = UIColor(white: 0.2, alpha: 0.6)
                    let tap = UITapGestureRecognizer(target: task, action: Selector("hide:"))
                    let swipe = UISwipeGestureRecognizer(target: task, action: Selector("hide:"))
                    swipe.direction = [.Up, .Down]
                    view.addGestureRecognizer(tap)
                    view.addGestureRecognizer(swipe)
                    task.modalView = view
                    UIApplication.sharedApplication().keyWindow?.insertSubview(view, belowSubview: task.view)
                } else {
                    
                }
            }
        }
*/
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
            if let windowTask = task as? WindowTask where !windowTask.style.isModal {
                task.frame = overlayWindow.frame
                task.frame.origin.y = overlayWindow.frame.minY - overlayWindow.frame.height
            } else {
                task.frame = task.view.frame
                task.frame.origin.y = task.frame.minY - task.frame.height
            }
            task.alpha = 0
        }
        
        UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
            
            if let task = windowTask {
                if task.style.isModal {
                    task.view.alpha = task.alpha
                    task.view.frame = task.frame
                    print("这是模态窗口动画2 frame:\(task.frame)")

                } else {
                    task.view.alpha = task.alpha
                    _overlayWindow?.frame = task.frame
                }
                _overlayWindow?.alpha = task.alpha
            }
            
            // 显示活动状态 Activity
            if let task = activityTask {
                task.view.alpha = task.alpha
                task.view.frame = task.frame
            }
            
            // 对要显示的 Toast.Task 进行动画
            for task:Task in tasksQueue {
                task.view.layer.cornerRadius = task.cornerRadius
                task.view.alpha = task.alpha
                task.view.frame = task.frame
            }
            
            // 对要移除的 Toast.Task 进行动画
            for task:Task in cleanQueue {
                if let windowTask = task as? WindowTask {
                    if windowTask.style.isModal {
                        //_overlayWindow?.alpha = 0
                        task.view.frame = task.frame
                    } else {
                        _overlayWindow?.frame = task.frame
                    }
                    _overlayWindow?.alpha = task.alpha
                } else {
                    task.view.alpha = task.alpha
                    task.view.frame = task.frame
                }
            }
            
        }) { (finish) -> Void in
            // 动画结束时 将移除列表清空
            var hasWindowTask:Bool = false
            for task in cleanQueue {
                hasWindowTask = hasWindowTask || task is WindowTask
                task.view.removeFromSuperview()
                task.childController?.removeFromParentViewController()
            }
            // 如果队列中再无 Toast.WindowTask 则移除窗口
            if hasWindowTask && windowQueue.count == 0 {
                _overlayWindow?.hidden = true
                _overlayWindow?.removeFromSuperview()
                _overlayWindow = nil
            }
            cleanQueue.removeAll()
        }
        
        // 如果没有延时回调 则计算最小延时回调时间
        if _afterBlock == nil && minDismissTime > 0 {

            _afterBlock = {
                _afterBlock = nil
                animateTasks(true)
            }
            
            let delay:NSTimeInterval = animateTime * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))

            dispatch_after(time, dispatch_get_main_queue(), _afterBlock!)
        }
        
//        CACurrentMediaTime()
//        mach_absolute_time()
//        CFAbsoluteTimeGetCurrent()
    }
/*
    public class NotificationTask : Task {
        
        let mode: ToastNotificationStyle
        weak var modalView:UIView?
        
        public init(controller: UIViewController, view: UIView, mode: ToastNotificationStyle = .TopModalCanCancel(true)) {
            self.mode = mode
            
            let screenSize = UIApplication.sharedApplication().keyWindow?.frame.size ?? UIScreen.mainScreen().bounds.size
            
            let insets = view.layoutMargins
            let height = view.bounds.height + insets.top + insets.bottom
            let y = screenSize.height - height
            
            view.frame.size.width = screenSize.width - insets.left - insets.right
            view.frame.origin = CGPoint(x: insets.left, y: mode.isTop ? insets.top : y - insets.bottom)
            super.init(controller: controller, view: view)
            
            switch mode {
            case .TopNormal(let duration) : self.duration = duration
            case .BottomNormal(let duration) : self.duration = duration
            default: break
            }
        }
        
        public override func show() {
            Toast.notificationTask = self
            Toast.animateTasks()
        }
        
        public override func hide() {
            hideLater()
            Toast.animateTasks()
        }
        
        public override func hideLater() {
            modalView?.removeFromSuperview()
            Toast.notificationTask = nil
        }
        
        @objc public func hide(gesture:UIGestureRecognizer!) {
            hide()
        }
        
    }
*/
    
    public class WindowTask : Task {
        
        private var style:ToastWindowStyle = ToastWindowStyle.None
        public init(controller: UIViewController, view: UIView, style:ToastWindowStyle = ToastWindowStyle.None) {
            self.style = style
            
            super.init(controller: controller, view: view)
        }
        
        public override func show() {
            if style.isModal {
                // 如果没有模态 Toast.WindowTask 则立即显示本 消息
                if let task = Toast.windowTask where !task.style.isModal {
                    Toast.windowTask = self
                    // 并将没显示完的信息插入队列顶部
                    if let index = Toast.cleanQueue.indexOf(task) {
                        Toast.cleanQueue.removeAtIndex(index)
                    }
                    Toast.windowQueue.insert(task, atIndex: 0)
                    // 还原原位置
                    task.view.frame.origin = Toast.overlayWindow.frame.origin
                    print("模态窗口通知立即显示")
                } else if Toast.windowTask !== nil {
                    // 否则如果有 模态消息通知则加入队列
                    Toast.windowQueue.insert(self, atIndex: Toast.indexOfFirstNoneStyleWindowTask())
                    print("模态窗口通知加入队列")
                } else {
                    // 如果没有其他消息则立即显示
                    Toast.windowTask = self
                    print("模态窗口通知马上显示")
                }
            } else {
                // 非模态信息一律加入队列
                Toast.windowQueue.append(self)
            }
            Toast.animateTasks()
        }
        
        public override func hide() {
            hideLater()
            Toast.animateTasks()
        }
        
        public override func hideLater() {
            if let index = Toast.windowQueue.indexOf(self) {
                Toast.windowQueue.removeAtIndex(index)
            }
            if let task = Toast.windowTask {
                if self === task { Toast.windowTask = nil }
            }
        }
        
        @objc public func hide(gesture:UIGestureRecognizer!) {
            if !self.view.bounds.contains(gesture.locationInView(self.view)) { hide() }
        }
    }
    
    public class ActivityTask : Task {
        
        public var activityView:UIActivityIndicatorView
        public var label:UILabel
        
        public init(controller:UIViewController, message:String) {
            let view = UIView()
            
            let insets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
            
            label = UILabel()
            label.font = UIFont.systemFontOfSize(Toast.fontSize)
            label.numberOfLines = 1
            label.text = message
            label.textColor = UIColor.whiteColor()
            label.layoutMargins = insets
            label.sizeToFit()
            label.lineBreakMode = NSLineBreakMode.ByTruncatingTail
            
            activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
            activityView.sizeToFit()
            activityView.startAnimating()
            
            let labelWidth = label.frame.width + insets.left + insets.right
            let labelHeight = label.frame.height + insets.top + insets.bottom
            let activityWidth = activityView.frame.width + insets.left + insets.right
            let activityHeight = activityView.frame.height + insets.top + insets.bottom
            //print("activityView.frame.height:\(activityView.frame.width)")
            view.backgroundColor = UIColor(white: 0.2, alpha: 0.6)

            view.layer.cornerRadius = 8
            
            view.layer.shadowColor = UIColor.blackColor().CGColor
            view.layer.shadowOpacity = 0.8
            view.layer.shadowOffset = CGSize(width: 0, height: 2)
            
            view.frame.size = CGSize(width: max(labelWidth, activityWidth), height: labelHeight + activityHeight + Toast.interval * 4)
            
            activityView.frame.origin = CGPoint(x: (view.frame.width - activityView.frame.width) / 2, y: Toast.interval * 2 + insets.top)
            label.frame.origin = CGPoint(x: (view.frame.width - label.frame.width) / 2, y: view.bounds.maxY - Toast.interval - label.frame.height - insets.bottom)
            
            view.addSubview(activityView)
            view.addSubview(label)
            
            super.init(controller: controller, view: view)
        }
        
        override public func show() {
            Toast.activityTask = self
            Toast.animateTasks()
        }
        
        override public func hide() {
            hideLater()
            Toast.animateTasks()
        }
        
        override public func hideLater() {
            Toast.activityTask = nil
        }
    }
    
    public class Task : Equatable {
        
        public let view:UIView
        public weak var viewController:UIViewController?
        public weak var childController:UIViewController?
        
        public var duration:NSTimeInterval = 0
        private var dismissTime:NSTimeInterval = 0
        private var defaultSize:CGSize
        private var cornerRadius:CGFloat = 8
        private var frame:CGRect = CGRect.zeroRect
        private var alpha:CGFloat = 1

        public init(controller:UIViewController, view:UIView) {
            self.viewController = controller
            self.view = view
            self.defaultSize = view.bounds.size
            self.cornerRadius = view.layer.cornerRadius
        }
        
        public func show() {
            dismissTime = CACurrentMediaTime() + duration + (Toast.tasksQueue.count > 2 ? Toast.minDismissTime : 0) // 计算消失时间
            if let _ = Toast.tasksQueue.indexOf(self) {
                return
            }
            Toast.tasksQueue.append(self)
            Toast.animateTasks(false)
        }
        
        public func hide() {
            hideLater()
            Toast.animateTasks(false)
        }
        
        public func hideLater() {
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
        
        //print("已还原 self=\(self) count:\(Toast.taskFilterWithController(self).count)")
        // 视图离开时换回来 并删除 此视图控制器的 Toast.Task
        for task in Toast.taskFilterWithController(self) {
            task.hideLater()
        }
        Toast.animateTasks()

    }
}
