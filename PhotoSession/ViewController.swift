//
//  ViewController.swift
//  sane3D Demo
//
//  Created by Evgeny Petrov on 15.08.20.
//  Copyright © 2020 Evgeny Petrov. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var projectNameButton: UIButton!
    @IBOutlet private weak var previewView: PreviewView!
    
    var currentProject: String?

    var imagePicker: UIImagePickerController!
    
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private let photoOutput = AVCapturePhotoOutput()
    private let photoCaptureDelegate = PhotoCaptureDelegate()
    private var backendClient: YandeDiskClient?
    
    @IBAction func takePhoto(_ sender: Any) {
        let outputSettings = AVCapturePhotoSettings(
            format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        print("Taking photo")
        photoOutput.capturePhoto(with: outputSettings, delegate: photoCaptureDelegate)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        previewView.session = session
        // Check camera access
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
           // The user has previously granted access to the camera.
           break
           
        case .notDetermined:
           
           AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in })
           
        default:
           // The user has previously denied access.
           break
        }
        
        // Configure Session
        sessionQueue.async {
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video,
                                                      position: .back) else {return}
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                self.session.addInput(videoInput)
                
            } catch {
                print("Error creationg video input")
            }
            
            self.session.addOutput(self.photoOutput)
            
            self.session.commitConfiguration()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        createBackend()
    }
    
    func createBackend(){
        let envPassword = ProcessInfo.processInfo.environment["DISK_API_TOKEN"]
        if envPassword != nil {
            backendClient = YandeDiskClient(token: envPassword!)
        }
        let alertController = UIAlertController(
            title: "Password",
            message: "Please provide Yandex.Disk token",
            preferredStyle: .alert)
        alertController.addTextField {
            (textField: UITextField) -> Void in
            textField.placeholder = "Enter project name"
        }
        let OKAction = UIAlertAction(title: "OK", style: .default) {
            alert -> Void in
            let textField = alertController.textFields![0] as UITextField
            let token = textField.text!
            self.backendClient = YandeDiskClient(token: token)
            self.photoCaptureDelegate.uploadClient = self.backendClient

        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }

    
    override func viewWillAppear(_ animated: Bool) {
        sessionQueue.async {
            self.session.startRunning()
        }
    }

    @IBAction func setProjectName(_ sender: Any) {
        let alertController = UIAlertController(title: "New project", message: "", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
               textField.placeholder = "Enter project name"
           }
        let OKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let firstTextField = alertController.textFields![0] as UITextField
            self.projectNameButton.setTitle(firstTextField.text, for:.normal)
            self.currentProject = firstTextField.text
            self.backendClient!.createProject(projectName: self.currentProject!)
        })
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style:UIAlertAction.Style.cancel,
                                         handler: {alert -> Void in})
        alertController.addAction(OKAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)

    }
    
}

