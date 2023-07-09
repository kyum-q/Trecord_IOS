//
//  SettingViewController.swift
//  IOSProject
//
//  Created by MacBookAir69 on 2023/06/20.
//

import UIKit
import FirebaseAuth

class SettingViewController: UIViewController {
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var traceLabel: UILabel!
    
    var traceGroup: TraceGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 현재 로그인된 사용자 가져오기
        if let currentUser = Auth.auth().currentUser {
            // 사용자의 이메일 정보 가져오기
            if let email = currentUser.email {
                emailLabel.text = email
            }
        }
        
        traceLabel.text = "\(traceGroup.traces.count) 개"
    }
    
    @IBAction func logout(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            // 로그아웃 성공
            showToast(message: "로그아웃이 되었습니다.")
            if let rootViewController = navigationController?.viewControllers.first {
                navigationController?.setViewControllers([rootViewController], animated: false)
            }
        } catch let signOutError as NSError {
            // 로그아웃 실패 처리
            print("로그아웃 실패: \(signOutError.localizedDescription)")
            
            showToast(message: "로그아웃이 실패하였습니다.")
        }
    }
    
    
    @IBAction func backAction(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
}
