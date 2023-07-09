//
//  TraceAddViewController.swift
//  IOSProject
//
//  Created by MacBookAir69 on 2023/06/16.
//

import UIKit
import FirebaseStorage //import하기

protocol TraceAddViewControllerDelegate: AnyObject {
    func traceAddViewControllerDidUpdateValue(_ trace: Trace)
    func traceRemoveViewControllerDidUpdateValue(_ trace: Trace)
}

class TraceAddViewController: UIViewController {
    
    @IBOutlet weak var date: UIDatePicker!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var contentLabel: UITextView!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var traceBtn: UIButton!
    @IBOutlet weak var resetTitleBtn: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var colorListView: UIView!
    @IBOutlet weak var loadingBar: UIActivityIndicatorView!
    
    let placeholderLabel = UILabel()
    
    var isClicked: Bool = false
    weak var delegate: TraceAddViewControllerDelegate?
    
    var traceGroup: TraceGroup!
    var trace: Trace!
    
    var isEdit = false
    
    var selectedColorIndex: Int!
    var selectedButton: UIButton!
    var isContentKeboard: Bool = false
    
    let storage = Storage.storage() //인스턴스 생성
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerKeyboardNotifications()
        
        loadingBar.hidesWhenStopped = true // 로딩바 초기 설정
        
        titleTextField.text = trace.locationTitle
        addressLabel.text = trace.locationAddress
        if let content = trace.content {
            contentLabel.text = content
        }
        if trace.imageUrl != nil {
            if let newImage = trace.image as? UIImage {
                imageView.image = newImage
            }
            else {
                imageView.image = trace.getImage()
            }
        }
        
        selectedColorIndex = trace.colorIndex
        selectedButton = colorListView.subviews[self.selectedColorIndex - 1] as? UIButton
        setColorSetting(selectedButton, selectedColorIndex)
        
        if isEdit {
            isClicked = true
            addBtn.setTitle("Edit", for: .normal)
            let clickedImage = UIImage(named: "fill_pawprint")
            traceBtn.setImage(clickedImage, for: .normal)
        }
        
        // content 입력 창 외에 창을 클릭시 키보드 없어지게 도와주는 tap 설정
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        configurePlaceholderLabel()
        contentLabel.delegate = self
    }
}

extension TraceAddViewController {
    @IBAction func setTraceAction(_ sender: UIButton) {
        if isClicked {
            // 클릭된 상태에서 다른 이미지로 변경
            isClicked = false
            let clickedImage = UIImage(named: "empty_pawprint")
            traceBtn.setImage(clickedImage, for: .normal)
        } else {
            isClicked = true
            let clickedImage = UIImage(named: "fill_pawprint")
            traceBtn.setImage(clickedImage, for: .normal)
        }
    }
    
    @IBAction func resetTitle(_ sender: UIButton) {
        titleTextField.text = ""
    }
    
    @IBAction func resetContent(_ sender: UIButton) {
        contentLabel.text = ""
        configurePlaceholderLabel()
    }
    
    @IBAction func addImage(_ sender: UIButton) {
        // 컨트로러를 생성
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self // 딜리게이터를 설정 -> 사진을 찍은후 호출
        
        imagePickerController.sourceType = .photoLibrary
        
        // UIImagePickerController이 활성화
        present(imagePickerController, animated: true, completion: nil)
    }
}

extension TraceAddViewController {
    // MARK: content 입력 창 외에 창을 클릭시 키보드 없어지게 도와주는 tap 설정
    @objc func dismissKeyboard(sender: UIGestureRecognizer) {
        contentLabel.resignFirstResponder()
        titleTextField.resignFirstResponder()
        isContentKeboard = false
    }
}

extension TraceAddViewController {
   
    override func viewWillDisappear(_ animated: Bool) {
        if isClicked {
            saveTrace(addBtn)
        }
        else {
            traceGroup.saveChange(trace: trace, action: .Delete)
            delegate?.traceRemoveViewControllerDidUpdateValue(trace)
        }
    }
    
    // MARK: 저장 버튼 클릭시 데이터 베이스에 저장
    @IBAction func saveTrace(_ sender: UIButton) {
        trace.date = date.date
        trace.locationTitle = titleTextField.text ?? ""
        trace.content = contentLabel.text
        trace.colorIndex = selectedColorIndex
        
        // 데이터베이스에 저장
        traceGroup.saveChange(trace: trace!, action: .Add)
        
        delegate?.traceAddViewControllerDidUpdateValue(trace)
    }
}

extension TraceAddViewController {
    // MARK: database에서 데이터가 변화될 때 호출되는 함수
    func receivingNotification(trace: Trace?, action: DbAction?){
        // 데이터가 올때마다 이 함수가 호출되는데 맨 처음에는 기본적으로 add라는 액션으로 데이터가 온다.
    }
}

extension TraceAddViewController: UITextViewDelegate {

    func configurePlaceholderLabel() {
        placeholderLabel.text = "당신의 발자국을 남겨주세요."
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.sizeToFit()
        contentLabel.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 5, y: contentLabel.font!.pointSize / 2)
        placeholderLabel.isHidden = !contentLabel.text.isEmpty
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !contentLabel.text.isEmpty
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
           // 키보드가 나타났을 때 실행되는 코드
           isContentKeboard = true
       }

       func textViewDidEndEditing(_ textView: UITextView) {
           // 키보드가 사라졌을 때 실행되는 코드
           isContentKeboard = false
       }
}


