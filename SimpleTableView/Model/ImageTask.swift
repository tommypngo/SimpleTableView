//
//  ImageTask.swift
//  SimpleTableView
//
//  Created by Tommy Ngo on 2/26/20.
//  Copyright © 2020 Ngo. All rights reserved.
//

import UIKit

protocol ImageTaskDownloadedDelegate: AnyObject {
    func imageTaskDidFinishDownloading(position: Int)
}

class ImageTask {
    let position: Int
    let url: URL
    let session: URLSession
    weak var delegate: ImageTaskDownloadedDelegate?

    var image: UIImage?

    private var task: URLSessionDownloadTask?
    private var resumeData: Data?

    private var isDownloading = false
    private var isFinishedDownloading = false

    init(position: Int, url: URL, session: URLSession, delegate: ImageTaskDownloadedDelegate?) {
        self.position = position
        self.url = url
        self.session = session
        self.delegate = delegate
    }

    /// resume a download session
    /// we will if we paused it before
    func resume() {
        guard !isDownloading && !isFinishedDownloading else {
            return
        }
        
        isDownloading = true
        
        if let resumeData = resumeData {
            task = session.downloadTask(withResumeData: resumeData, completionHandler: downloadTaskCompletionHandler)
        } else {
            task = session.downloadTask(with: url, completionHandler: downloadTaskCompletionHandler)
        }
        
        task?.resume()
    }

    /// pause a download session
    /// and come back to it later
    func pause() {
        guard isDownloading && !isFinishedDownloading else {
            return
        }
        
        task?.cancel(byProducingResumeData: { [weak self] data in
            self?.resumeData = data
        })
        
        isDownloading = false
    }

    /// Handle when a download just done
    /// we also check status to make sure it was not a bad url.
    private func downloadTaskCompletionHandler(url: URL?, response: URLResponse?, error: Error?) {

        defer {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.imageTaskDidFinishDownloading(position: self?.position ?? -1)
            }
            isFinishedDownloading = true
        }

        guard error == nil,
              let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let url,
              let data = FileManager.default.contents(atPath: url.path),
              let image = UIImage(data: data)
        else {
            print("Error downloading: ", error?.localizedDescription ?? "image not exist")
            self.image = #imageLiteral(resourceName: "FailImage")
            return
        }
        self.image = image
    }
}

