//
//  ViewController.swift
//  classificazione campioni   7.2
//
//  Created by Filippo Mattia Menghi on 06/04/24.
//
import UIKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary // Can be changed to .camera to take photos
        return picker
    }()
    
    // Create a VNCoreMLModel from your Core ML model
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // Make sure 'MyImageClassifier' is the correct name of your Core ML model class
            let model = try VNCoreMLModel(for: MyImageClassifier(configuration: MLModelConfiguration()).model)
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load ML model: \(error)")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resultLabel.text = "Choose an image to start"
    }
    
    @IBAction func pickImage(_ sender: UIButton) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        imageView.image = selectedImage
        classifyImage(selectedImage)
    }
    
    func classifyImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else { fatalError("Could not convert UIImage to CIImage") }
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .up)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification: \(error.localizedDescription)")
            }
        }
    }
    
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.resultLabel.text = "Unable to classify image.\n\(error?.localizedDescription ?? "")"
                return
            }
            let classifications = results as! [VNClassificationObservation]
            if !classifications.isEmpty {
                // Display top classification.
                let topClassification = classifications.first!
                self.resultLabel.text = "Class: \(topClassification.identifier)\nConfidence: \(topClassification.confidence * 100.0)%"
            } else {
                self.resultLabel.text = "Nothing recognized."
            }
        }
    }
}
