//
//  PhotoCaptureDelegate.swift
//  sane3D Demo
//
//  Created by Evgeny Petrov on 18.08.20.
//  Copyright © 2020 Evgeny Petrov. All rights reserved.
//

import AVFoundation
import Photos

class PhotoCaptureDelegate: NSObject {
    var uploadClient: YandeDiskClient?
}

extension PhotoCaptureDelegate: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto: AVCapturePhoto, error: Error?)
    {
        print("Did receive \(didFinishProcessingPhoto.photoCount) photo")
        let data = didFinishProcessingPhoto.fileDataRepresentation()
        if (data != nil) {
            print("Data length \(data!.count)")
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.current;
            formatter.dateFormat = "yyyyMMdd'_'HHmmss"
            let date = Date()
            let fileName = formatter.string(from:date) + ".jpeg"
            
            print("Image file name: \(fileName)")
            uploadClient!.upladPhoto(imageName: fileName, photoData: data!)
        }
        
    }
}
