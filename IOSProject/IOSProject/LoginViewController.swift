//
//  LoginViewController.swift
//  IOSProject
//
//  Created by MacBookAir69 on 2023/06/17.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var pwTextField: UITextField!
    
    @IBOutlet weak var warning: UILabel!
    @IBOutlet weak var emailWarning: UILabel!
    @IBOutlet weak var pwWarning: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerKeyboardNotifications()
        
        // content 입력 창 외에 창을 클릭시 키보드 없어지게 도와주는 tap 설정
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        if let user = Auth.auth().currentUser {

            let viewController = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController
            if let viewController = viewController {
                // trace 전달
                viewController.userEmail = user.email

                self.navigationController?.pushViewController(viewController, animated: false)
            }
        }
    }
}

extension LoginViewController {
    
    @IBAction func loginActioin(_ sender: UIButton) {
        warning.isHidden = true
        emailWarning.isHidden = true
        pwWarning.isHidden = true
        if let emailText = emailTextField.text, !emailText.isEmpty {
            
            if let pwText = pwTextField.text, !pwText.isEmpty {
                Auth.auth().signIn(withEmail: emailText, password: pwText) { (user, error) in
                    
                    if let error = error {
                        // 인증 과정 중에 에러가 발생한 경우 처리할 코드를 작성합니다.
                        print("로그인 에러: \(error.localizedDescription)")
                        self.warning.isHidden = false
                    } else {
                        // 인증이 성공한 경우 사용자 객체(user)를 통해 추가 작업을 수행할 수 있습니다.
                        if let user = user {
                            print("로그인 성공! 사용자 ID: \(user.user)")
                            // 로그인 성공 후 실행할 코드를 작성합니다.
                            
                            showToast(message: "로그인 되었습니다.")
                            
                            // viewcontroller 제작 후 이동
                            let viewController = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController
                            if let viewController = viewController {
                                // userEmail 전달
                                viewController.userEmail = user.user.email
                                
                                self.navigationController?.pushViewController(viewController, animated: false)
                            }
                        }
                    }
                }
            }
            else {
                pwWarning.isHidden = false
            }
        }
        else {
            emailWarning.isHidden = false
        }
    }
    
    @IBAction func singUpAction(_ sender: UIButton) {
        // viewcontroller 제작 후 이동
        let viewController = self.storyboard?.instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController
        if let viewController = viewController {
            self.navigationController?.pushViewController(viewController, animated: false)
        }
    }
    
}

extension LoginViewController {
    // MARK: content 입력 창 외에 창을 클릭시 키보드 없어지게 도와주는 tap 설정
    @objc func dismissKeyboard(sender: UIGestureRecognizer) {
        emailTextField.resignFirstResponder()
        pwTextField.resignFirstResponder()
    }
}

// MARK: 키보드가 나타났을 때 뷰가 가려지지 않게 하기 위해서
extension LoginViewController {
    // 키보드가 나타날 때 호출되는 셀렉터 메서드
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardRect = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRect.height
        
        // 뷰를 키보드의 높이만큼 올리기
        UIView.animate(withDuration: 0.3) {
            self.view.frame.origin.y = -keyboardHeight+235
        }
    }

    // 키보드가 사라질 때 호출되는 셀렉터 메서드
    @objc func keyboardWillHide(notification: NSNotification) {
        // 뷰를 원래 위치로 복원하기
        UIView.animate(withDuration: 0.3) {
            self.view.frame.origin.y = 0
        }
    }

    // 키보드 옵저버 등록
    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // 키보드 옵저버 해제
    func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // 뷰 컨트롤러의 viewDidLoad() 메서드나 필요한 곳에서 registerKeyboardNotifications()를 호출하여 키보드 옵저버를 등록하고,
    // 뷰 컨트롤러가 해제될 때 unregisterKeyboardNotifications()를 호출하여 키보드 옵저버를 해제합니다.

}
