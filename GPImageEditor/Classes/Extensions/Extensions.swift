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

extension UITextView {
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
