//
//  AssetResourceLoaderDelegate.swift
//  newdv
//
//  Created by 김효정 on 28/07/2019.
//  Copyright © 2019 김효정. All rights reserved.
//

import AVFoundation
import MobileCoreServices

class AssetResourceLoaderDelegate: NSObject {
    
    let originalUrl: URL

    var pendingRequest: AVAssetResourceLoadingRequest?
    var dataTask: URLSessionDataTask?
    lazy var session = {
        return URLSession(configuration: URLSessionConfiguration.default,
                          delegate: self,
                          delegateQueue: OperationQueue.main)
    }()

    init(url: URL) {
        originalUrl = url
        super.init()
    }
    
    func urlForLoadingRequest(loadingRequest: AVAssetResourceLoadingRequest) -> URL {
        guard let interceptedURL = loadingRequest.request.url else {
            fatalError("dont have url!!")
        }
        return fixedURLFromURL(url: interceptedURL)
    }
    
    func fixedURLFromURL(url: URL) -> URL {
        var actualUrlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        actualUrlComponents?.scheme = originalUrl.scheme
        guard let actualUrl = actualUrlComponents?.url else {
            fatalError("can not make url")
        }
        return actualUrl
    }
    
    func fillInContentInformation(contentInformationRequest: AVAssetResourceLoadingContentInformationRequest,
                                  response: URLResponse) {
        guard
            let mimeType = response.mimeType else {
                return
        }
        let unmanagedMimeUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)
        let mimeUTI = unmanagedMimeUTI?.takeRetainedValue()
        contentInformationRequest.contentType = CFBridgingRetain(mimeUTI) as? String
        print("type is :")
        print(mimeType)
        
        guard let httpResponse = response as? HTTPURLResponse
            else {
                print("can not convert to httpurlresponse")
                return
        }
        if let acceptRange = httpResponse.allHeaderFields["Accept-Ranges"] as? String {
            contentInformationRequest.isByteRangeAccessSupported = acceptRange == "bytes"
        }
        if let contentRange = httpResponse.allHeaderFields["Content-Range"] as? String,
            let contentLengthString = contentRange.components(separatedBy: "/").last,
            let contentLength = Int64(contentLengthString) {
            contentInformationRequest.contentLength = contentLength
        } else {
            contentInformationRequest.contentLength = response.expectedContentLength
        }
        print(contentInformationRequest)
    }
}

extension AssetResourceLoaderDelegate: AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        let actualUrl = urlForLoadingRequest(loadingRequest: loadingRequest)
        var request = URLRequest(url: actualUrl)
        if loadingRequest.contentInformationRequest != nil {
            request.allHTTPHeaderFields = ["Range": "bytes=0-1"]
        } else if loadingRequest.dataRequest?.requestsAllDataToEndOfResource == true,
            let requestedOffset = loadingRequest.dataRequest?.requestedOffset {
            request.allHTTPHeaderFields = ["Range" : "bytes=\(requestedOffset)-"]
        }
        else if let dataRequest = loadingRequest.dataRequest {
            let requestedOffset = Int(dataRequest.requestedOffset)
            let requestedLength = dataRequest.requestedLength
            request.allHTTPHeaderFields = ["Range" : "bytes=\(requestedOffset)-\(requestedOffset + requestedLength - 1)"]
        } else {
            return false
        }
        request.cachePolicy = .useProtocolCachePolicy
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
        pendingRequest = loadingRequest
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        dataTask?.cancel()
    }
}

extension AssetResourceLoaderDelegate: URLSessionDelegate, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        pendingRequest?.response = response
        if let contentInformationRequest = pendingRequest?.contentInformationRequest {
            fillInContentInformation(contentInformationRequest: contentInformationRequest, response: response)
            pendingRequest?.finishLoading()
            self.dataTask?.cancel()
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        pendingRequest?.dataRequest?.respond(with: data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        pendingRequest?.finishLoading(with: error)
    }
}
