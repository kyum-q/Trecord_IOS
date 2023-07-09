//
//  MapViewController.swift
//  IOSProject
//
//  Created by MacBookAir69 on 2023/06/16.
//

import UIKit
import MapKit


class MapViewController: UIViewController {
    
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var dataAddBtn: UIButton!
    @IBOutlet weak var locationAddress: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchScrollView: UIScrollView!
    
    var locationManager: CLLocationManager!
    
    var userEmail: String!
    
    var isClicked: Bool = false
    var clickLocation: [String:Double?] = ["lon": nil, "lat": nil]
    var clickTrace: Trace? = nil
    
    var currentLocation: [String:Double?] = ["lon": nil, "lat": nil]
    var currentCenter : CLLocationCoordinate2D!
    
    var traceGroup: TraceGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        
        // 단순히 planGroup 객체 생성
        traceGroup = TraceGroup(parentNotification: receivingNotification, email: userEmail)
        // 데이터를 가져오기
        traceGroup.queryData(date: Date())
        
        // mapView delegate 등록
        mapView.delegate = self
        
        // 맵에 Tap 제스처를 추가 -> 맵 클릭시 해당 주소에 관한 정보 띄우기
        let mapTap = UITapGestureRecognizer(target: self, action: #selector(self.didTappedMapView(_:)))
        mapView.addGestureRecognizer(mapTap)
        currentCenter = mapView.centerCoordinate // 일단 기존의 중심을 저장
        
        // UITapGestureRecognizer 생성 및 추가
        let detailTap = UITapGestureRecognizer(target: self, action: #selector(viewClicked(_:)))
        detailView.addGestureRecognizer(detailTap)
        
        // 검색하다 다른 창 눌렀을 때 키보드 지우기
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        initLocationManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // annotation 제거
        removePreAnnotations()
        moveCurrentLocation()
    }
}

extension MapViewController {
    
    // MARK: locationManager 설정
    func initLocationManager() {
        // 현재 위치 알기 위한 설정
        locationManager = CLLocationManager()
        
        // locationManager delegate 설정
        locationManager.delegate = self
        
        // 지도의 정확도 최고로 설정
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // didchangeAutorization 호출
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: database에서 데이터를 가져올때마다 호출되는 함수
    func receivingNotification(trace: Trace?, action: DbAction?){
        // 데이터가 올때마다 이 함수가 호출되는데 맨 처음에는 기본적으로 add라는 액션으로 데이터가 온다.
        // 데이터들 모두 annotation 설정
        if action == .Add {
            if let trace = trace {
                addMap(trace: trace)
            }
        }
    }
}

extension MapViewController {
    
    // MARK: 현재 위치를 지도의 중심으로 바꾸기
    func moveCurrentLocation() {
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: currentCenter, span: span)
        mapView.setRegion(region, animated: true) //현재 위치를 중심으로 지도를 설정
    }
    
    // MARK: 현재 위치에 annotation 추가
    func setCurrentLocationAnnotation() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = currentCenter // 현재 위치가 저장된 센터에 annotation을 설치
        
        annotation.title = "현재위치"
        mapView.addAnnotation(annotation) // annotation 추가
    }
    
    // MARK: 지도에 해당 위치에 annotation 추가
    func addMap(trace: Trace){
        
        var center = mapView.centerCoordinate // 일단 기존의 중심을 저장
        if let longitute = trace.location["lon"], let latitute = trace.location["lat"] {
            if let longitute = longitute, let latitute = latitute{
                center = CLLocationCoordinate2D(latitude: latitute, longitude: longitute) // 새로운 중심 설정
            }
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = center    // 센터에 annotation을 설치
        annotation.title = trace.locationTitle
        if trace.colorIndex != 1 {
            annotation.subtitle = String(trace.colorIndex)
        }
        mapView.addAnnotation(annotation)
    }
}


// MARK: 현재 위치 알아내는 delegate
extension MapViewController: CLLocationManagerDelegate {
    
