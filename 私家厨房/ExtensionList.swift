
import UIKit
import CloudKit

// Use the TableView style name as the reusable ID.
// For a custom cell, use the class name.

extension Notification.Name {
    static let zoneCacheDidChange = Notification.Name("zoneCacheDidChange")
    static let mealCacheDidChange = Notification.Name("mealCacheDidChange")
    static let reservedMealsDeleted = Notification.Name("reservedMealsDeleted")
    static let reservedMealsAdded = Notification.Name("reservedMealsAdded")
	static let dateChanged = Notification.Name("dateChanged")
}

enum NotificationReason {
    case zoneNotFound
    case switchTopic
}

struct NotificationObjectKey {
    static let reason = "reason"
    static let recordIDsDeleted = "recordIDsDeleted"
    static let recordsChanged = "recordsChanged"
    static let sharedRecordChanged = "sharedRecordChanged"
    static let newMeal = "newMeal"
    static let reservedMealsDeleted = "reservedMealsDeleted"
}

extension UIViewController {
    func showErrorView(_ error: Error?) {
        guard let error = error as NSError?, let errorMessage = error.userInfo["error"] as? String else {
            return
        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                message: errorMessage,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""),
                                                style: .default))
        
        present(alertController, animated: true)
    }
}

extension UIColor {
    
    convenience init(hex:Int, alpha:CGFloat = 1.0) {
        self.init(
            red:   CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8)  / 255.0,
            blue:  CGFloat((hex & 0x0000FF) >> 0)  / 255.0,
            alpha: alpha
        )
    }
}

extension UIView {
    
    func rotate(_ toValue: CGFloat, duration: CFTimeInterval = 0.2) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        
        animation.toValue = toValue
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        
        self.layer.add(animation, forKey: nil)
    }
}

class UIButtonWithBadgeNumber : UIButton {
    let badgeView = UILabel()
    convenience init() {
        self.init()
        self.superview?.addSubview(badgeView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
