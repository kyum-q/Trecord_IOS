//
//  TraceGroupViewController.swift
//  IOSProject
//
//  Created by MacBookAir69 on 2023/06/18.
//

import UIKit
import FirebaseStorage //import하기
import FirebaseAuth

class TraceGroupViewController: UIViewController {

    @IBOutlet weak var traceGroupTableView: UITableView!
    @IBOutlet weak var detailMenuView: UIView!
    @IBOutlet weak var loadingBar: UIActivityIndicatorView!
    @IBOutlet weak var colorListView: UIView!
    
    var selectedColorIndex: Int!
    var selectedButton: UIButton!
    
    var userEmail: String!
    var traceGroup: TraceGroup!
    var traces: [Trace] = []

    let storage = Storage.storage() //인스턴스 생성
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingBar.hidesWhenStopped = true // 로딩바 초기 설정
        
        // detailMenuView에 그림자 주기
        detailMenuView.layer.shadowColor = UIColor.black.cgColor // 그림자 색상
        detailMenuView.layer.shadowOpacity = 0.5 // 그림자 투명도 (0.0 ~ 1.0)
        detailMenuView.layer.shadowOffset = CGSize(width: 2, height: 2) // 그림자 오프셋
        detailMenuView.layer.shadowRadius = 4 // 그림자 반경
        detailMenuView.layer.masksToBounds = false // true로 설정하면 그림자가 UIView 경계 내에서 잘립니다.
        
        // 단순히 planGroup객체만 생성한다
        traceGroup = TraceGroup(parentNotification: receivingNotification, email: userEmail)
        traceGroup.queryData(date: Date())       // 이달의 데이터를 가져온다. 데이터가 오면 planGroupListener가 호출된다.
        
        if traceGroup.traces.count > 0 {
            loadingBar.startAnimating() // 로딩바 실행
        }
        
        selectedColorIndex = 0
        selectedButton = colorListView.subviews[0] as? UIButton
//        setColorSetting(selectedButton, selectedColorIndex)
        
        // tableview 초기설정
        traceGroupTableView.dataSource = self        // 데이터 소스로 등록
        traceGroupTableView.delegate = self        // 딜리게이터로 등록
    }

    func receivingNotification(trace: Trace?, action: DbAction?){
        // 데이터가 올때마다 이 함수가 호출되는데 맨 처음에는 기본적으로 add라는 액션으로 데이터가 온다.
        self.traceGroupTableView.reloadData()  // 속도를 증가시키기 위해 action에 따라 개별적 코딩도 가능하다.
    }
}

extension TraceGroupViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if selectedColorIndex == 0 {
            if let traceGroup = traceGroup{
                return traceGroup.traces.count
            }
        }
        else {
            return traces.count
        }
        return 0    // traceGroup가 생성되기전에 호출될 수도 있다
    }
    
    // 화면에 표시되는 index별 화면 구성
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TraceTableViewCell", for: indexPath)

        var newTraces = traceGroup.traces
        if selectedColorIndex != 0 {
            newTraces = traces
        }
        
        // 날짜 정렬
        newTraces.sort { $0.date > $1.date }
        
        var trace = newTraces[indexPath.row]
        
        (cell.contentView.subviews[0] as! UILabel).text = trace.locationTitle
                (cell.contentView.subviews[1] as! UILabel).text = trace.locationAddress
        (cell.contentView.subviews[2] as! UILabel).text = formatDate(trace.date)
        
        if trace.imageUrl != nil {
            if let image = trace.image as? UIImage {
                (cell.contentView.subviews[3] as! UIImageView).image = image
            }
            else {
//                DispatchQueue.global().async {
                    var image = trace.getImage()
                    if let image = image {
                        // 메인 스레드에서 mapView에 Annotation 추가
//                            DispatchQueue.main.async {
                            (cell.contentView.subviews[3] as! UIImageView).image  = image
//                        }
                    }
//                }
            }
        } else {
            (cell.contentView.subviews[3] as! UIImageView).image = nil
        }
        return cell
    }

    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 셀이 화면에 표시된 후 호출됨
        var count = traceGroup.traces.count
        if selectedColorIndex != 0 {
            count = traces.count
        }
        
        if indexPath.row == 0 {
            // 마지막 셀이 화면에 표시되었을 때 동작 수행 -> 로딩 끝
            loadingBar.stopAnimating()
        }
    }
    
}