    //didChangeAuthorization implemetation
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    //didUpdateLocations implemetation
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 현재 위치 정보 사용
        print("현재 위치: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        currentLocation["lon"] = location.coordinate.longitude
        currentLocation["lat"] = location.coordinate.latitude
        
        // 원하는 정확도에 도달했을 때 위치 업데이트 중단
        //        if location.horizontalAccuracy <= locationManager.desiredAccuracy {
        locationManager.stopUpdatingLocation()
        
        if let longitute = currentLocation["lon"], let latitute = currentLocation["lat"] {
            currentCenter = CLLocationCoordinate2D(latitude: latitute!, longitude: longitute!) // 새로운 중심 설정
        }
        
        // 현재 위치로 중심이동 및 annotation 추가
        moveCurrentLocation()
        setCurrentLocationAnnotation()
        //        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 위치 업데이트 실패 처리
        print("위치 업데이트 실패: \(error.localizedDescription)")
    }
}

extension MapViewController {
    // MARK: detail View 클릭 이벤트 핸들러
    @objc func viewClicked(_ sender: UITapGestureRecognizer) {
        dataAdd()
    }
    
    // MARK: 맵을 클릭했을 때 이벤트 처리
    @objc private func didTappedMapView(_ sender: UITapGestureRecognizer) {
        
        searchTextField.resignFirstResponder()
        searchView.isHidden = true
        searchTextField.text = ""
        
        let location: CGPoint = sender.location(in: self.mapView)
        
        let mapPoint: CLLocationCoordinate2D = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        
        if sender.state == .ended {
            self.searchLocation(mapPoint)
        }
    }
    
    // MARK: 자세한 건물 정보를 얻기 위함
    private func searchLocation(_ point: CLLocationCoordinate2D) {
        let geocoder: CLGeocoder = CLGeocoder()
        let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
        
        
        geocoder.reverseGeocodeLocation(location) { (placeMarks, error) in
            if error == nil, let marks = placeMarks {
                
                // 위도경도를 가지고 해당 건물 명과 같은 상세 주소 얻기
                var buildingName = ""
                if let placemark = marks.first, let newBuildingName = placemark.name {
                    // buildingName 전달
                    buildingName = newBuildingName
                }
                
                marks.forEach { (placeMark) in
                    
                    let address = " \(placeMark.administrativeArea ?? "") \(placeMark.locality ?? "") \(placeMark.thoroughfare ?? "") \(placeMark.subThoroughfare ?? "") "
                    
                    // annotation 리셋
                    self.removePreAnnotations()
                    
                    // 해당 위치 clickLocation으로 기록
                    self.clickLocation["lon"] = point.longitude
                    self.clickLocation["lat"] = point.latitude
                    
                    
                    // 해당 건물 명과 같은 상세 주소를 label text로
                    
                    self.setDetailView(address: address, buildingName: buildingName)
                    self.setEmptyPawprint()
                    
                    // 숨겨놨던 view 보이기
                    self.detailView.isHidden = false
                }
                
                // annotation 추가
                self.addMap(trace: Trace(date: Date(), location: self.clickLocation, locationTitle: "", locationAddress: "1"))
            }
            else {
                print("검색 실패")
                self.detailView.isHidden = true
            }
        }
    }
    
    // MARK: 이전 선택한 annotation 제거
    private func removePreAnnotations() {
        // Annotation 제거
        let annotations = mapView.annotations
        for annotation in annotations {
            let coordinate = annotation.coordinate
            if let lat = clickLocation["lat"], let lon = clickLocation["lon"] {
                if coordinate.latitude == lat && coordinate.longitude == lon {
                    mapView.removeAnnotation(annotation)
                }
            }
        }
    }
    
    func setDetailView(address: String, buildingName :String) {
        locationAddress.text = address
        locationName.text = buildingName
    }
}

extension MapViewController {
    
    // MARK: 현재 위치로 중심 이동해주는 버튼 클릭
    @IBAction func setCurrentLocation(_ sender: UIButton) {
        removePreAnnotations()
        moveCurrentLocation()
        self.detailView.isHidden = true
    }
    
