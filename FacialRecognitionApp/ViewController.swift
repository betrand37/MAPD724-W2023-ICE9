//
//  ViewController.swift
//  FacialRecognitionApp
//
//  Created by Kobbie on 02/04/2023.
//

import Vision
import Photos
import UIKit
import PhotosUI
import AVKit

class ViewController:  UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{



    @IBOutlet var messageLabel: UILabel!
    
    @IBOutlet var pictureChosen: UIImageView!
    
    @IBAction func getImage(_ sender: UIButton) {
        getPhoto()
    }
    
    private var selectedAssetIdentifiers = [String]()
    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func getPhoto() {
     let picker = UIImagePickerController()
     picker.delegate = self
     picker.sourceType = .savedPhotosAlbum
     present(picker, animated: true, completion: nil)
     }
    
    func analyzeImage()
    {
        
        
        let pictureChose=CIImage(image: pictureChosen.image!)!
        let accuracy=[CIDetectorAccuracy:CIDetectorAccuracyHigh]
        let faceDetector=CIDetector(ofType: CIDetectorTypeFace, context: nil,options: accuracy)
        let faces = VNDetectFaceRectanglesRequest()
        let request = VNDetectFaceRectanglesRequest { (req,err)
            in
            if let err = err {
                print("detect failed",err)
                return
            }
            print(req)
            
        }
#if targetEnvironment(simulator)

request.usesCPUOnly = true
        faces.usesCPUOnly=true
        

#endif
        guard let cgImage = pictureChose.cgImage else {return}
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [ : ])
        do{
            try handler.perform([request])
            guard let foundFaces = request.results else {
                    fatalError ("Can't find a face in the picture")
                }
            messageLabel.text = "Found \(foundFaces.count) faces in the picture"
            request.results?.forEach({(res) in
                guard let faceObservation = res as?
                    VNFaceObservation else {return}
                
               
                var landmarkRegions: [VNFaceLandmarkRegion2D] = []
                
                drawImage(source: pictureChosen.image!,
                          boundary: faceObservation.boundingBox, faceLandmarkRegions: landmarkRegions)
            })
        }catch let reqErr {
            print("failed",reqErr)
        }
    }
    
   func imagePickerController(_ picker: UIImagePickerController,
     didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
     {
         
     if let image =
            info[UIImagePickerController.InfoKey.originalImage] as? UIImage
     {
         pictureChosen.image=image
         
         analyzeImage()
         
     }
         self.dismiss(animated: true,completion: nil)
         print("self")
     }



//    func identifyFacesWithLandmarks(image: UIImage)
//    {
//        let pictureChose=CIImage(image: pictureChosen.image!)!
//        guard let cgImage = pictureChose.cgImage else {return}
//     let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [ : ])
//     let request =
//     VNDetectFaceLandmarksRequest(completionHandler: handleFaceLandmarksRecognition)
//        do{
//            try handler.perform([request])
//        }catch{
//            print("error")
//        }
//    }


//    func handleFaceLandmarksRecognition(request: VNRequest, error: Error?)
//    {
//        request.results?.forEach({(res) in
//            guard let faceObservation = res as?
//                VNFaceObservation else {return}
//            let landmarkRegions: [VNFaceLandmarkRegion2D] = []
//            drawImage(source: pictureChosen.image!,
//                      boundary: faceObservation.boundingBox, faceLandmarkRegions: landmarkRegions)
//        })
//    }
 
    func drawImage(source: UIImage, boundary: CGRect,
     faceLandmarkRegions:[VNFaceLandmarkRegion2D])
    {
     UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
     let context = UIGraphicsGetCurrentContext()!
     context.translateBy(x: 0, y: source.size.height)
     context.scaleBy(x: 1.0, y: -1.0)
     context.setLineJoin(.round)
     context.setLineCap(.round)
     context.setShouldAntialias(true)
     context.setAllowsAntialiasing(true)
     let rect = CGRect(x: 0, y:0, width: source.size.width,
      height: source.size.height)
     context.draw(source.cgImage!, in: rect)

     //draw rectangles around faces
     var fillColor = UIColor.systemGreen
     fillColor.setStroke()
     context.setLineWidth(10.0)
     let rectangleWidth = source.size.width * boundary.size.width
     let rectangleHeight = source.size.height * boundary.size.height
     context.addRect(CGRect(
      x: boundary.origin.x * source.size.width,
      y:boundary.origin.y * source.size.height,
      width: rectangleWidth,
      height: rectangleHeight))
     context.drawPath(using: CGPathDrawingMode.stroke)

     //draw facial features
     fillColor = UIColor.systemRed
     fillColor.setStroke()
     context.setLineWidth(5.0)
     for faceLandmarkRegion in faceLandmarkRegions
     {
      var points: [CGPoint] = []
      for i in 0..<faceLandmarkRegion.pointCount
      {
       let point = faceLandmarkRegion.normalizedPoints[i]
       let p = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
       points.append(p)
      }
      let facialPoints = points.map { CGPoint(
       x: boundary.origin.x * source.size.width + $0.x * rectangleWidth,
       y: boundary.origin.y * source.size.height + $0.y * rectangleHeight) }
      context.addLines(between: facialPoints)
      context.drawPath(using: CGPathDrawingMode.stroke)
     }

     let modifiedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
     UIGraphicsEndImageContext()
     pictureChosen.image = modifiedImage
    }
    
}

