//
//  UITextBox.swift
//  UITest
//
//  Created by 李招利 on 14/7/10.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import UIKit

//enum UITextBoxContentType {
//    case AnyChar
//    case Number
//    case Integer
//    case EMail
//    case Phone
//    case Telephone
//    case MobilePhone
//    case CustomType
//}


enum UITextBoxHighlightState {
    case `default`
    case validator  (String)    // 状态提示文字
    case warning    (String)    // 状态提示文字
    case wrong      (String)    // 状态提示文字
}

@IBDesignable

class UITextBox: UITextField {
    
    @IBInspectable var wrongColor:UIColor       = UIColor(number: 0xFFEEEE) // 淡红色
    @IBInspectable var warningColor:UIColor     = UIColor(number: 0xFFFFCC) // 淡黄色
    @IBInspectable var validatorColor:UIColor   = UIColor(number: 0xEEFFEE) // 淡绿色
    @IBInspectable var highlightColor:UIColor   = UIColor(number: 0xEEF7FF) // 淡蓝色
    
    @IBInspectable var animateDuration:CGFloat = 0.4
    fileprivate weak var _placeholderLabel:UILabel?
    var placeholderLabel:UILabel {
        if _placeholderLabel == nil {
            let label = UILabel(frame: super.placeholderRect(forBounds: bounds))
            label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
            setHighlightText(label, state: self._highlightState)
            _placeholderLabel = label
            addSubview(label)
        }
        return _placeholderLabel!
    }
    
    @NSCopying fileprivate var _backgroundColor: UIColor? = nil
    override var backgroundColor: UIColor? {
        set {
            _backgroundColor = newValue
            super.backgroundColor = self.getHighlightColor(self.highlightState)
        }
        get {
            return _backgroundColor
        }
    }
    override var attributedPlaceholder: NSAttributedString? {
    didSet {
        if let label = _placeholderLabel {
            label.attributedText = super.attributedPlaceholder
            layoutSubviews()
        }
    }
    }
    override var placeholder:String? {
    didSet {
        if let label = _placeholderLabel {
            label.text = super.placeholder
            layoutSubviews()
        }
    }
    }
    
    
    fileprivate var _highlightState:UITextBoxHighlightState {
        return text == nil || text == "" ? .default : highlightState
    }
    var highlightState:UITextBoxHighlightState = .default {
    didSet {
        animationFirstResponder(isFirstResponder)
    }
    }
    
    //获得焦点时高亮动画
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        animationFirstResponder(true)
        return result
    }
    
    //失去焦点时取消高亮动画
    override func resignFirstResponder() -> Bool {
        animationFirstResponder(false)
        return super.resignFirstResponder()
    }
    
    //
    fileprivate func animationFirstResponder(_ isFirstResponder:Bool) {
        UIView.animate(withDuration: TimeInterval(animateDuration), delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveLinear, animations: {
            let color = self.getHighlightColor(self._highlightState)
            super.backgroundColor = isFirstResponder ? color : self._backgroundColor ?? UIColor.white
            if let label = self._placeholderLabel {
                self.setHighlightText(label, state: self._highlightState)
                label.frame = self.placeholderRectAtRight(isFirstResponder || !(self.text ?? "").isEmpty)
            }
        }, completion: nil)
    }
    
    //调整子控件布局
    override func layoutSubviews() {
        super.layoutSubviews()
        _placeholderLabel?.frame = placeholderRectAtRight(isFirstResponder || !(text ?? "").isEmpty)
    }
    
    override func willMove(toSuperview newSuperview: UIView!)  {
        super.willMove(toSuperview: newSuperview)
        placeholderLabel.frame = placeholderRectAtRight(isFirstResponder || !(text ?? "").isEmpty)
    }
    
    override func removeFromSuperview() {
        self._placeholderLabel?.removeFromSuperview()
        self._placeholderLabel = nil
        super.removeFromSuperview()
    }
    

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect.zero
    }
    
    //布局提示文本
    func placeholderRectAtRight(_ right: Bool = false) -> CGRect {
        let rect = super.placeholderRect(forBounds: bounds)
        let size = placeholderLabel.sizeThatFits(rect.size)
        let frame = right ? CGRect(x: super.clearButtonRect(forBounds: bounds).minX - size.width, y: rect.minY, width: size.width, height: rect.height) : rect
        return frame
    }
    
    fileprivate func setHighlightText(_ label:UILabel, state:UITextBoxHighlightState) {
        switch state {
        case .wrong(let errorText):
            label.textColor = getTextColorWithHighlightColor(wrongColor)
            label.text = errorText
        case .warning(let warningText):
            label.textColor = getTextColorWithHighlightColor(warningColor)
            label.text = warningText
        case .validator(let validatorText):
            label.textColor = getTextColorWithHighlightColor(validatorColor)
            label.text = validatorText
        default:
            if let attributedPlaceholder = self.attributedPlaceholder {
                label.attributedText = attributedPlaceholder
            } else {
                label.text = self.placeholder
            }
            label.textColor = getTextColorWithHighlightColor(getHighlightColor(_highlightState))
        }
    }
    
    fileprivate func getBackgroundColorWithTextColor(_ color:UIColor) -> UIColor {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        r = 1 - r
        g = 1 - g
        b = 1 - b
        return UIColor(red: r*r*0.7, green: g*g*0.7, blue: b*b*0.7, alpha: a)   // 同类颜色减淡一些
    }
    fileprivate func getTextColorWithHighlightColor(_ color:UIColor) -> UIColor {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r*r*0.7, green: g*g*0.7, blue: b*b*0.7, alpha: a)   // 同类颜色加深一些
    }
    fileprivate func getHighlightColor(_ state:UITextBoxHighlightState) -> UIColor {
        switch state {
        case .wrong:        return wrongColor
        case .warning:      return warningColor
        case .validator:    return validatorColor
        default:            return self.isFirstResponder ? highlightColor : self.backgroundColor ?? UIColor.white
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
            regular = try NSRegularExpression(pattern: "(#?|0x)[0-9a-fA-F]{2,}", options: NSRegularExpression.Options.caseInsensitive)
        } catch { return nil }
        
        let length = hex.characters.distance(from: hex.startIndex, to: hex.endIndex) //distance(hex.startIndex, hex.endIndex)
        
        guard let result = regular.firstMatch(in: hex, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, length)) else {
             return nil
        }
        
        let start = hex.characters.index(hex.startIndex, offsetBy: result.rangeAt(1).length + result.rangeAt(1).location) //advance(hex.startIndex, result.rangeAtIndex(1).length + result.rangeAtIndex(1).location)
        let end = hex.characters.index(hex.startIndex, offsetBy: result.range.length + result.range.location) //advance(hex.startIndex, result.range.length + result.range.location)
        let number = strtoul(hex[start..<end], nil, 16)
        let b = CGFloat((number >>  0) & 0xFF) / 255
        let g = CGFloat((number >>  8) & 0xFF) / 255
        let r = CGFloat((number >> 16) & 0xFF) / 255
        let a = hex.distance(from: start, to: end) > 6 ? CGFloat((number >> 24) & 0xFF) / 255 : 1 //distance(start, end) > 6 ? CGFloat((number >> 24) & 0xFF) / 255 : 1
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
