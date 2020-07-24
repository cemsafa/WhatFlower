//
//  ViewController.swift
//  WhatFlower
//
//  Created by Cem Safa on 24.07.2020.
//  Copyright © 2020 Cem Safa. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let imagePicker = UIImagePickerController()
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
    }

    @IBAction func cameraBtnTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else { fatalError("Cannot import model") }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else { fatalError("Cannot classify image") }
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func requestInfo(flowerName: String) {
        let parameters: [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        AF.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            switch response.result {
            case .success(let json):
                let flowerJSON: JSON = JSON(json)
                let pageId = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageId]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.label.text = flowerDescription
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else { fatalError("Cannot convert to CIImage") }
            detect(image: ciImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
}
