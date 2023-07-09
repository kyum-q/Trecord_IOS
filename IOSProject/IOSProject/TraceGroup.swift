//
//  TraceGroup.swift
//  IOSProject
//
//  Created by MacBookAir69 on 2023/06/16.
//

import Foundation

class TraceGroup: NSObject{
    var traces = [Trace]()            // var traces: [Trace] = []와 동일, 퀴리를 만족하는 trace들만 저장한다.
    var fromDate, toDate: Date?     // queryPlan 함수에서 주어진다.
    var database: Database!
    var parentNotification: ((Trace?, DbAction?) -> Void)?
    var email : String!
    
    init(parentNotification: ((Trace?, DbAction?) -> Void)?, email: String){
        super.init()
        self.parentNotification = parentNotification

        database = DbFirebase(parentNotification: receivingNotification, email: email) // 데이터베이스 생성
    }

    func receivingNotification(trace: Trace?, action: DbAction?){
        // 데이터베이스로부터 메시지를 받고 이를 부모에게 전달한다
        if let trace = trace{
            switch(action){    // 액션에 따라 적절히     plans에 적용한다
                case .Add: addTrace(trace: trace)
                case .Modify: modifyTrace(modifiedTrace: trace)
                case .Delete: removeTrace(removedTrace: trace)
                default: break
            }
        }
        if let parentNotification = parentNotification{
            parentNotification(trace, action) // 역시 부모에게 알림내용을 전달한다.
        }
    }
}

extension TraceGroup{
    
    func queryData(date: Date){
        traces.removeAll()    // 새로운 쿼리에 맞는 데이터를 채우기 위해 기존 데이터를 전부 지운다
        database.queryPlan()
    }
    
    func saveChange(trace: Trace, action: DbAction){
        // 단순히 데이터베이스에 변경요청을 하고 plans에 대해서는
        // 데이터베이스가 변경알림을 호출하는 receivingNotification에서 적용한다
        database.saveChange(trace: trace, action: action)
    }
}

extension TraceGroup{
    
    private func count() -> Int{ return traces.count }
    
    func isIn(date: Date) -> Bool{
        if let from = fromDate, let to = toDate{
            return (date >= from && date <= to) ? true: false
        }
        return false
    }
    
    private func find(_ address: String) -> Int?{
        for i in 0..<traces.count{
            if address == traces[i].locationAddress {
                return i
            }
        }
        return nil
    }
    
    func findTrace(_ location: [String: Double?]) -> Trace?{
        for trace in traces {
            if location["lon"] == trace.location["lon"], location["lat"] == trace.location["lat"] {
                return trace
            }
        }
        return nil
    }
    
    func findEqualsColorTraces(_ colorIndex: Int) -> [Trace] {
        var newTraces = [Trace]()
        for trace in traces  {
            if trace.colorIndex == colorIndex {
                newTraces.append(trace)
            }
        }
        return newTraces
    }
    
    func searchTraceGroup(_ address: String) -> Trace? {
        for trace in traces {
            if trace.locationAddress == address {
                return trace
            }
        }
        return nil
    }
}

extension TraceGroup{
    private func addTrace(trace:Trace){ traces.append(trace) }
    private func modifyTrace(modifiedTrace: Trace){
        if let index = find(modifiedTrace.locationAddress){
            traces[index] = modifiedTrace
        }
    }
    private func removeTrace(removedTrace: Trace){
        if let index = find(removedTrace.locationAddress){
            traces.remove(at: index)
        }
    }
    func changeTrace(from: Trace, to: Trace){
        if let fromIndex = find(from.locationAddress), let toIndex = find(to.key) {
            traces[fromIndex] = to
            traces[toIndex] = from
        }
    }
}