extension TraceAddViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // 여기서 이미지에 대한 추가적인 작업을 한다
            imageView.image = image
            upLoadImage(img: image)
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    // 사진 캡쳐를 취소하는 경우 호출 함수
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // imagePickerController을 죽인다
        picker.dismiss(animated: true, completion: nil)
    }
    
    func upLoadImage(img: UIImage){
        loadingBar.startAnimating() // 로딩바 실행
        
        var data = Data()
        data = img.jpegData(compressionQuality: 0.8)! //지정한 이미지를 포함하는 데이터 개체를 JPEG 형식으로 반환, 0.8은 데이터의 품질을 나타낸것 1에 가까울수록 품질이 높은 것
        let filePath = trace.locationAddress
        let metaData = StorageMetadata() //Firebase 저장소에 있는 개체의 메타데이터를 나타내는 클래스, URL, 콘텐츠 유형 및 문제의 개체에 대한 FIRStorage 참조를 검색하는 데 사용
        metaData.contentType = "image/png" //데이터 타입을 image or png 팡이
        
        let storageRef = storage.reference().child(filePath)
        
        storageRef.putData(data, metadata: metaData){
            (metaData,error) in if let error = error { //실패
                print(error)
                return
            }else{ //성공
                print("성공")
                storageRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        // URL 얻기 실패
                        return
                    }
                    
                    // downloadURL을 사용하여 필요한 작업 수행
                    print("다운로드 URL:", downloadURL)
                    
                    self.trace.imageUrl = downloadURL.absoluteString
                    //                    let imageUrlString = imgUrl.absoluteString
                    
                    self.loadingBar.stopAnimating()
                    showToast(message: "사진이 업로드 되었습니다.")
                }
            }
        }
    }
}

func getSeletedColor(_ index: Int) -> UIColor {
    var selectedColor: UIColor
    switch index {
    case 1:
        selectedColor = UIColor(red: 255/255.0, green: 126/255.0, blue: 121/255.0, alpha: 1)
    case 2:
        selectedColor = UIColor(red: 239/255.0, green: 178/255.0, blue: 121/255.0, alpha: 1)
    case 3:
        selectedColor = UIColor(red: 255/255.0, green: 212/255.0, blue: 121/255.0, alpha: 1)
    case 4:
        selectedColor = UIColor(red: 255/255.0, green: 252/255.0, blue: 121/255.0, alpha: 1)
    case 5:
        selectedColor = UIColor(red: 103/255.0, green: 254/255.0, blue: 109/255.0, alpha: 1)
    case 6:
        selectedColor = UIColor(red: 114/255.0, green: 157/255.0, blue: 247/255.0, alpha: 1)
    case 7:
        selectedColor = UIColor(red: 193/255.0, green: 164/255.0, blue: 248/255.0, alpha: 1)
    default:
        selectedColor = .white
    }
    return selectedColor
}

extension TraceAddViewController {
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

        selectedButton = sender
    }
}

func addButtonBorder(_ sender: UIButton, borderColor: CGColor) {
    let spacing: CGFloat = 6.0 // 버튼과 테두리 사이의 여백 크기

    // 테두리 레이어 생성
    let borderLayer = CALayer()
    borderLayer.frame = sender.frame.insetBy(dx: -spacing, dy: -spacing)
    borderLayer.borderWidth = 2.0 // 테두리 두께 설정
    borderLayer.cornerRadius = 20 // 버튼을 원형으로 만들기 위한 반지름 설정
    borderLayer.borderColor = borderColor // 테두리 색상 설정

    // 버튼의 레이어 순서 변경
    sender.layer.zPosition = 1
    // 테두리 레이어를 버튼의 상위 레이어로 추가
    sender.layer.superlayer?.insertSublayer(borderLayer, below: sender.layer)
}

func removeButtonBorder(_ sender: UIButton) {
    let spacing: CGFloat = 8.0 // 버튼과 테두리 사이의 여백 크기

    // 테두리 레이어 생성
    let borderLayer = CALayer()
    borderLayer.frame = sender.frame.insetBy(dx: -spacing, dy: -spacing)
    borderLayer.borderWidth = 10.0 // 테두리 두께 설정
    borderLayer.cornerRadius = 20 // 버튼을 원형으로 만들기 위한 반지름 설정
    borderLayer.borderColor = UIColor.white.cgColor // 테두리 색상 설정

    // 버튼의 레이어 순서 변경
    sender.layer.zPosition = 1
    // 테두리 레이어를 버튼의 상위 레이어로 추가
    sender.layer.superlayer?.insertSublayer(borderLayer, below: sender.layer)
}

// MARK: 키보드가 나타났을 때 뷰가 가려지지 않게 하기 위해서
extension TraceAddViewController {
    // 키보드가 나타날 때 호출되는 셀렉터 메서드
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardRect = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRect.height
        
        
        if isContentKeboard {
            // 뷰를 키보드의 높이만큼 올리기
            UIView.animate(withDuration: 0.3) {
                self.view.frame.origin.y = -keyboardHeight
            }
        }
    }

    // 키보드가 사라질 때 호출되는 셀렉터 메서드
    @objc func keyboardWillHide(notification: NSNotification) {
        if isContentKeboard {
            // 뷰를 원래 위치로 복원하기
            UIView.animate(withDuration: 0.3) {
                self.view.frame.origin.y = 0
            }
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
