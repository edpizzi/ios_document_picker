import Flutter
import UIKit
import UniformTypeIdentifiers

enum PickerMode: Int { case file, folder }

public class IosDocumentPickerPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
  var resultFn: FlutterResult?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "ios_document_picker", binaryMessenger: registrar.messenger())
    let instance = IosDocumentPickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "InvalidArgsType", message: "Invalid args type", details: nil))
      return
    }
    switch call.method {
    case "pick":
      resultFn = result

      let mode = PickerMode(rawValue: args["type"] as! Int)
      let allowsMultiple = args["multiple"] as? Bool ?? false
      let allowedUtiTypes = args["allowedUtiTypes"] as? [String]
      let forExportingStr = args["forExporting"] as? [String] ?? []
      let forExporting = forExportingStr.map{ URL(string: $0)}.compactMap({ $0 });
      let asCopy = args["asCopy"] as? Bool ?? false
      let directoryUrlStr = args["directoryUrl"] as? String
      let utTypes = allowedUtiTypes?.compactMap { UTType($0) }

      let documentPicker: UIDocumentPickerViewController;
      if (!forExporting.isEmpty) {
        documentPicker = UIDocumentPickerViewController(forExporting: forExporting, asCopy: asCopy)
      } else {
        documentPicker = UIDocumentPickerViewController(
          forOpeningContentTypes: utTypes ?? (mode == .folder ? [UTType.folder] : [UTType.data]))
      }
      documentPicker.delegate = self
      documentPicker.allowsMultipleSelection = allowsMultiple
      if #available(iOS 13.0, *) {
        if let urlStr = directoryUrlStr {
          documentPicker.directoryURL = URL(string: urlStr);
        }
      }

      // Present the document picker.
      currentViewController()?.present(documentPicker, animated: true, completion: nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func currentViewController() -> UIViewController? {
    var keyWindow: UIWindow?
    for window in UIApplication.shared.windows {
      if window.isKeyWindow {
        keyWindow = window
        break
      }
    }

    var topController = keyWindow?.rootViewController
    while topController?.presentedViewController != nil {
      topController = topController?.presentedViewController
    }
    return topController
  }

  private func urlToMap(_ url: URL) -> [String: String] {
    return ["url": url.absoluteString, "path": url.path, "name": url.lastPathComponent]
  }

  public func documentPicker(
    _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
  ) {
    resultFn?(urls.map { urlToMap($0) })
  }

  public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    resultFn?(nil)
  }
}
