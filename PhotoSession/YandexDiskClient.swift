//
//  YandexDiskClient.swift
//  sane3D Demo
//
//  Created by Evgeny Petrov on 19.08.20.
//  Copyright © 2020 Evgeny Petrov. All rights reserved.
//

import Foundation

struct Link: Decodable {
    var href: String
    var method: String
    var templated: Bool
}


class YandeDiskClient {
    let startUrl = "https://cloud-api.yandex.net:443/v1/disk"
    var headers = [
        "Content-Type": "application/json",
    ]
    var currentProject: String?
    
    init(token: String) {
        headers["Authorization"] = "OAuth " + token
    }
    
    private func makeRequest(
        urlString: String) -> URLRequest?
    {
        guard let url = URL(string: urlString) else {
            print("Can not create url from: `\(urlString)`")
            return nil
        }
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }
    
    func createProject(projectName: String)
    {
        guard let encodedProjectName = projectName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        else {
            print("Can not encode project name \(projectName)")
            return
        }
        guard var request = makeRequest(urlString: startUrl + "/resources?path=app:/\(encodedProjectName)") else {
            print("Can not create request")
            return
        }
        request.httpMethod = "PUT"
        let session = URLSession.shared
        let task = session.dataTask(with: request) {
            (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse,
                [201, 409].contains(httpResponse.statusCode)
            {
                print("Project created: \(httpResponse.statusCode)")
            } else {
                print("Project creation failded")
            }
        }
        task.resume()
        
        currentProject = projectName
    }
    
    func upladPhoto(imageName: String, photoData: Data) {
        // Get upload URL
        guard let currentProject = self.currentProject else {return}
        guard let encodedProjectName = currentProject.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return}
        guard let encodedImageName = imageName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return}
        let remoteFilePath = "app:/\(encodedProjectName)/\(encodedImageName)"
        guard let request = makeRequest(
            urlString: startUrl + "/resources/upload?path=\(remoteFilePath)") else {
                print("Can not create request")
                return
        }
        let session = URLSession.shared
        let task = session.dataTask(with: request) {
            (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse,
                [200].contains(httpResponse.statusCode)
            {
                let link = try! JSONDecoder().decode(Link.self, from: data!)

                print("Upload url creation: \(httpResponse.statusCode)")
                print("Upload url: \(link.href)")
                
                // Actual uploading
                guard var request = self.makeRequest(urlString: link.href) else {
                    print("Can not create request for \(link.href)")
                    return
                }
                request.httpMethod = "PUT"
                request.httpBody = photoData
                let uploadTask = session.dataTask(with: request) {
                    (data, response, error) in
                    if let uploadResponse = response as? HTTPURLResponse,
                        [201].contains(uploadResponse.statusCode)
                    {
                        print("Upload complete")
                    } else {
                        print("Failed to upload \(response!) \(data!)")
                    }
                }
                uploadTask.resume()
                
            } else {
                print("Project creation failded")
            }
        }
        task.resume()

    }
}
