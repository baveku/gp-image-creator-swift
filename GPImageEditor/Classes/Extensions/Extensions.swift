//
//  StringExtensions.swift
//  GPImageEditor
//
//  Created by ToanDK on 9/12/19.
//

import Foundation
import RxSwift
import RxCocoa

public extension UIImage {
    class func imageWithView(view: UIView, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        view.layer.render(in: context)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
    
    // return true if needed scale width to fit max size, height is ratio with width
    // return false if needed scale heigh to fit max size, width is ratio with height
    func shouldScaleWidth(toFitSize size: CGSize) -> Bool {
        return self.size.width / size.width > self.size.height / size.height
    }
    
    // calc image view size to fit maxium size
    func calcImageSize(toFitSize size: CGSize) -> CGSize {
        if self.size.width == 0 || self.size.height == 0 {
            return self.size
        }
        var width: CGFloat = 0
        var height: CGFloat = 0
        if shouldScaleWidth(toFitSize: size) {
            width = size.width
            height = width * self.size.height / self.size.width
        } else {
            height = size.height
            width = height * self.size.width / self.size.height
        }
        return CGSize(width: width, height: height)
    }
    
    // crop image with transform
    func cropTransformImage(maskFrame: CGRect,
                            transform: CGAffineTransform,
                            isFlipped: Bool = false) -> UIImage {
        guard
            let ciImage = CIImage(image: self),
            let ciFilter = CIFilter(name: "CIAffineTransform",
                                    parameters: [kCIInputImageKey: ciImage])
            else { return self }
        ciFilter.setDefaults()
        var cropTransform = transform.inverted2DMatrixTransform()
        if isFlipped {
            cropTransform = cropTransform.flipped2DMatrixTransform()
        }
        ciFilter.setValue(cropTransform, forKey: "inputTransform")
        let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
        guard
            let outputImage = ciFilter.outputImage,
            let imageRef = context.createCGImage(outputImage, from: outputImage.extent),
            let result = UIImage(cgImage: imageRef).cropImage(in: maskFrame)
            else { return self }
        return result
    }
}

extension String {
    static func getListEmojis() -> [String] {
        var emojis: [String] = []
        for cateName in emojiCategoryNames {
            let cate = emojiCategories[cateName] ?? []
            emojis.append(contentsOf: cate)
        }
        return emojis
    }
}

public extension Reactive where Base: UITextView {
    
    var textColor: Binder<UIColor?> {
        return Binder(base) { $0.textColor = $1 }
    }
    
    var textAlignment: Binder<NSTextAlignment> {
        return Binder(base) { $0.textAlignment = $1 }
    }
    
    var font: Binder<UIFont?> {
        return Binder(base) { $0.font = $1 }
    }
}

public extension Reactive where Base: UILabel {
    var font: Binder<UIFont?> {
        return Binder(base) { $0.font = $1 }
    }
}

public extension Reactive where Base: UIStackView {
    var alignment: Binder<UIStackView.Alignment> {
        return Binder(base) { $0.alignment = $1 }
    }
}

public extension UITextView {
    func buildEditorTextView() {
        layer.masksToBounds = true
        layer.cornerRadius = 4
        isScrollEnabled = false
        contentInset = .zero
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = 6
        layoutManager.usesFontLeading = false
        autocorrectionType = .no
        spellCheckingType = .no
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
        textContainerInset = .only(top: 10, bottom: 10, left: 10, right: 10)
    }
    
    func scrollToBottom() {
        if text.count > 0 {
            let location = CGPoint(x: 0, y: max(0, contentSize.height - frame.size.height))
            setContentOffset(location, animated: true)
            isScrollEnabled = false
            isScrollEnabled = true
        }
    }
}

extension UIAlertController {
    static func showAlertController(in viewController: UIViewController, title: String? = nil, message: String? = nil, cancelButtonTitle: String? = nil, otherButtonTitles: [String]? = nil, tap: ((_ alertVC: UIAlertController, _ buttonIndex: Int) -> Void)? = nil) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: cancelButtonTitle ?? "Hủy", style: UIAlertAction.Style.cancel, handler: { (action) in
            tap?(controller, 0)
        }))
        if let otherTitles = otherButtonTitles {
            for i in 0..<otherTitles.count {
                controller.addAction(UIAlertAction(title: otherTitles[i], style: .default, handler: { (action) in
                    tap?(controller, cancelButtonTitle != nil ? i + 1 : i)
                }))
            }
        }
        viewController.present(controller, animated: true, completion: nil)
    }
}

public extension Notification {
    func getKeyboardFrame() -> CGRect {
        if let keyboardFrame: NSValue = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            return keyboardFrame.cgRectValue
        }
        return CGRect.zero
    }
    
    func getKeyboardHeight() -> CGFloat {
        let keyboardFrame = getKeyboardFrame()
        let keyboardHeight = keyboardFrame.height
        return keyboardHeight
    }
}