    // MARK: 발자취 추가 버튼 클릭시
    @IBAction func dataTraceAction(_ sender: UIButton) {
        if isClicked {
            if let trace = clickTrace {
                traceGroup.saveChange(trace: trace, action: .Delete)
                self.clickLocation = trace.location
                self.removePreAnnotations()
                self.clickTrace = nil
            }
            // 클릭된 상태에서 다른 이미지로 변경
            setEmptyPawprint()
        } else {
            dataAdd()
        }
    }
    
    // MARK: 데이터 추가하는 view controller로
    func dataAdd() {
        // trace 제작
        
        // viewcontroller 제작 후 이동
        let viewController = storyboard?.instantiateViewController(withIdentifier: "TraceAddViewController") as? TraceAddViewController
        if let viewController = viewController {
            var setTrace: Trace!
            
            viewController.isEdit = true
            
            if let trace = clickTrace {
                setTrace = trace
            }
            else {
                setTrace = Trace(date: Date(), location: clickLocation, locationTitle: locationName.text ?? "", locationAddress: locationAddress.text ?? "")
            }
            // trace 전달
            viewController.trace = setTrace
            viewController.traceGroup = traceGroup
            viewController.delegate = self
            
            present(viewController, animated: true, completion: nil)
            //                navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func setEmptyPawprint() {
        clickTrace = nil
        // 클릭된 상태에서 다른 이미지로 변경
        let normalImage = UIImage(named: "empty_pawprint")
        dataAddBtn.setImage(normalImage, for: .normal)
        //        dataAddBtn.isHidden = false
        isClicked = false
    }
    
    func setFillPawprint(newTrace: Trace) {
        clickTrace = newTrace
        setDetailView(address: newTrace.locationAddress, buildingName: newTrace.locationTitle)
        
        // 클릭되지 않은 상태에서 다른 이미지로 변경
        let clickedImage = UIImage(named: "fill_pawprint")
        dataAddBtn.setImage(clickedImage, for: .normal)
        isClicked = true
    }
}

extension MapViewController {
    @IBAction func viewTracesList(_ sender: UIButton) {
        // viewcontroller 제작 후 이동
        let viewController = self.storyboard?.instantiateViewController(withIdentifier: "TraceGroupViewController") as? TraceGroupViewController
        if let viewController = viewController {
            viewController.userEmail = userEmail
            
            self.navigationController?.pushViewController(viewController, animated: false)
        }
    }
}

// MARK: TraceAddController 를 위한 Delegate
extension MapViewController : TraceAddViewControllerDelegate {
    func traceAddViewControllerDidUpdateValue(_ trace: Trace) {
        locationName.text = trace.locationTitle
        
        removePreAnnotations()
        
        clickLocation["lon"] = nil
        clickLocation["lat"] = nil
        
        addMap(trace: trace)
        
        if mapView.selectedAnnotations.count > 0 {
            mapView.removeAnnotation(mapView.selectedAnnotations[0])
        }
        
//        selectAnnotationWithCoordinate(latitude: trace.location["lat"]!!, longitude: trace.location["lon"]!!)
        
    }
    
    func traceRemoveViewControllerDidUpdateValue(_ trace: Trace) {
        
        clickLocation = trace.location
        removePreAnnotations()
        
        clickTrace = nil
        // 클릭된 상태에서 다른 이미지로 변경
        let normalImage = UIImage(named: "empty_pawprint")
        dataAddBtn.setImage(normalImage, for: .normal)
        //        dataAddBtn.isHidden = false
        isClicked = false
    }
}

// MARK: annotation 커스텀을 도와주는 delegate
extension MapViewController: MKMapViewDelegate {
    // MKMapViewDelegate 메서드
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            // 현재 사용자의 위치 Annotation은 기본 뷰를 사용합니다.
            return nil
        }
        
