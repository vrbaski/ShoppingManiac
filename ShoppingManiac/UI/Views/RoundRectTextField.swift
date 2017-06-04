//
//  RoundRectTextField.swift
//  ShoppingManiac
//
//  Created by Dmitry Matyushkin on 21/05/2017.
//  Copyright © 2017 Dmitry Matyushkin. All rights reserved.
//

import UIKit

@IBDesignable
class RoundRectTextField: UITextField {
    
    private let floatingLabelActiveColor = UIColor.blue
    private let floatingLabelInactiveColor = UIColor.gray
    
    private let floatingLabel = UILabel()
    
    private func setup() {
        self.borderStyle = UITextBorderStyle.roundedRect
        self.floatingLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
        self.floatingLabel.textColor = self.floatingLabelInactiveColor
        self.floatingLabel.text = self.placeholder
        self.floatingLabel.sizeToFit()
        self.clearButtonMode = UITextFieldViewMode.whileEditing
        self.addSubview(self.floatingLabel)
        self.floatingLabel.frame = CGRect(x: 5, y: 0, width: self.floatingLabel.bounds.width, height: self.floatingLabel.bounds.height)
        self.floatingLabel.alpha = 0.0
        self.addTarget(self, action: #selector(RoundRectTextField.editingDone), for: UIControlEvents.editingDidEndOnExit)
        self.addTarget(self, action: #selector(RoundRectTextField.editingStarted), for: UIControlEvents.editingDidBegin)
        self.addTarget(self, action: #selector(RoundRectTextField.editingChanged), for: UIControlEvents.editingChanged)
        self.addTarget(self, action: #selector(RoundRectTextField.editingEnded), for: UIControlEvents.editingDidEnd)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    override var text: String? {
        didSet {
            self.hideFloatingLabel(text?.isEmpty ?? true)
        }
    }
    
    override var placeholder: String? {
        didSet {
            self.floatingLabel.text = placeholder
            self.floatingLabel.sizeToFit()
        }
    }
    
    private func setTextIfEmpty(_ text: String?) {
        if self.text?.isEmpty ?? true {
            self.text = text
        }
    }
    
    private func hideFloatingLabel(_ hide : Bool) {
        let isLabelHidden = (self.floatingLabel.alpha == 0.0)
        if hide != isLabelHidden {
            UIView.animate(withDuration: 0.45, delay: 0.0, options: .curveEaseOut, animations: {
                self.floatingLabel.alpha = hide ? 0.0 : 1.0
            }, completion: nil)
        }
    }
    
    private func changeFloatingLabelColor(_ color : UIColor) {
        self.floatingLabel.textColor = color
    }
    
    func editingDone() {
        self.resignFirstResponder()
    }
    
    func editingStarted() {
        changeFloatingLabelColor(self.floatingLabelActiveColor)
    }
    
    func editingChanged() {
        self.hideFloatingLabel(text?.isEmpty ?? true)
    }
    
    func editingEnded() {
        changeFloatingLabelColor(self.floatingLabelInactiveColor)
    }
    
    override var intrinsicContentSize : CGSize {
        let size = sizeThatFits(frame.size)
        return CGSize(width: size.width, height: size.height + floatingLabel.font.lineHeight)
    }
    
    override func textRect (forBounds bounds :CGRect) -> CGRect {
        return rectWithTitle(super.textRect(forBounds: bounds))
    }
    
    override func editingRect (forBounds bounds : CGRect) -> CGRect {
        return rectWithTitle(super.editingRect(forBounds: bounds))
    }
    
    private func rectWithTitle(_ rect : CGRect) -> CGRect {
        floatingLabel.sizeToFit()
        return UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(floatingLabel.font.lineHeight, 0, 0, 0))
    }
}