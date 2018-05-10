//
//  ViewController.swift
//  http-retry-ios
//
//  Created by Amrzs on 5/10/18.
//  Copyright © 2018 Amrzs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func sendBtnClicked(_ sender: Any) {
        let url = URL(string: "https://jsonplaceholder.typicode.com/11users")
        let request = URLRequest(url: url!)
        
        callWithRetry(request: request, retry: 1)
    }
    
    enum ApiRequestError: Error {
        case statusCodeOtherThan200(statusCode: Int)
    }
    
    enum ApiResponse {
        case success(Data)
        case failure(Error)
    }
    
    func delay(_ delayInSecond: Double, closure: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delayInSecond * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
            execute: closure
        )
    }
    
    func callWithRetry(request: URLRequest, retry: Int64) {
        callServerApi(request: request) {
            apiResponse in
            switch apiResponse {
            case .success(let data):
                print("JSON response:")
                if let jsonResponse = String(data: data, encoding: String.Encoding.utf8) {
                    print("\(jsonResponse)")
                }
            case .failure(let error):
                print("Failure! \(error)")
                if (retry > 0) {
                    self.delay(2) {
                        self.callWithRetry(request: request, retry: retry - 1)
                    }
                }
            }
        }
    }
    
    func callServerApi(request: URLRequest, completion: @escaping (ApiResponse) -> ()) {
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            
            if let error = error {
                print(error)
                completion(.failure(error))
            } else {
                if let data = data, let response = response as? HTTPURLResponse {
                    print(response, data)
                    if (response.statusCode == 200) {
                        completion(.success(data))
                    } else {
                        completion(.failure(ApiRequestError.statusCodeOtherThan200(statusCode: response.statusCode)))
                    }
                }
            }
        }
        task.resume()
    }
}
