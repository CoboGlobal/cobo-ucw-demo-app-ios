//
//  QRCodeScanner.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/23.
//

import SwiftUI
import AVFoundation

struct QRCodeScanner: UIViewControllerRepresentable {
    @Binding var presentScanner: Bool
    @Binding var scannedCode: String

    func makeUIViewController(context: Context) -> UIViewController {
        let scannerViewController = ScannerViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: QRCodeScanner

        init(_ parent: QRCodeScanner) {
            self.parent = parent
        }

        func codeDidFind(_ code: String) {
            parent.scannedCode = code
            parent.presentScanner = false
        }
    }
}

import CoreImage.CIFilterBuiltins

func generateQRCode(from string: String) -> UIImage {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    let data = Data(string.utf8)
    filter.setValue(data, forKey: "inputMessage")
    
    if let outputImage = filter.outputImage {
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
    }
    
    return UIImage(systemName: "xmark.circle") ?? UIImage()
}

