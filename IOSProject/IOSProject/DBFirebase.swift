//
//  DBFirebase.swift
//  IOSProject
//
//  Created by MacBookAir69 on 2023/06/16.
//

import Foundation
import FirebaseFirestore
class DbFirebase: Database {
    
    var reference: CollectionReference                    // firestore에서 데이터베이스 위치
    var parentNotification: ((Trace?, DbAction?) -> Void)? // PlanGroupViewController에서 설정
    var existQuery: ListenerRegistration?                 // 이미 설정한 Query의 존재여부

    required init(parentNotification: ((Trace?, DbAction?) -> Void)?, email: String) {
        self.parentNotification = parentNotification
        reference = Firestore.firestore().collection(email) // 첫번째 "plans"라는 Collection
    }
}
extension DbFirebase{
    
    func saveChange(trace: Trace, action: DbAction){
        if action == .Delete{
            reference.document(trace.locationAddress).delete()    // key로된 plan을 지운다
            return
        }

        // dict 형식으로 변환해서 저장
        let data  = trace.toDict()

        // 저장 형태로 만든다
        let storeDate: [String : Any] = ["date": trace.date, "data": data]
        reference.document(trace.locationAddress).setData(storeDate)
    }
}
extension DbFirebase{
    
    func queryPlan() {
        
        if let existQuery = existQuery{    // 이미 적용 쿼리가 있으면 제거, 중복 방지
            existQuery.remove()
        }
        // where plan.date >= fromDate and plan.date <= toDate
        let queryReference = reference
        
        // onChangingData는 쿼리를 만족하는 데이터가 있거나 firestore내에서 다른 앱에 의하여
        // 데이터가 변경되어 쿼리를 만족하는 데이터가 발생하면 호출해 달라는 것이다.
        existQuery = queryReference.addSnapshotListener(onChangingData)
    }
}

extension DbFirebase{
    func onChangingData(querySnapshot: QuerySnapshot?, error: Error?){
        guard let querySnapshot = querySnapshot else{ return }
        // 초기 데이터가 하나도 없는 경우에 count가 0이다
        if(querySnapshot.documentChanges.count <= 0){
            if let parentNotification = parentNotification { parentNotification(nil, nil)} // 부모에게 알림
        }
        // 쿼리를 만족하는 데이터가 많은 경우 한꺼번에 여러 데이터가 온다
        for documentChange in querySnapshot.documentChanges {
            let data = documentChange.document.data()
            
            let trace = Trace()
            trace.toTrace(dict: data["data"] as! [String:Any?])
            var action: DbAction?
            switch(documentChange.type){    // 단순히 DbAction으로 설정
                case    .added: action = .Add
                case    .modified: action = .Modify
                case    .removed: action = .Delete
            }
            if let parentNotification = parentNotification {parentNotification(trace, action)} // 부모에게 알림
        }
    }
}
