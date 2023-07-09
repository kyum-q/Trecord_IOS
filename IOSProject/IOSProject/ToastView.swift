//
//  ToastView.swift
//  IOSProject
//
//  Created by MacBookAir69 on 2023/06/18.
//

import UIKit

class ToastView: UIView {
    // 토스트 메시지를 표시할 레이블
    private let messageLabel: UILabel
    
    // 초기화 메소드
    init(frame: CGRect, message: String) {
        messageLabel = UILabel(frame: CGRect(x: 10, y: 10, width: frame.width - 20, height: frame.height - 20))
        messageLabel.text = message
        messageLabel.textAlignment = .center
        messageLabel.textColor = .white
        messageLabel.backgroundColor = UIColor(white: 0, alpha: 0.7)
        messageLabel.layer.cornerRadius = 10
        messageLabel.clipsToBounds = true
        
        super.init(frame: frame)
        
        addSubview(messageLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


func showToast(message: String, duration: TimeInterval = 2.0) {
    let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: 200, height: 50), message: message)
    toastView.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)
    
    UIApplication.shared.keyWindow?.addSubview(toastView)
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
        toastView.removeFromSuperview()
    }
}
