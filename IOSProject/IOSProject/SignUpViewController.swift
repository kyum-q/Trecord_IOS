//
//  SignUpViewController.swift
//  IOSProject
//
//  Created by MacBookAir69 on 2023/06/17.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var pwTextField: UITextField!
    @IBOutlet weak var checkPwTextField: UITextField!
    
    @IBOutlet weak var emailWarning: UILabel!
    @IBOutlet weak var pwWarning: UILabel!
    @IBOutlet weak var pwCheckWarning: UILabel!
    @IBOutlet weak var Warning: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerKeyboardNotifications()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
}

extension SignUpViewController {
    
    @IBAction func singUpAction(_ sender: UIButton) {
        // 비밀번호 확인
        if pwTextField.text == checkPwTextField.text {
            pwCheckWarning.isHidden = true
            // 이메일 형식 확인
            if let email = emailTextField.text,  email.contains("@"), email.contains(".com") {
                emailWarning.isHidden = true
                // pw 글자수 확인
                if let pw = pwTextField.text, pw.count >= 6 {
                    pwWarning.isHidden = true
                    // 회원가입 시도
                    Auth.auth().createUser(withEmail: email, password: pw) { (user, error) in
                        if let error = error {
                            let errorMessage: String
                            switch error.localizedDescription {
                            case "The email address is badly formatted.":
                                errorMessage = "올바른 이메일 주소 형식을 입력해주세요."
                            case "The email address is already in use by another account.":
                                errorMessage = "이미 사용 중인 이메일 주소입니다."
                            case "Network error (such as timeout, interrupted connection, or unreachable host) has occurred.":
                                errorMessage = "네트워크 오류가 발생했습니다. 다시 시도해주세요."
                            default:
                                errorMessage = "회원가입에 실패했습니다."
                            }
                            self.Warning.text = errorMessage
                            self.Warning.isHidden = false
                        } else {
                            // 회원가입 성공 시 처리할 내용
                            self.Warning.isHidden = true
                            
                            showToast(message: "회원가입 되었습니다.")
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
                else {
                    pwWarning.isHidden = false
                    Warning.isHidden = true
                }
            }
            else {
                emailWarning.isHidden = false
                Warning.isHidden = true
            }
        }
        else {
            pwCheckWarning.isHidden = false
        }
    }
}

extension SignUpViewController {
    // MARK: content 입력 창 외에 창을 클릭시 키보드 없어지게 도와주는 tap 설정
    @objc func dismissKeyboard(sender: UIGestureRecognizer) {
        emailTextField.resignFirstResponder()
        pwTextField.resignFirstResponder()
        checkPwTextField.resignFirstResponder()
    }
}

extension SignUpViewController {
    @IBAction func backAction(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: 키보드가 나타났을 때 뷰가 가려지지 않게 하기 위해서
extension SignUpViewController {
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
