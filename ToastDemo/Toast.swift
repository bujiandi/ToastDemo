//
//  Toast.swift
//  DemoNavigationMore
//
//  Created by 慧趣小歪 on 15/7/20.
//  Copyright © 2015年 慧趣小歪. All rights reserved.
//

import UIKit

public func ==(lhs: Toast.Task, rhs: Toast.Task) -> Bool {
    return lhs.view === rhs.view
}

extension UISwipeGestureRecognizerDirection {
    static var Tap: UISwipeGestureRecognizerDirection { return UISwipeGestureRecognizerDirection(rawValue: 0) }
}

public enum ToastWindowStyle {
    case None (timeout: NSTimeInterval)
    case Modal
    case ModalCanCancel (cancelDirection: UISwipeGestureRecognizerDirection)
    
    var isModal:Bool {
        switch self {
        case .None( _): return false
        default: return true
        }
    }
}

public struct Toast {

    static public var fontSize:CGFloat = 13
    static public var interval:CGFloat = 5     // 默认 Toast.Task 间隔
    
    static public weak var activityTask:ActivityTask? = nil
    static public var tasksQueue:[Task] = []   // 显示 Toast.Task 队列
    static public var cleanQueue:[Task] = []   // 移除 Toast.Task 队列
    static public var windowQueue:[WindowTask] = [] // 窗口式 Toast.WindowTask 等待显示队列
    static public var windowModalQueue:[WindowTask] = [] // 模态窗口式 Toast.WindowTask 等待显示队列
    
