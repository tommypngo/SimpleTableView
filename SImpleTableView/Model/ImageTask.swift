//
//  ImageTask.swift
//  SImpleTableView
//
//  Created by Tommy Ngo on 2/26/20.
//  Copyright © 2020 Ngo. All rights reserved.
//

import UIKit

protocol ImageTaskDownloadedDelegate {
    func imageDownloaded(position: Int)
}

class ImageTask {
    let position: Int
    let url: URL
    let session: URLSession
    let delegate: ImageTaskDownloadedDelegate?

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

    func resume() {
        if !isDownloading && !isFinishedDownloading {
            isDownloading = true

            if let resumeData = resumeData {
                task = session.downloadTask(withResumeData: resumeData, completionHandler: downloadTaskCompletionHandler)
            } else {
                task = session.downloadTask(with: url, completionHandler: downloadTaskCompletionHandler)
            }

            task?.resume()
        }
    }

    func pause() {
        if isDownloading && !isFinishedDownloading {
            task?.cancel(byProducingResumeData: { (data) in
                self.resumeData = data
            })

            self.isDownloading = false
        }
    }

    private func downloadTaskCompletionHandler(url: URL?, response: URLResponse?, error: Error?) {
        defer {
            DispatchQueue.main.async {
                self.delegate?.imageDownloaded(position: self.position)
            }
            self.isFinishedDownloading = true
        }

        guard error == nil,
              let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let url = url,
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