        // Annotation 뷰의 색상 설정
        if annotation.title == "현재위치" {
            
            // 커스텀 Annotation 뷰 생성
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "CurrentAnnotation")
            
            let image = UIImage(named: "cat_face") // 사용할 이미지 이름으로 변경해야 합니다.
            annotationView.glyphImage = image
            annotationView.markerTintColor = .black
            annotationView.glyphTintColor = .white
            
            return annotationView
        } else {
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnotation")
            
            let image = UIImage(named: "fill_pawprint") // 사용할 이미지 이름으로 변경해야 합니다.
            annotationView.glyphImage = image
            if let index = Int((annotation.subtitle ?? "1") ??  "1") {
                annotationView.markerTintColor = getSeletedColor(index)
            }
            annotationView.glyphTintColor = .white
            
            
            return annotationView
        }
    }
    
    
    // MARK: Annotation 클릭 시 호출되는 콜백 메서드입니다.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        searchTextField.resignFirstResponder()
        searchView.isHidden = true
        searchTextField.text = ""
        
        
        // 클릭된 Annotation에 대한 정보를 가져옵니다.
        if let annotation = view.annotation as? MKPointAnnotation {
            let coordinate = annotation.coordinate
            // 클릭된 Annotation에 대한 추가 작업을 수행합니다.
            // 예: 상세 정보 표시, 다른 뷰로 이동 등
            
            let newTrace = traceGroup.findTrace(["lon": coordinate.longitude, "lat": coordinate.latitude])
            if let newTrace = newTrace {
                removePreAnnotations()
                
                clickLocation["lon"] = nil
                clickLocation["lat"] = nil
                
                annotation.title = newTrace.locationTitle
                annotation.subtitle = ""
                setFillPawprint(newTrace: newTrace)
            }
        }
    }
}

// MARK: 위치검색 액션
extension MapViewController {
    @IBAction func searchTextField(_ sender: UITextField) {
        setEmptyPawprint()
        
        searchView.isHidden = false
        
        for subview in self.searchScrollView.subviews {
            subview.removeFromSuperview()
        }
        
        if let text = sender.text {
            for trace in traceGroup.traces {
                if trace.locationTitle.contains(text) {
                    print("result :\(trace.locationTitle)")
                    
                    let button = UIButton(type: .system)
                    button.frame = CGRect(x: 0, y: 0, width: searchScrollView.frame.width, height: 20)
                    button.setTitle(trace.locationTitle, for: .normal)
                    
                    if let lastSubview = searchScrollView.subviews.last {
                        let newY = lastSubview.frame.origin.y + lastSubview.frame.size.height
                        button.frame.origin.y = newY
                    }
                    
                    button.addTarget(self, action: #selector(searchResultClicked(_:)), for: .touchUpInside)
                    searchScrollView.addSubview(button)
                }
                
            }
        }
    }
}

extension MapViewController {
    // MARK: content 입력 창 외에 창을 클릭시 키보드 없어지게 도와주는 tap 설정
    @objc func dismissKeyboard(sender: UIGestureRecognizer) {
        searchTextField.resignFirstResponder()
    }
    
    @objc func searchResultClicked(_ sender: UIButton) {
        guard let buttonText = sender.titleLabel?.text else {
            return
        }
        
        for trace in traceGroup.traces {
            if trace.locationTitle == buttonText {
                guard let lon = trace.location["lon"], let lat = trace.location["lat"] else {
                    return
                }
                
                let newCenter = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                let region = MKCoordinateRegion(center: newCenter, span: span)
                mapView.setRegion(region, animated: true)
                selectAnnotationWithCoordinate(latitude: lat!, longitude: lon!)
                break
            }
        }
    }
    
    func selectAnnotationWithCoordinate(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        for annotation in mapView.annotations {
            let coordinate = annotation.coordinate
            if coordinate.latitude == latitude && coordinate.longitude == longitude {
                // 원하는 annotation을 찾았으므로 선택 또는 원하는 동작 수행
                mapView.selectAnnotation(annotation, animated: true)
                break
            }
        }
    }
}
