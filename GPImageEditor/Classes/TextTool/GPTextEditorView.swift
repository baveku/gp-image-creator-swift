//
//  GPTextEditorView.swift
//  GPImageEditor_Example
//
//  Created by ToanDK on 9/17/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import DTMvvm

private let kAnimationTime = 0.3
private let kColorButtonWidth: CGFloat = 40

class ColorButton: UIView {
    let button = UIButton()
    let circle = UIImageView()
    var circleWidth: NSLayoutConstraint!
    
    var isSelected: Bool = false {
        didSet {
            circleWidth.constant = isSelected ? frame.width * 0.7 : frame.width * 0.5
        }
    }
    
    var bgColor: UIColor = .clear {
        didSet {
            circle.backgroundColor = bgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circle.layer.masksToBounds = true
        circle.layer.cornerRadius = circle.frame.width/2
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(button)
        button.autoPinEdgesToSuperviewEdges()
        
        addSubview(circle)
        circle.autoMatch(.width, to: .height, of: circle)
        circleWidth = circle.autoSetDimension(.width, toSize: kColorButtonWidth * 0.5)
        circle.autoCenterInSuperview()
        circle.layer.borderColor = UIColor.white.cgColor
        circle.layer.borderWidth = 1
        circle.layer.masksToBounds = true
        circle.layer.cornerRadius = circle.frame.size.width/2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Reactive where Base: ColorButton {
    var isSelected: Binder<Bool> {
        return Binder(base) { $0.isSelected = $1 }
    }
}

class GPTextEditorView: UIView {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var doneOverlayButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var alignButton: UIButton!
    @IBOutlet weak var fontButton: UIButton!
    @IBOutlet weak var changeColorButton: UIButton!
    @IBOutlet weak var menuBottomView: UIView!
    @IBOutlet weak var colorPickerView: UIView!
    @IBOutlet weak var colorScrollView: ScrollLayout!
    @IBOutlet weak var fontButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var menuBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    var showBgButton: UIButton!
    let hideButton = UIButton(type: .custom)
    let tutorialView = GPTutorialView.fontEditTutorial
    
    var colorButtons: [ColorButton] = []
    private var disposeBag: DisposeBag? = DisposeBag()
    
    static func buildTextView(_ textView: UITextView) {
        textView.layer.masksToBounds = true
        textView.layer.cornerRadius = 4
        textView.isScrollEnabled = false
        textView.contentInset = .zero
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.maximumNumberOfLines = 6
        textView.layoutManager.usesFontLeading = false
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        if #available(iOS 11.0, *) {
            textView.contentInsetAdjustmentBehavior = .never
        }
        textView.textContainerInset = .only(top: 0, bottom: 0, left: 10, right: 10)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        GPTextEditorView.buildTextView(textView)
        textView.delegate = self
        
        fontButton.layer.masksToBounds = true
        fontButton.layer.cornerRadius = fontButton.frame.height/2
        fontButton.layer.borderColor = UIColor.fromHex("#B2B2B2").cgColor
        fontButton.layer.borderWidth = 0.5
        
        let shouldShowTutorial = GPTutorialView.shouldShowTutorial(.GPFontEditTutorial)
        if (shouldShowTutorial) {
            addSubview(hideButton)
            bringSubviewToFront(hideButton)
            hideButton.autoPinEdgesToSuperviewEdges()
            hideButton.addSubview(tutorialView)
            tutorialView.autoAlignAxis(toSuperviewAxis: .vertical)
            tutorialView.autoPinEdge(.bottom, to: .top, of: menuBottomView, withOffset: -10)
            hideButton.addTarget(self, action: #selector(handleHide(_:)), for: .touchUpInside)
        }
        
        colorPickerView.isHidden = true
        addColorPicker()
        showKeyboard()
    }
    
    @objc func handleHide(_ sender: UIButton) {
        hideButton.isHidden = true
    }
    
    func showKeyboard() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    let keyboardRectangle = keyboardFrame.cgRectValue
                    let keyboardHeight = keyboardRectangle.height
                    let animationTime = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
                    self?.menuBottomConstraint.constant = keyboardHeight
                    UIView.animate(withDuration: animationTime, animations: {
                        self?.menuBottomView.superview?.layoutIfNeeded()
                    })                    
                    self?.disposeBag = nil
                }
            }) => disposeBag
        textView.becomeFirstResponder()
    }
    
    func addColorPicker() {
        showBgButton = UIButton(frame: .zero)
        showBgButton.autoSetDimensions(to: CGSize(width: kColorButtonWidth, height: colorPickerView.frame.height))
        showBgButton.setImage(GPImageEditorBundle.imageFromBundle(imageName: "ie_ic_text_border_active"), for: .selected)
        showBgButton.setImage(GPImageEditorBundle.imageFromBundle(imageName: "ie_ic_text_border"), for: .normal)
        colorScrollView.appendChild(showBgButton)
        
        for i in 0..<GPImageEditorConfigs.colorSet.count {
            let colorInfo = GPImageEditorConfigs.colorSet[i]
            let button = ColorButton(frame: .zero)
            button.autoSetDimensions(to: CGSize(width: kColorButtonWidth, height: colorPickerView.frame.height))
            button.tag = i
            button.bgColor = UIColor.fromHex(colorInfo.bgColor)
            colorButtons.append(button)
            colorScrollView.appendChild(button)            
        }
    }
}

extension GPTextEditorView: UITextViewDelegate, NSLayoutManagerDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let maxWidth = frame.width - 60
        let newSize = textView.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        textViewHeight.constant = newSize.height
        textViewWidthConstraint.constant = min(newSize.width, maxWidth)
        placeholderLabel.isHidden = textView.text.count > 0
    }
}

extension GPTextEditorView {
    
    // MARK: Actions
    
    @IBAction func cancelAction() {
        textView.resignFirstResponder()
        UIView.animate(withDuration: kAnimationTime, animations: {
            self.superview?.alpha = 0
        }) { _ in
            self.superview?.isHidden = true
        }
    }
    
    @IBAction func hideColorPickerAction() {
        menuBottomView.alpha = 0
        menuBottomView.isHidden = false
        UIView.animate(withDuration: kAnimationTime, animations: {
            self.colorPickerView.alpha = 0
            self.menuBottomView.alpha = 1
        }) { _ in
            self.colorPickerView.isHidden = true
        }
    }
    
    @IBAction func showColorPickerAction() {
        colorPickerView.alpha = 0
        colorPickerView.isHidden = false
        UIView.animate(withDuration: kAnimationTime, animations: {
            self.colorPickerView.alpha = 1
            self.menuBottomView.alpha = 0
        }) { _ in
            self.menuBottomView.isHidden = true
        }
    }
}
