import UIKit
import Photos
import RxSwift

class PhotosViewController: UICollectionViewController {

  private lazy var photos = PhotosViewController.loadPhotos()
  private lazy var imageManager = PHCachingImageManager()
  
  // set this to private, you only want to stream controller in this controller
  private let selectedPhotosSubject = PublishSubject<UIImage>()
  
  // set this to public, cause you want to get the stream, but you stream value to this will not effect the model.
  var selectedPhotos: Observable<UIImage> {
    return selectedPhotosSubject.asObservable()
  }


  private lazy var thumbnailSize: CGSize = {
    let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
    return CGSize(width: cellSize.width * UIScreen.main.scale,
                  height: cellSize.height * UIScreen.main.scale)
  }()

  static func loadPhotos() -> PHFetchResult<PHAsset> {
    let allPhotosOptions = PHFetchOptions()
    allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    return PHAsset.fetchAssets(with: allPhotosOptions)
  }

  // MARK: View Controller
  override func viewDidLoad() {
    super.viewDidLoad()

  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    selectedPhotosSubject.onCompleted()
  }

  // MARK: UICollectionView

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

    let asset = photos.object(at: indexPath.item)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCell

    cell.representedAssetIdentifier = asset.localIdentifier
    imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
      if cell.representedAssetIdentifier == asset.localIdentifier {
        cell.imageView.image = image
      }
    })

    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let asset = photos.object(at: indexPath.item)

    if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
      cell.flash()
    }

    imageManager.requestImage(for: asset, targetSize: view.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { [weak self] image, info in
      guard let image = image, let info = info else { return }
      if let isThumbnail = info[PHImageResultIsDegradedKey as NSString] as? Bool, !isThumbnail {
        self?.selectedPhotosSubject.onNext(image)
      }
    })
  }
}
