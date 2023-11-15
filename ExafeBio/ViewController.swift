//
//  ViewController.swift
//  ExafeBio
//
//  Created by ExTrus on 11/15/23.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {

    var userModel = UserModel()
    @IBOutlet weak var id: UITextField!
    @IBOutlet weak var pw: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //id.becomeFirstResponder()
        //pw.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(exafeBioAuthNotification(_:)),
            name: NSNotification.Name("exafeBioAuthNotification"),
            object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("exafeBioAuthNotification"),
            object: nil
        )
    }
    
    @objc func didEndOnExit(_ sender: UITextField) {
            if id.isFirstResponder {
                pw.becomeFirstResponder()
            }
        }
    
    @IBAction func btn(_ sender: UIButton) {
        
        let exafeBioAuth = ExafeBioAuth()
        if #available(iOS 11.0, *){
            let canEvaluateDic : Dictionary<String, Any> = exafeBioAuth.canEvaluate()
            if (canEvaluateDic["result"] != nil) == true {
                // [생체 인증 수행 실시]
                exafeBioAuth.evaluate()
            } else{ //생체인증 불가능한 경우
                
            }
        }
        
        //키보드 강제 내림
        DispatchQueue.main.async {
            self.view.endEditing(true)
        }
    }
    
    @objc func exafeBioAuthNotification(_ notification:NSNotification) {
        print("생체 인증 결과")
        switch(notification.userInfo?["code"]) as! Int{
        case ExafeBioAuth.CODE_SUCCESS:
            //인증 성공시
            print("SUCCESS")
            DispatchQueue.main.async {
                if let mainView = self.storyboard?.instantiateViewController(identifier: "mainViewController") as? MainViewController {
                    self.present(mainView, animated: true, completion: nil)
                }
            }

        case ExafeBioAuth.CODE_FAIL:
            //인증 실패시
            print("FAIL")
            
        case ExafeBioAuth.CODE_CANCEL:
            //인증 취소
            print("CANCEL")
        
        case ExafeBioAuth.CODE_LOCKED:
            //인증 잠금 총 5번 실패하면 잠금됨
            print("LOCKED")
            
        case ExafeBioAuth.CODE_ERROR:
            //인증 에러
            print("message : \(notification.userInfo!["code"]!)")
            
        default:
            break
        }
        
        
        
        
    }
}