    static public var windowModalTask:WindowTask? = nil {
        willSet {
            if let task = windowModalTask {
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
    static public var visibleTasks:ContiguousArray<Task> {
        // 构造一个高性能的连续数组
        var tasks = ContiguousArray<Task>()
        // 为其分配最佳内存大小 (已显示的Task + windowTask)
        tasks.reserveCapacity(tasksQueue.count + 1)
        if let task = windowTask { tasks.append(task) }
        tasks.appendContentsOf(tasksQueue)
        return tasks
    }
    
    static private var _overlayWindow:UIWindow?//OverlayWindow? = nil
    static private var overlayWindow:UIWindow { //OverlayWindow {
        
        if _overlayWindow == nil {
            let window = UIWindow(frame: UIScreen.mainScreen().bounds) //OverlayWindow(frame: UIScreen.mainScreen().bounds)
            window.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            window.userInteractionEnabled = true    // 支持手势
            window.backgroundColor = UIColor.clearColor()
            window.windowLevel = UIWindowLevelStatusBar
            window.transform = UIApplication.sharedApplication().keyWindow?.transform ?? CGAffineTransformIdentity
            window.rootViewController = OverlayRootController() //UIViewController()
            _overlayWindow = window
        }
        return _overlayWindow!
    }
    /// - 构造Toast
    /// 构造一个顶部通知
    static public func makeNotificationOnTop(parentController:UIViewController, view:UIView, style:ToastWindowStyle = .None(timeout: 8)) -> WindowTask {
        let task = makeWindow(parentController, view: view, style: style)
        task.cornerRadius = 0
        task.view.layer.cornerRadius = 0
        task.view.frame = CGRectMake(0, -20, UIScreen.mainScreen().bounds.width, task.view.frame.height + 20)
        task.defaultSize = task.view.frame.size
        view.frame.origin.y += 20
        view.autoresizingMask = [.FlexibleWidth]
        task.autoresizingMask = [.FlexibleWidth, .FlexibleBottomMargin]
        return task
    }
    /// 构造一个中部通知
    static public func makeNotificationOnCenter(parentController:UIViewController, view:UIView, style:ToastWindowStyle = .None(timeout: 8)) -> WindowTask {
        let task = makeWindow(parentController, view: view, style: style)
        let size = UIScreen.mainScreen().bounds.size
        task.view.center = CGPointMake(size.width / 2, size.height / 2)
        task.defaultSize = task.view.frame.size
        view.autoresizingMask = [.FlexibleWidth]
        task.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin, .FlexibleBottomMargin]
        return task
    }
    /// 构造一个底部通知
    static public func makeNotificationOnBottom(parentController:UIViewController, view:UIView, style:ToastWindowStyle = .None(timeout: 8)) -> WindowTask {
        let task = makeWindow(parentController, view: view, style: style)
        task.cornerRadius = 0
        task.view.layer.cornerRadius = 0
        let height = task.view.frame.height
        let screenHeight = UIScreen.mainScreen().bounds.height
        task.view.frame = CGRectMake(0, screenHeight - height, UIScreen.mainScreen().bounds.width, height + 20)
        task.defaultSize = task.view.frame.size
        view.autoresizingMask = [.FlexibleWidth]
        task.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
        return task
    }
    static private func updateNotificationLabel(label:UILabel) {
        let insets = label.layoutMargins
        label.frame.size.width = UIScreen.mainScreen().bounds.width - insets.left - insets.right
        label.textAlignment = NSTextAlignment.Center
        label.backgroundColor = UIColor.darkGrayColor()
    }
    /// 构造一个纯文字顶部通知
    static public func makeNotificationOnTop(parentController:UIViewController, message:String, style:ToastWindowStyle = .None(timeout: 8)) -> WindowTask {
        let label = makeLabel(message, numberOfLines:3)
        updateNotificationLabel(label)
        return makeNotificationOnTop(parentController, view: label, style: style)
    }
    /// 构造一个富文本顶部通知
    static public func makeNotificationOnTop(parentController:UIViewController, message:NSAttributedString, style:ToastWindowStyle = .None(timeout: 8)) -> WindowTask {
        let label = makeLabel(message, numberOfLines:3)
        updateNotificationLabel(label)
        return makeNotificationOnTop(parentController, view: label, style: style)
    }
    static public func makeNotificationOnBottom(parentController:UIViewController, message:String, style:ToastWindowStyle = .None(timeout: 8)) -> WindowTask {
        let label = makeLabel(message, numberOfLines:3)
        updateNotificationLabel(label)
        return makeNotificationOnBottom(parentController, view: label, style: style)
    }
    static public func makeNotificationOnBottom(parentController:UIViewController, message:NSAttributedString, style:ToastWindowStyle = .None(timeout: 8)) -> WindowTask {
        let label = makeLabel(message, numberOfLines:3)
        updateNotificationLabel(label)
        return makeNotificationOnBottom(parentController, view: label, style: style)
    }
    
    /// create a controller Toast.Task
    static public func makeWindow(parentController:UIViewController, toastController:UIViewController, style:ToastWindowStyle = .Modal) -> WindowTask {
        let task = makeWindow(parentController, view: toastController.view, style: style)
        task.childController = toastController
        return task
    }
    static private func makeBackgroundByView(view:UIView) -> UIView {
        let insets = view.layoutMargins
        let backgroundView = UIView(frame: CGRect(x: view.frame.minX - insets.left, y: view.frame.minY - insets.top, width: view.frame.width + insets.left + insets.right, height: view.frame.height + insets.top + insets.bottom))
        
        view.frame.origin = CGPoint(x: insets.left, y: insets.top)
        
        backgroundView.addSubview(view)
        backgroundView.backgroundColor = view.backgroundColor
        backgroundView.layer.shadowColor = UIColor(white: 0.2, alpha: 1).CGColor
        backgroundView.layer.shadowOpacity = 0.8
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundView.layer.cornerRadius = 7
        backgroundView.autoresizingMask = view.autoresizingMask
        view.backgroundColor = UIColor.clearColor()
        
        return backgroundView
    }
    /// create a view Toast.Task, has black background and shadow
    static public func makeWindow(parentController:UIViewController, view:UIView, style:ToastWindowStyle = .Modal) -> WindowTask {
        return WindowTask(controller: parentController, view: makeBackgroundByView(view), style:style)
    }
    
    /// 显示活动等待视图
    static public func makeActivity(parentController:UIViewController, message:String, style:ToastWindowStyle = .Modal) -> ActivityTask {
        return ActivityTask(controller: parentController, message: message, style: style)
    }
    
    /// 显示自定义控制器的视图
    static public func makeCustomView(parentController:UIViewController, toastController:UIViewController, duration: NSTimeInterval = 8) -> Task {
        let task = Task(controller: parentController, view:toastController.view)
        task.childController = toastController
        task.duration = duration
        return task
    }
    
    /// 显示带背景 View 的自定义控制器的视图
    static public func makeView(parentController:UIViewController, toastController:UIViewController, duration: NSTimeInterval = 8) -> Task {
        let task = makeView(parentController, childView: toastController.view, duration: duration)
        task.childController = toastController
        return task
    }
    
    /// 显示自定义视图
    static public func makeCustomView(parentController:UIViewController, view:UIView, duration: NSTimeInterval = 8) -> Task {
        let task = Task(controller: parentController, view:view)
        task.duration = duration
        return task
    }
    
    /// 显示带背景 View 的自定义视图
    static public func makeView(parentController:UIViewController, childView child:UIView, duration: NSTimeInterval = 8) -> Task {
        let font = UIFont.systemFontOfSize(Toast.fontSize)
        let maxHeight = font.lineHeight * 2
        let backgroundView = makeBackgroundByView(child)
        backgroundView.layer.cornerRadius = (backgroundView.frame.height > maxHeight ? font.lineHeight : backgroundView.frame.height) / 2
        return makeCustomView(parentController, view: backgroundView, duration: duration)
    }
    
    /// 显示文本通知视图
    static public func makeText(controller:UIViewController, message:String, duration: NSTimeInterval = 8) -> Task {
        return makeView(controller, childView: makeLabel(message, numberOfLines:3), duration: duration)
    }
    static public func makeText(controller:UIViewController, message:NSAttributedString, duration: NSTimeInterval = 8) -> Task {
        return makeView(controller, childView: makeLabel(message, numberOfLines:3), duration: duration)
    }
    
    // 根据文本内容创建 UILabel
    static private func makeLabel(message:String, numberOfLines:Int) -> UILabel {
        let screenSize = UIApplication.sharedApplication().keyWindow?.frame.size ?? UIScreen.mainScreen().bounds.size
        let insets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
        let screenWidth = screenSize.width - insets.left - insets.right
        
        let label:UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(Toast.fontSize)
        label.numberOfLines = numberOfLines
        label.text = message
        label.textColor = UIColor.whiteColor()
        label.layoutMargins = insets
        let size = label.sizeThatFits(CGSize(width: screenWidth, height: label.font.lineHeight * CGFloat(label.numberOfLines)))
        
        label.frame.size = size//CGSizeMake(screenWidth, size.height)
        label.backgroundColor = UIColor(white: 0.2, alpha: 0.6)

        return label
    }
    // 根据富文本内容创建UILabel
    static private func makeLabel(message:NSAttributedString, numberOfLines:Int) -> UILabel {
        let screenSize = UIApplication.sharedApplication().keyWindow?.frame.size ?? UIScreen.mainScreen().bounds.size
        let insets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
        let screenWidth = screenSize.width - insets.left - insets.right
        
        let label:UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(Toast.fontSize)
        label.numberOfLines = numberOfLines
        label.attributedText = message
        label.textColor = UIColor.whiteColor()
        label.layoutMargins = insets
        let size = label.textRectForBounds(CGRectMake(0, 0, screenWidth, UIScreen.mainScreen().bounds.height), limitedToNumberOfLines: numberOfLines).size
        
        label.frame.size = size//CGSizeMake(screenWidth, height)
        label.backgroundColor = UIColor(white: 0.2, alpha: 0.6)

        
        return label
    }
    static private func indexOfFirstNoneStyleWindowTask() -> Int {
        for i:Int in 0 ..< windowQueue.count {
            if !windowQueue[i].style.isModal { return i }
        }
        return windowQueue.count
    }
    static private func taskFilterWithController(controller:UIViewController) -> [Task] {
        var tasks:[Task] = []
        
        // 已显示的窗口 Toast.WindowTask
        if let task = windowTask {
            if let viewController = task.viewController {
                if controller === viewController { tasks.append(task) }
            }
        }
        
        // 将要显示的窗口 Toast.WindowTask
        for task in windowQueue {
            if let viewController = task.viewController {
                if controller === viewController { tasks.append(task) }
            }
        }
        
        // 将要显示的 Toast.Task
        for task:Task in tasksQueue {
            if let viewController = task.viewController {
                if controller === viewController { tasks.append(task) }
            }
        }
        
        return tasks
    }
    
    static private func registerViewControllerClass<T : UIViewController>(cls:T.Type) {
        if cls !== UIViewController.self {
            let viewDidDisappearSelector = #selector(UIViewController.viewDidDisappear(_:))
            
            let viewDidDisappearMethod = class_getInstanceMethod(cls, viewDidDisappearSelector)
            let taskDidDisappearMethod = class_getInstanceMethod(cls, #selector(UIViewController.taskDidDisappear(_:)))
            
            let taskDidDisappearIMP = method_getImplementation(taskDidDisappearMethod)
            
            var viewDidDisappearIMP:IMP = nil
            
            // 如果对象 没有 override func viewDidDisappear 则创建一个 并跳转到 taskDidDisappear
            if !class_addMethod(cls, viewDidDisappearSelector, taskDidDisappearIMP, method_getTypeEncoding(viewDidDisappearMethod)) {
                
                let taskDidDisappearAndRecallMethod = class_getInstanceMethod(cls, #selector(UIViewController.taskDidDisappearAndRecall(_:)))
                let taskDidDisappearAndRecallIMP = method_getImplementation(taskDidDisappearAndRecallMethod)

                // 如果 存在 override func viewDidDisappear 则将函数指针替换为 taskDidDisappear
                viewDidDisappearIMP = class_replaceMethod(cls, viewDidDisappearSelector, taskDidDisappearAndRecallIMP, method_getTypeEncoding(viewDidDisappearMethod))
                
                let selfDidDisappearSelector = #selector(UIViewController.__selfDidDisappear(_:))
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
        // 计算最小更新时间
        if let task = windowTask where !task.style.isModal {
            if minDismissTime > task.dismissTime { minDismissTime = task.dismissTime }
        }

        return minDismissTime - currentTime
    }
    static private var _afterBlock:(dispatch_block_t?, NSTimeInterval) = (nil, 0)
    static private func animateTasks(isAfter:Bool = false) {
        let currentTime = CACurrentMediaTime()

        let screenSize = UIApplication.sharedApplication().windows.first?.frame.size ?? UIScreen.mainScreen().bounds.size
        var animateTaskList:[Task] = []
        // 处理队列中要显示的
        
        var minDismissTime:NSTimeInterval = 0
        
        // 将超时的 Toast.Task 都加入移除队列
        for i in (0..<tasksQueue.count).reverse() {
        //for var i:Int = tasksQueue.count - 1; i>=0; i -= 1 {
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
        // 如果当前显示的 Toast.WindowTask 非模态 则判断其是否超时
        
        var currentWindowTask = windowModalTask ?? (windowModalQueue.count > 0 ? windowModalQueue.removeAtIndex(0) : nil)
        if let task = windowTask where currentWindowTask == nil {
            if currentTime > task.dismissTime {
                windowTask = windowQueue.count > 0 ? windowQueue.removeAtIndex(0) : nil
                windowTask?.dismissTime = currentTime + windowTask!.duration
            }
            currentWindowTask = windowTask
        }
        if currentWindowTask == nil && windowQueue.count > 0 {
            currentWindowTask = windowQueue.removeAtIndex(0)
            currentWindowTask!.dismissTime = currentTime + currentWindowTask!.duration
        }
        
        if let task = currentWindowTask {
            
            if task.style.isModal {
                windowModalTask = task
            } else {
                windowTask = task
                if minDismissTime > task.dismissTime || minDismissTime == 0 {
                    minDismissTime = task.dismissTime
                }
            }
            
            // 如果视图未显示则添加
            if task.view.superview == nil {
                
                task.view.alpha = 0
                //task.frame = task.view.frame
                task.updateFrame()
                
                let window = overlayWindow
                window.frame = UIScreen.mainScreen().bounds
                window.rootViewController!.view.gestureRecognizers = nil
                (window.rootViewController!.view as? OverlayToastView)?.originPercent = CGPoint(x: task.view.center.x / window.frame.width, y: task.view.center.y / window.frame.height)
                window.rootViewController!.view.alpha = 1
                window.rootViewController!.view.hidden = false
                
                if task.style.isModal {
                    windowTask?.duration = max(windowTask!.dismissTime - currentTime, 0)
                }
                window.rootViewController!.view.addSubview(task.view)
                
                task.view.autoresizingMask = task.autoresizingMask
                
                let y = task.view.center.y
                task.view.center.y = (screenSize.height / 2) > y ? y - 30 : y + 30
                
                if case .ModalCanCancel(let direction) = task.style {
                    // 如果是可自动终止的
                    let tap = UITapGestureRecognizer(target: task, action: #selector(WindowTask.hide(_:)))
                    let swipe = UISwipeGestureRecognizer(target: task, action: #selector(WindowTask.hide(_:)))
                    swipe.direction = direction
                    window.rootViewController?.view.addGestureRecognizer(tap)
                    window.rootViewController?.view.addGestureRecognizer(swipe)
                }
                if let controller = task.childController {
                    window.rootViewController?.addChildViewController(controller)
                }
                // 加入动画列表
                animateTaskList.append(task)
            }
            let color = task.style.isModal ? UIColor(white: 0.2, alpha: 0.6) : UIColor.clearColor()
            _overlayWindow!.rootViewController!.view.backgroundColor = color

            task.alpha = 1
            _overlayWindow!.hidden = false
        }
        
        // 下次动画时间 不小于一次动画的间隔
        let animateTime = max(minDismissTime - currentTime + 0.05, 0.351)
        
        let startY = screenSize.height * 0.75
        var offsetY:CGFloat = 0
        
        // 所有需显示的
        for i in (0..<tasksQueue.count).reverse() {
        //for var i:Int = tasksQueue.count - 1; i>=0; i -= 1 {
            let task = tasksQueue[i]
            
            var size = task.defaultSize
            var x:CGFloat = (screenSize.width - size.width) / 2
            var y:CGFloat = startY - offsetY - size.height
            offsetY += size.height + interval

            if i > 2 {
                // 计算等待的 Toast.Task 位置
                task.view.layer.cornerRadius = 8
                task.cornerRadius = 8
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
                task.cornerRadius = task.defaultCornerRadius
            }
            //print("task i:\(i) x:\(x) y:\(y) offsetY:\(offsetY)")

            // 如果尚未显示则动画出现
            if task.view.superview == nil {
                task.view.alpha = 0.2
                task.view.frame.origin = CGPointMake(x, y + 30)
                task.view.frame.size = size
                let keyWindow = UIApplication.sharedApplication().keyWindow ?? UIApplication.sharedApplication().windows.first
                keyWindow?.addSubview(task.view)
                if let controller = task.childController where controller !== task.viewController {
                    task.viewController?.addChildViewController(controller)
                }
            }
            
            task.frame.origin = CGPoint(x: x, y: y)
            task.frame.size = size
            task.alpha = 1

            // 加入动画列表
            animateTaskList.append(task)
        }
        
        // 将要移除的列表
        for task in cleanQueue {
            task.frame = task.view.frame
            if task is WindowTask {
                let y = task.view.center.y
                let oy = task.frame.origin.y
                task.frame.origin.y = (screenSize.height / 2) > y ? oy - 30 : oy + 30
            } else {
                task.frame.origin.y -= 30 //task.frame.minY - task.frame.height
            }

            task.alpha = 0
            
            // 加入动画列表
            animateTaskList.insert(task, atIndex: 0)
        }
        
        UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 10, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            // 对要移除的 Toast.Task 进行动画
            for task:Task in animateTaskList {
                if task is WindowTask {
                    let alpha:CGFloat = windowModalTask === nil && windowTask === nil ? 0 : 1
                    _overlayWindow?.rootViewController?.view.alpha = alpha
                }
                task.view.layer.cornerRadius = task.cornerRadius
                task.view.transform = task.transform
                task.view.alpha = task.alpha
                task.view.frame = task.frame
            }
        }) { (finish) -> Void in
            for task:Task in animateTaskList {
                task.view.autoresizingMask = task.autoresizingMask
                //print(task.autoresizingMask, "anim")
            }
            // 动画结束时 将移除列表清空
            var hasWindowTask:Bool = false
            for task in cleanQueue {
                hasWindowTask = hasWindowTask || task is WindowTask
                task.view.removeFromSuperview()
                task.childController?.removeFromParentViewController()
                task.onDismiss?()
                task.onDismiss = nil
            }
            // 如果队列中再无 Toast.WindowTask 则移除窗口
            if hasWindowTask && windowTask === nil && windowModalTask === nil {
                _overlayWindow?.hidden = true
                _overlayWindow?.rootViewController?.view.gestureRecognizers = nil
                _overlayWindow?.rootViewController?.removeFromParentViewController()
                _overlayWindow?.rootViewController = nil
                _overlayWindow?.removeFromSuperview()
                _overlayWindow = nil
                //print("动画结束干掉窗口 windowTask:\(windowTask)")
            }
            cleanQueue.removeAll()
        }
        
        
        // 如果没有延时回调 则计算最小延时回调时间
        let (afterBlock, lastDismissTime) = _afterBlock
        // 如果有更早的动画更新 即使有回调也创建一个新的动画回调
        if (afterBlock == nil || minDismissTime < lastDismissTime) && minDismissTime > 0 {

            _afterBlock = ({
                _afterBlock = (nil, minDismissTime)
                animateTasks(true)
            }, minDismissTime)
            
            let delay:NSTimeInterval = animateTime * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            
            dispatch_after(time, dispatch_get_main_queue(), _afterBlock.0!)
        }
//        print("下次动画时间:\(animateTime) _afterBlock:\(_afterBlock)")

//        CACurrentMediaTime()
//        mach_absolute_time()
//        CFAbsoluteTimeGetCurrent()
    }
    
    public class Task : Equatable {
        
        public let view:UIView
        public var childController:UIViewController?
        public weak var viewController:UIViewController?
        
        public var duration:NSTimeInterval = 0
        private var inset:UIEdgeInsets = UIEdgeInsetsZero
        private var autoresizingMask:UIViewAutoresizing = [.None]
        private var dismissTime:NSTimeInterval = 0
        private var defaultSize:CGSize
        private var defaultCornerRadius:CGFloat = 8
        private var cornerRadius:CGFloat = 8
        private var frame:CGRect = CGRect.zero
        private var alpha:CGFloat = 1
        private var transform:CGAffineTransform = CGAffineTransformIdentity
        private var onDismiss:(()->Void)?
        
        public init(controller:UIViewController, view:UIView) {
            self.viewController = controller
            self.view = view
            self.transform = view.transform
            self.defaultSize = view.bounds.size
            self.cornerRadius = view.layer.cornerRadius
            self.autoresizingMask = view.autoresizingMask
            self.defaultCornerRadius = cornerRadius
            let size = UIScreen.mainScreen().bounds.size
            let rect = view.frame
            self.inset = UIEdgeInsetsMake(rect.minY, rect.minX, size.height - rect.maxY, size.width - rect.maxX)
            //view.autoresizingMask = [.None]
        }
        
        public func setAutoresizingMask(autoresizingMask:UIViewAutoresizing) -> Self {
            self.autoresizingMask = autoresizingMask
            updateFrame()
            return self
        }
        
        deinit {
            view.removeFromSuperview()
            childController?.view.removeFromSuperview()
            childController?.removeFromParentViewController()
            childController = nil
            viewController = nil
        }
        
        private func updateFrame() {
            let size = UIScreen.mainScreen().bounds.size
            var rect = view.frame
            if autoresizingMask.contains(.FlexibleWidth) {
                rect.origin.x = inset.left == UITableViewAutomaticDimension ? 0 : inset.left
                rect.size.width = inset.right == UITableViewAutomaticDimension ? size.width - rect.minX : size.width - rect.minX - inset.right
            } else if autoresizingMask.contains([.FlexibleLeftMargin, .FlexibleRightMargin]) {
                rect.origin.x = (size.width - rect.width) / 2
            } else if autoresizingMask.contains(.FlexibleLeftMargin) {
                rect.origin.x = size.width - rect.width - inset.right
            } else if autoresizingMask.contains(.FlexibleRightMargin) {
                rect.origin.x = inset.left
            }
            if autoresizingMask.contains(.FlexibleHeight) {
                rect.origin.y = inset.top == UITableViewAutomaticDimension ? 0 : inset.top
                rect.size.height = inset.bottom == UITableViewAutomaticDimension ? size.height - rect.minY : size.height - rect.minY - inset.bottom
            } else if autoresizingMask.contains([.FlexibleTopMargin, .FlexibleBottomMargin]) {
                rect.origin.y = (size.height - rect.height) / 2
            } else if autoresizingMask.contains(.FlexibleTopMargin) {
                rect.origin.y = size.height - rect.height - inset.bottom
            } else if autoresizingMask.contains(.FlexibleBottomMargin) {
                rect.origin.y = inset.top
            }
            view.frame = rect
            frame = rect
        }
        
        private func updateInset() {
            let size = UIScreen.mainScreen().bounds.size
            inset.left = autoresizingMask.contains(.FlexibleLeftMargin) ? UITableViewAutomaticDimension : view.frame.minX
            inset.right = autoresizingMask.contains(.FlexibleRightMargin) ? UITableViewAutomaticDimension : size.width - view.frame.maxX
            inset.top = autoresizingMask.contains(.FlexibleTopMargin) ? UITableViewAutomaticDimension : view.frame.minY
            inset.bottom = autoresizingMask.contains(.FlexibleBottomMargin) ? UITableViewAutomaticDimension : size.height - view.frame.maxY
        }
        
        public func show(onDismiss:(()->Void)? = nil) {
            self.onDismiss = onDismiss
            self.updateInset()
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

    
    public class WindowTask : Task {
        
        //private var orientation:UIInterfaceOrientation
        private var style:ToastWindowStyle
        public init(controller: UIViewController, view: UIView, style:ToastWindowStyle = .None(timeout: 8)) {
            self.style = style
            //self.orientation = UIApplication.sharedApplication().statusBarOrientation
            super.init(controller: controller, view:view)
            if case .None(let duration) = style {
                super.duration = duration
            }
        }
        public override func show(onDismiss:(() -> Void)? = nil) {
            self.onDismiss = onDismiss
            super.updateInset()
            if self.style.isModal {
                Toast.windowModalQueue.append(self)
            } else {
                Toast.windowQueue.append(self)
            }
            Toast.animateTasks(false)
        }
        
        public override func hide() {
            hideLater()
            Toast.animateTasks(false)
        }
        
        public override func hideLater() {
            if let index = Toast.windowQueue.indexOf(self) {
                Toast.windowQueue.removeAtIndex(index)
            }
            if let index = Toast.windowModalQueue.indexOf(self) {
                Toast.windowModalQueue.removeAtIndex(index)
            }
            if let task = Toast.windowTask where self == task {
                Toast.windowTask = nil
            }
            if let task = Toast.windowModalTask where self == task {
                Toast.windowModalTask = nil
                Toast.windowTask?.dismissTime = CACurrentMediaTime() + windowTask!.duration
            }
        }
        
        @objc public func hide(gesture:UIGestureRecognizer!) {
            if !self.view.bounds.contains(gesture.locationInView(self.view)) { hide() }
        }
    }
    
    public class ActivityTask : WindowTask {
        
        public var activityView:UIActivityIndicatorView
        public var label:UILabel
        
        public init(controller:UIViewController, message:String, style:ToastWindowStyle = .Modal) {
            let view = UIView()
            
            let insets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
            
            label = Toast.makeLabel(message, numberOfLines: 1)
            label.backgroundColor = UIColor.clearColor()
            label.layoutMargins = insets

            activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
            activityView.sizeToFit()
            activityView.startAnimating()
            
            let labelWidth = label.frame.width + insets.left + insets.right
            let labelHeight = label.frame.height + insets.top + insets.bottom
            let activityWidth = activityView.frame.width + insets.left + insets.right
            let activityHeight = activityView.frame.height + insets.top + insets.bottom

            view.backgroundColor = UIColor(white: 0.2, alpha: 0.6)

            view.layer.cornerRadius = 8
            
            view.layer.shadowColor = UIColor.blackColor().CGColor
            view.layer.shadowOpacity = 0.8
            view.layer.shadowOffset = CGSize(width: 0, height: 2)
            
            view.frame.size = CGSize(width: max(labelWidth, activityWidth), height: labelHeight + activityHeight + Toast.interval * 4)
            let screenSize = UIScreen.mainScreen().bounds.size
            view.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)

            activityView.frame.origin = CGPoint(x: (view.frame.width - activityView.frame.width) / 2, y: Toast.interval * 2 + insets.top)
            label.frame.origin = CGPoint(x: (view.frame.width - label.frame.width) / 2, y: view.bounds.maxY - Toast.interval - label.frame.height - insets.bottom)
            
            view.addSubview(activityView)
            view.addSubview(label)
            
            super.init(controller: controller, view: view, style: style)
        }
        
        override public func show(onDismiss: (() -> Void)? = nil) {
            Toast.activityTask = self
            super.show(onDismiss)
        }
        
    }
}

class OverlayToastView : UIView {
    
    private var originPercent:CGPoint = CGPoint.zero

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let windowTask = Toast.windowTask else {
            return
        }
        if windowTask.autoresizingMask.rawValue != 0 {
            windowTask.defaultSize = windowTask.view.frame.size
            return
        }
        for view in subviews where view === windowTask.view {
            print(windowTask.autoresizingMask, "need")
            view.center = CGPoint(x: bounds.width * originPercent.x, y: bounds.height * originPercent.y)
        }
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, withEvent: event)
        // 如果模态 则忽略手势穿透
        if Toast.windowModalTask !== nil { return view }
        if view === self || view === nil {
            let window = UIApplication.sharedApplication().windows.first
            //print("操作穿透")
            return window?.hitTest(point, withEvent: event) ?? view
        }
        return view
    }
    
}

class OverlayRootController: UIViewController {
    
    override func loadView() {
        view = OverlayToastView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.clearColor()
    }
    
}

//extension UIInterfaceOrientation : CustomStringConvertible {
//    
//    public var description: String {
//        switch self {
//        case .LandscapeLeft: return "LandscapeLeft"
//        case .LandscapeRight: return "LandscapeRight"
//        case .PortraitUpsideDown: return "PortraitUpsideDown"
//        default : return "Portrait"
//        }
//    }
//}

extension UIViewController {
    
    public override class func initialize() {
        Toast.registerViewControllerClass(self)
    }
    
    func __selfDidDisappear(animated: Bool) {
        print("此方法用于回调原 ViewController 的 viewDidDisappear 函数指针被替换")
    }
    
    final func taskDidDisappearAndRecall(animated: Bool) {
        self.__selfDidDisappear(animated)  // 回调原 viewWillDisappear
        taskDidDisappear(animated)
    }
    
    final func taskDidDisappear(animated: Bool) {
        //self.__selfDidDisappear(animated)  // 回调原 viewWillDisappear
        
        //print("已还原 self=\(self) count:\(Toast.taskFilterWithController(self).count)")
        // 视图离开时换回来 并删除 此视图控制器的 Toast.Task
        for task in Toast.taskFilterWithController(self) {
            task.hideLater()
        }
        Toast.animateTasks()
        
    }
}
/*
public class OverlayRootControlller: UIViewController {
    
    override public func shouldAutorotate() -> Bool {
        return true
    }
}
*/

/*
extension UIWindow {
    
    // 选择后可以得到正常的 frame
    var transformFrame:CGRect {
        get {
            // 只有 iPhone 才需要旋转 window
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad { return frame }
            
            let screenSize = screen.bounds.size
            switch UIApplication.sharedApplication().statusBarOrientation {
            case .LandscapeLeft:
                return CGRect(x: -frame.minY, y: frame.minX, width: frame.height, height: frame.width)
            case .LandscapeRight:
                return CGRect(x: frame.minY, y: screenSize.height - frame.width - frame.minX, width: frame.height, height: frame.width)
            case .PortraitUpsideDown:
                return CGRect(x: frame.minX, y: screenSize.height - frame.height - frame.minY, width: frame.width, height: frame.height)
            default:
                return frame
            }
        }
        set (rect) {
            // 只有 iPhone 才需要旋转 window
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad { frame = rect; return }

            let screenSize = screen.bounds.size
            switch UIApplication.sharedApplication().statusBarOrientation {
            case .LandscapeLeft:
                frame = CGRect(x: rect.minY, y: -rect.minX, width: rect.height, height: rect.width)
            case .LandscapeRight:
                frame = CGRect(x: screenSize.height - rect.height - rect.minY, y: rect.minX, width: rect.height, height: rect.width)
            case .PortraitUpsideDown:
                frame = CGRect(x: rect.minX, y: screenSize.height - rect.height - rect.minY, width: rect.width, height: rect.height)
            default:
                frame = rect
            }
        }
    }
    
}
*/
//                if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
//                    // 只有 iPhone 才需要旋转 window
//                    func DegreesToRadians(degrees:CGFloat) -> CGFloat {
//                        return degrees * CGFloat(M_PI) / 180
//                    }
//
//                    switch UIApplication.sharedApplication().statusBarOrientation  {
//                    case .LandscapeLeft:
//                        window.transform = CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: 0) //CGAffineTransformRotate(CGAffineTransformIdentity, -DegreesToRadians(90))
//                    case .LandscapeRight:
//                        window.transform = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 0, ty: 0) //CGAffineTransformRotate(CGAffineTransformIdentity, DegreesToRadians(90))
//                    case .PortraitUpsideDown:
//                        task.view.transform = CGAffineTransformMakeRotation(DegreesToRadians(0))
//                    default:
//                        task.view.transform = UIApplication.sharedApplication().keyWindow?.transform ?? CGAffineTransformIdentity
//                    }
//                    //print("改变方向\(task.orientation) curr:\(UIApplication.sharedApplication().statusBarOrientation)")
//                }