// MARK: UITableViewDelegate
extension TraceGroupViewController: UITableViewDelegate{
    // UITableView의 특정 셀을 클릭했을 때 호출되는 메서드
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // 클릭한 셀에 대한 작업을 수행합니다.
        // viewcontroller 제작 후 이동
        let viewController = storyboard?.instantiateViewController(withIdentifier: "TraceAddViewController") as? TraceAddViewController
        if let viewController = viewController {
            viewController.isEdit = true
            
            if let row = traceGroupTableView.indexPathForSelectedRow?.row {
                var newTraces = traceGroup.traces
                if selectedColorIndex != 0 {
                    newTraces = traces
                }
                newTraces.sort { $0.date > $1.date }
                
                let setTrace = newTraces[row]
                
                // trace 전달
                viewController.trace = setTrace
                viewController.traceGroup = traceGroup
                
                viewController.delegate = presentingViewController as? TraceAddViewControllerDelegate
                
                present(viewController, animated: true, completion: nil)
            }
        }
    }
}

extension TraceGroupViewController {
    @IBAction func backAction(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func settingAction(_ sender: UIBarButtonItem) {
        if(detailMenuView.isHidden) {
            detailMenuView.isHidden = false
        }
        else {
            detailMenuView.isHidden = true
        }
    }
}

extension TraceGroupViewController {
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
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
    
    @IBAction func gotoSettingView(_ sender: UIButton) {
        // viewcontroller 제작 후 이동
        let viewController = storyboard?.instantiateViewController(withIdentifier: "SettingViewController") as? SettingViewController
        if let viewController = viewController {
            
            viewController.traceGroup = traceGroup
//            present(viewController, animated: true, completion: nil)
            self.navigationController?.pushViewController(viewController, animated: false)
        }
    }
}

extension TraceGroupViewController {
    @IBAction func color1Selected(_ sender: UIButton) {
        selectedColorIndex = 1
        setColorSetting(sender, selectedColorIndex)
    }
    @IBAction func color2Selected(_ sender: UIButton) {
        selectedColorIndex = 2
        setColorSetting(sender, selectedColorIndex)
    }
    @IBAction func color3Selected(_ sender: UIButton) {
        selectedColorIndex = 3
        setColorSetting(sender, selectedColorIndex)
    }
    @IBAction func color4Selected(_ sender: UIButton) {
        selectedColorIndex = 4
        setColorSetting(sender, selectedColorIndex)
    }
    @IBAction func color5Selected(_ sender: UIButton) {
        selectedColorIndex = 5
        setColorSetting(sender, selectedColorIndex)
    }
    @IBAction func color6Selected(_ sender: UIButton) {
        selectedColorIndex = 6
        setColorSetting(sender, selectedColorIndex)
    }
    @IBAction func color7Selected(_ sender: UIButton) {
        selectedColorIndex = 7
        setColorSetting(sender, selectedColorIndex)
    }
    
    func setColorSetting(_ sender: UIButton, _ selectedColorIndex: Int) {
        selectedButton.layer.borderColor = UIColor.white.cgColor
        
        removeButtonBorder(selectedButton)
        addButtonBorder(sender, borderColor: getSeletedColor(selectedColorIndex).cgColor)

        // 선택한 색상에 관한 발자국 기록만 가져온다
        traces = traceGroup.findEqualsColorTraces(selectedColorIndex)
        traceGroupTableView.reloadData()
        
        selectedButton = sender
    }
}
