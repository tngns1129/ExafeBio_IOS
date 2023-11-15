//
//  A_Auth.swift
//  ExafeBio
//
//  Created by ExTrus on 11/15/23.
//

import UIKit
import LocalAuthentication

class ExafeBioAuth{
    private let context = LAContext()   //생체 인증 객체
    private let policy: LAPolicy    //deviceOwnerAuthenticationWithBiometrics 객체
    private let localizedReason: String //생체 인증 팝업창 내용
    private var error: NSError? //에러 발생 타입
    
    static let POPUP_CONTENT = "생체 인증을 수행합니다."  //생체 인증 팝업창 내용
    static let POPUP_FALLBACK = ""  //생체 인증 팝업창 버튼 내용
    static let POPUP_CANCLE = "취소"  //생체 인증 팝업창 버튼 내용
    
    static let ERROR_CHEK_FAIL = "ERROR CHECK FAIL" //에러 체크 실패 멘트 저장
    static let CHECK_SUCCESS = "SUCCESS"    //생체 인증 사용 여부 및 생체 인증 결과 성공 멘트 저장
    
    static let CODE = 0
    static let CODE_SUCCESS = 0
    static let CODE_FAIL = 1
    static let CODE_CANCEL = 2
    static let CODE_LOCKED = 3
    static let CODE_ERROR = 99
    
    // 0 : 성공
    // 1 : 실패
    // 2 : 취소
    // 3 : 잠금
    
    init(policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics,
         localizedReason: String = ExafeBioAuth.POPUP_CONTENT,
         localizedFallbackTitle: String = ExafeBioAuth.POPUP_FALLBACK,
         localizedCancelTitle: String = ExafeBioAuth.POPUP_CANCLE) {
        self.policy = policy
        self.localizedReason = localizedReason
        self.context.localizedFallbackTitle = localizedFallbackTitle
        self.context.localizedCancelTitle = localizedCancelTitle
    }
    
    enum BiometricType{
        case none
        case touchID
        case faceID
        case unknown
    }
    
    @available(iOS 11.0, *)
    private func biometricType(for type: LABiometryType) -> BiometricType {
        switch type {
        case .none:
            return .none
            
        case.touchID:
            return .touchID
            
        case.faceID:
            return .faceID
            
        @unknown default:
            return .unknown
        }
    }
    
    @available(iOS 11.0, *)
    private func biometricError(from nsError: NSError) -> (Int, String, Int) {
        var retry = 0
        var error = ""
        var code = 0
        
        switch nsError {
        case LAError.authenticationFailed:
            retry = 0
            error = "생체인증에 실패하였습니다."
            code = 1
            
        case LAError.userCancel:
            retry = 0
            error = "생체 인증 동작을 취소하였습니다."
            code = 2
            
        case LAError.userFallback:
            retry = 1
            error = "생체 인증 기능이 필요합니다. 재실행하시겟습니까?"
            code = 99
            
        case LAError.biometryNotAvailable:
            retry = 0
            error = "기기에서 생체 인식을 사용할 수 없습니다. 권한을 거부하신 경우 확인해주세요."
            code = 99
            
        case LAError.biometryNotEnrolled:
            retry = 0
            error = "등록된 생체 인식 ID가 없습니다. 생체 인증 등록 후 사용해 주세요."
            if let appSettingsURL = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettingsURL) {
                        UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
                    }
            code = 99
            
        case LAError.biometryLockout:
            retry = 0
            error = "생체 인증 사용 잠금 상태입니다. 디바이스에 등록된 생체 인증을 확인 후 다시 실행해주세요."
            code = 3
            
        case LAError.appCancel:
            retry = 0
            error = "생체 인증 기능 동작이 취소되었습니다. 잠시 후 다시 실행해주세요."
            code = 99
            
        default:
            retry = 0
            error = "생체 인증에서 일시적인 문제가 발생하였습니다."
            code = 99
            
        }
        return (retry, error, code)
    }
    
    @available(iOS 11.0, *)
    func canEvaluate() -> Dictionary<String, Any> {
        let semaphore = DispatchSemaphore(value: 0)     //value 0 값은 대기 상태 선언
        
        var returnDic : Dictionary<String, Any> = [String : Any]()
        var errorData : NSError? = nil
        var errorMsg = ""
        
        guard self.context.canEvaluatePolicy(self.policy, error: &self.error) else{
            let type = self.biometricType(for: self.context.biometryType)
            
            guard let error = self.error
            else{
                //생체 인증 사용 가능 여부 에러 결과 반환
                returnDic["result"] = false
                returnDic["msg"] = ExafeBioAuth.ERROR_CHEK_FAIL
                
                //세마포어 신호 알림
                semaphore.signal()
                
                return returnDic
            }
            errorData = error as NSError
            
            errorMsg = self.biometricError(from: errorData!).1
            
            returnDic["result"] = false
            returnDic["msg"] = errorMsg
            
            semaphore.signal()
            
            return returnDic
        }
        returnDic["result"] = true
        returnDic["msg"] = ExafeBioAuth.CHECK_SUCCESS
        
        semaphore.signal()
        
        semaphore.wait()
        
        return returnDic
    }
    
    @available(iOS 11.0, *)
    func evaluate() {
        
        print("생체 인증 실시")
        
        self.context.evaluatePolicy(self.policy, localizedReason: self.localizedReason){ (success, error) in
            if success == true {
                print("결과 : 생체 인증 성공")
                print("msg : ", ExafeBioAuth.CHECK_SUCCESS)
                
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: "exafeBioAuthNotification"),
                    object: nil,
                    userInfo: ["code" : ExafeBioAuth.CODE_SUCCESS]
                )
                return
            }
            else{
                print("결과 : 에러 발생 확인")
                print("error : ", error?.localizedDescription ?? "")
                print("retry : ", self.biometricError(from: error as! NSError).0)
                print("msg : ", self.biometricError(from: error as! NSError).1)
                
                if self.biometricError(from: error as! NSError).0 == 1 {
                    self.evaluate()
                } else{
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "exafeBioAuthNotification"),
                                                    object: nil,
                                                    userInfo: ["code" : self.biometricError(from: error as! NSError).2 ?? ""]
                    )
                }
                return
            }
            
        }
    }
    
}
