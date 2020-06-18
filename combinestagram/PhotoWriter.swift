import Foundation
import UIKit
import Photos
import RxSwift

// what this shit is doing, why I am writing this shit.
// First thing first, rest in peace uncle phil.

class PhotoWriter {
  enum Errors: Error {
    case couldNotSavePhoto
  }

  // save created photo right ?
  static func save(_ image: UIImage) -> Observable<String> {
    return Observable.create { observer in
      var savedAssetId: String?
      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
        savedAssetId = request.placeholderForCreatedAsset?.localIdentifier
      }, completionHandler: { success, error in
        // every UI related shit needs to be done in main Queue
        DispatchQueue.main.async {
          if success, let id = savedAssetId {
            observer.onNext(id)
            observer.onCompleted()
          } else {
            observer.onError(error ?? Errors.couldNotSavePhoto)
          }
        }
      })
      return Disposables.create()
    }
  }
  
}
