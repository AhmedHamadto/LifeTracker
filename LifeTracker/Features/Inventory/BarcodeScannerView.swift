import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let controller = BarcodeScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BarcodeScannerDelegate {
        let parent: BarcodeScannerView

        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }

        func didScanBarcode(_ code: String) {
            parent.scannedCode = code
            parent.dismiss()
        }

        func didFailWithError(_ error: Error) {
            print("Barcode scan error: \(error)")
            parent.dismiss()
        }
    }
}

protocol BarcodeScannerDelegate: AnyObject {
    func didScanBarcode(_ code: String)
    func didFailWithError(_ error: Error)
}

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: BarcodeScannerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasScanned = false

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.didFailWithError(ScannerError.noCameraAvailable)
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)

            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                delegate?.didFailWithError(ScannerError.inputFailed)
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [
                    .ean8, .ean13, .pdf417, .qr, .code128, .code39, .code93,
                    .upce, .aztec, .dataMatrix, .interleaved2of5, .itf14
                ]
            } else {
                delegate?.didFailWithError(ScannerError.outputFailed)
                return
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            self.previewLayer = previewLayer
            self.captureSession = session

        } catch {
            delegate?.didFailWithError(error)
        }
    }

    private func setupOverlay() {
        // Semi-transparent overlay
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(overlayView)

        // Clear scanning area
        let scanAreaSize: CGFloat = min(view.bounds.width, view.bounds.height) * 0.7
        let scanArea = CGRect(
            x: (view.bounds.width - scanAreaSize) / 2,
            y: (view.bounds.height - scanAreaSize) / 2,
            width: scanAreaSize,
            height: scanAreaSize
        )

        let path = UIBezierPath(rect: view.bounds)
        let scanPath = UIBezierPath(roundedRect: scanArea, cornerRadius: 12)
        path.append(scanPath)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer

        // Corner brackets
        let bracketColor = UIColor.white
        let bracketWidth: CGFloat = 4
        let bracketLength: CGFloat = 30
        let cornerRadius: CGFloat = 12

        let corners: [(CGPoint, CGFloat)] = [
            (CGPoint(x: scanArea.minX, y: scanArea.minY), 0),           // Top-left
            (CGPoint(x: scanArea.maxX, y: scanArea.minY), .pi / 2),     // Top-right
            (CGPoint(x: scanArea.maxX, y: scanArea.maxY), .pi),         // Bottom-right
            (CGPoint(x: scanArea.minX, y: scanArea.maxY), -.pi / 2)     // Bottom-left
        ]

        for (point, rotation) in corners {
            let bracket = CAShapeLayer()
            let bracketPath = UIBezierPath()
            bracketPath.move(to: CGPoint(x: 0, y: bracketLength))
            bracketPath.addLine(to: CGPoint(x: 0, y: cornerRadius))
            bracketPath.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                              radius: cornerRadius,
                              startAngle: .pi,
                              endAngle: -.pi / 2,
                              clockwise: true)
            bracketPath.addLine(to: CGPoint(x: bracketLength, y: 0))

            bracket.path = bracketPath.cgPath
            bracket.strokeColor = bracketColor.cgColor
            bracket.fillColor = UIColor.clear.cgColor
            bracket.lineWidth = bracketWidth
            bracket.lineCap = .round
            bracket.position = point
            bracket.setAffineTransform(CGAffineTransform(rotationAngle: rotation))

            view.layer.addSublayer(bracket)
        }

        // Instructions label
        let instructionLabel = UILabel()
        instructionLabel.text = "Point camera at barcode"
        instructionLabel.textColor = .white
        instructionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)

        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: scanArea.minY - 40)
        ])

        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        guard !hasScanned,
              let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }

        hasScanned = true
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        delegate?.didScanBarcode(stringValue)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}

enum ScannerError: Error, LocalizedError {
    case noCameraAvailable
    case inputFailed
    case outputFailed

    var errorDescription: String? {
        switch self {
        case .noCameraAvailable:
            return "No camera available"
        case .inputFailed:
            return "Failed to set up camera input"
        case .outputFailed:
            return "Failed to set up barcode detection"
        }
    }
}
