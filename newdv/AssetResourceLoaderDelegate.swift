//
//  AssetResourceLoaderDelegate.swift
//  newdv
//
//  Created by 김효정 on 28/07/2019.
//  Copyright © 2019 김효정. All rights reserved.
//

import AVFoundation
import MobileCoreServices

struct Operation: Hashable {
    
    let dataTask: URLSessionDataTask
    let loadingRequest: AVAssetResourceLoadingRequest
    
    init(dataTask: URLSessionDataTask, loadingRequest: AVAssetResourceLoadingRequest) {
        self.dataTask = dataTask
        self.loadingRequest = loadingRequest
    }
    
    func fillLoadingRequest(with response: URLResponse) {
        guard
            let contentInformationRequest = loadingRequest.contentInformationRequest,
            let response = response as? HTTPURLResponse,
            let mimeType = response.mimeType else {
                return
        }
        let unmanagedMimeUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)
        let mimeUTI = unmanagedMimeUTI?.takeRetainedValue()
        contentInformationRequest.contentType = CFBridgingRetain(mimeUTI) as? String

        if let acceptRange = response.allHeaderFields["Accept-Ranges"] as? String {
            contentInformationRequest.isByteRangeAccessSupported = acceptRange == "bytes"
        }
        
        if let contentRange = response.allHeaderFields["Content-Range"] as? String,
            let contentLengthString = contentRange.components(separatedBy: "/").last,
            let contentLength = Int64(contentLengthString) {
            contentInformationRequest.contentLength = contentLength
        } else {
            contentInformationRequest.contentLength = response.expectedContentLength
        }
    }
}

extension URL {
    
    func replaceScheme(to scheme: String) -> URL {
        guard
            var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
            else {
                print("can not replace")
                return self
        }
        components.scheme = scheme
        if let url = components.url { return url }
        return self
    }
}

class AssetResourceLoaderDelegate: NSObject {
    
    let originalUrl: URL
    var operations = Set<Operation>()
    lazy var session = {
        return URLSession(configuration: URLSessionConfiguration.default,
                          delegate: self,
                          delegateQueue: OperationQueue.main)
    }()

    init(url: URL) {
        originalUrl = url
        super.init()
    }
    
    func searchedOperation(with dataTask: URLSessionDataTask) -> Operation {
        let searchedOperation = operations.first{ (operation) -> Bool in
            return operation.dataTask == dataTask
        }
        guard let operation = searchedOperation else {
            fatalError("can not search operation with dataTask")
        }
        return operation
    }

    func searchedOperation(with loadingRequest: AVAssetResourceLoadingRequest) -> Operation {
        let searchedOperation = operations.first{ (operation) -> Bool in
            return operation.loadingRequest == loadingRequest
        }
        guard let operation = searchedOperation else {
            fatalError("can not search operation with loadingRequest")
        }
        return operation
    }
    
    func rangeHeaderField(with loadingRequest: AVAssetResourceLoadingRequest) -> String? {
        if loadingRequest.contentInformationRequest != nil {
            return "bytes=0-1"
        } else if loadingRequest.dataRequest?.requestsAllDataToEndOfResource == true,
            let requestedOffset = loadingRequest.dataRequest?.requestedOffset {
            return "bytes=\(requestedOffset)-"
        }
        else if let dataRequest = loadingRequest.dataRequest {
            let requestedOffset = Int(dataRequest.requestedOffset)
            let requestedLength = dataRequest.requestedLength
            return "bytes=\(requestedOffset)-\(requestedOffset + requestedLength - 1)"
        }
        return nil
    }
    
    func request(with loadingRequest: AVAssetResourceLoadingRequest) -> URLRequest {
        guard
            let url = loadingRequest.request.url,
            let originalUrlScheme = originalUrl.scheme
            else {
                fatalError("can not redirect!!")
        }
        let actualUrl = url.replaceScheme(to: originalUrlScheme)
        var request = URLRequest(url: actualUrl)
        let rangeHeaderValue = rangeHeaderField(with: loadingRequest)
        request.setValue(rangeHeaderValue, forHTTPHeaderField: "Range")
        request.cachePolicy = .useProtocolCachePolicy
        return request
    }
}

extension AssetResourceLoaderDelegate: AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        let dataRequest = request(with: loadingRequest)
        let dataTask = session.dataTask(with: dataRequest)
        let operation = Operation(dataTask: dataTask, loadingRequest: loadingRequest)
        operations.insert(operation)
        dataTask.resume()
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        let operation = searchedOperation(with: loadingRequest)
        operation.dataTask.cancel()
        operations.remove(operation)
    }
}

extension AssetResourceLoaderDelegate: URLSessionDelegate, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let operation = searchedOperation(with: dataTask)
        operation.loadingRequest.response = response
        operation.fillLoadingRequest(with: response)
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let operation = searchedOperation(with: dataTask)
        operation.loadingRequest.dataRequest?.respond(with: data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard
            let dataTask = task as? URLSessionDataTask
            else {
            fatalError("can not convert task to data task")
        }
        let operation = searchedOperation(with: dataTask)
        if let error = error {
            operation.loadingRequest.finishLoading(with: error)
        } else {
            operation.loadingRequest.finishLoading()
        }
        operations.remove(operation)
    }
}
