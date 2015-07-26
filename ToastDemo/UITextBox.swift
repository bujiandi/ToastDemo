//
//  UITextBox.swift
//  UITest
//
//  Created by 李招利 on 14/7/10.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import UIKit

enum UITextBoxContentType {
    case AnyChar
    case Number
    case Integer
    case EMail
    case Phone
    case Telephone
    case MobilePhone
    case CustomType
}


enum UITextBoxHighlightState:UInt32 {
    case Default    = 0xEEF7FF  // 淡蓝色
    case Validator  = 0xEEFFEE  // 淡绿色
    case Warning    = 0xFFFFCC  // 淡黄色
    case Wrong      = 0xFFEEEE  // 淡红色
}

@IBDesignable

class UITextBox: UITextField {
    
    @IBInspectable var wrongColor:UIColor = UIColor(number: UITextBoxHighlightState.Wrong.rawValue)
    @IBInspectable var warningColor:UIColor = UIColor(number: UITextBoxHighlightState.Warning.rawValue)
    @IBInspectable var validatorColor:UIColor = UIColor(number: UITextBoxHighlightState.Validator.rawValue)
    @IBInspectable var highlightColor:UIColor = UIColor(number: UITextBoxHighlightState.Default.rawValue)
    
    @IBInspectable var animateDuration:CGFloat = 0.4
    weak var placeholderLabel:UILabel!
    
    override var attributedPlaceholder: NSAttributedString? {
    didSet {
        if let label = placeholderLabel {
            label.attributedText = super.attributedPlaceholder
            self.layoutSubviews()
        }
    }
    }
    override var placeholder:String! {
    didSet {
        if let label = placeholderLabel {
            label.text = super.placeholder
            self.layoutSubviews()
        }
    }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: Selector("editingChanged"), forControlEvents: UIControlEvents.EditingChanged);
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addTarget(self, action: Selector("editingChanged"), forControlEvents: UIControlEvents.EditingChanged);
    }
    
    func editingChanged() {
        print("editingChanged:\(text)")
    }
    
    //获得焦点时高亮动画
    override func becomeFirstResponder() -> Bool {
        UIView.animateWithDuration(Double(animateDuration)){
            self.backgroundColor = self.highlightColor
        }
        return super.becomeFirstResponder()
    }
    
    //失去焦点时取消高亮动画
    override func resignFirstResponder() -> Bool {
        UIView.animateWithDuration(Double(animateDuration)){
            self.backgroundColor = UIColor.clearColor()
        }
        return super.resignFirstResponder()
    }
    
    
    //调整子控件布局
    override func layoutSubviews() {
        super.layoutSubviews()
        let rect = super.placeholderRectForBounds(bounds)
        if isFirstResponder() {
            layoutPlaceholderLabel(rect,false)
        } else if text == nil || text == "" {
            layoutPlaceholderLabel(rect,true)
        } else {
            layoutPlaceholderLabel(rect,false)
        }
    }
    
    override func willMoveToSuperview(newSuperview: UIView!)  {
        super.willMoveToSuperview(newSuperview)
        if placeholderLabel == nil {
            let rect = super.placeholderRectForBounds(bounds)
            let label = UILabel(frame: rect)
            label.text = self.placeholder
            label.textColor = UIColor(white: 0.7, alpha: 1.0)
            label.font = self.font
            placeholderLabel = label
            self.addSubview(label);
        }
    }
    
    override func removeFromSuperview() {
        self.placeholderLabel.removeFromSuperview()
        self.placeholderLabel = nil
        super.removeFromSuperview()
    }
    

    override func placeholderRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.placeholderRectForBounds(bounds)
        if placeholderLabel == nil {
            let label = UILabel(frame: rect)
            label.textColor = UIColor(white: 0.7, alpha: 1.0)
            label.font = self.font
            placeholderLabel = label
            addSubview(label)
        }
        placeholderLabel.text = self.placeholder
        layoutPlaceholderLabel(rect,!isFirstResponder())
        return CGRect.zeroRect
    }
    
    
    //布局提示文本
    func layoutPlaceholderLabel(rect: CGRect,_ left: Bool = false) {
        if let label = placeholderLabel {
            let size = label.sizeThatFits(bounds.size)
            if left {
                UIView.animateWithDuration(Double(animateDuration)){
                    self.placeholderLabel.frame = rect;
                }
            } else {
                UIView.animateWithDuration(Double(animateDuration)){
                    let size = self.placeholderLabel.sizeThatFits(self.bounds.size)
                    var frame = self.placeholderLabel.frame
                    frame.origin.x = self.bounds.width - size.width - 7.0
                    frame.size.width = size.width + 7.0
                    self.placeholderLabel.frame = frame
                }
            }
        }
    }
    
    
    private func getHighlightColor(state:UITextBoxHighlightState) -> UIColor {
        switch state {
        case .Wrong:        return wrongColor
        case .Warning:      return warningColor
        case .Validator:    return validatorColor
        default:            return highlightColor
        }
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */

}


extension UIColor {
    convenience init(number:UInt32) {
        let b = CGFloat(number & 0xFF) / 255
        let g = CGFloat((number >> 8) & 0xFF) / 255
        let r = CGFloat((number >> 16) & 0xFF) / 255
        let a = number > 0xFFFFFF ? CGFloat((number >> 24) & 0xFF) / 255 : 1.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    convenience init?(hex:String) {
        let regular:NSRegularExpression
        do {
            regular = try NSRegularExpression(pattern: "(#?|0x)[0-9a-fA-F]{2,}", options: NSRegularExpressionOptions.CaseInsensitive)
        } catch { return nil }
        
        let length = distance(hex.startIndex, hex.endIndex)
        guard let result = regular.firstMatchInString(hex, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, length)) else {
            print("error: hex isn't color hex value!")
            return nil
        }
        
        let start = advance(hex.startIndex, result.rangeAtIndex(1).length + result.rangeAtIndex(1).location)
        let end = advance(hex.startIndex, result.range.length + result.range.location)
        let number = strtoul(hex[start..<end], nil, 16)
        let b = CGFloat((number >>  0) & 0xFF) / 255
        let g = CGFloat((number >>  8) & 0xFF) / 255
        let r = CGFloat((number >> 16) & 0xFF) / 255
        let a = distance(start, end) > 6 ? CGFloat((number >> 24) & 0xFF) / 255 : 1
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
