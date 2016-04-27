//
//  PhotoBrowserCollectionViewController.swift
//  Photomania
//
//  Created by Essan Parto on 2014-08-20.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire

class PhotoBrowserCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var photos = Set<PhotoInfo>()
  
    let refreshControl = UIRefreshControl()
    var populatingPhotos = false
    var currentPage = 1
  
    let PhotoBrowserCellIdentifier = "PhotoBrowserCell"
    let PhotoBrowserFooterViewIdentifier = "PhotoBrowserFooterView"
  
  // MARK: Life-cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupView()
    
    populatePhotos()
    
//    Alamofire.request(.GET, "https://api.500px.com/v1/photos", parameters: ["consumer_key": "5tU9ikrM096SaczrM3AX5lAXTJSkpkK3LQHTuWTN"]).responseJSON { (response) in
//        guard let JSON = response.result.value else { return }
//        print("JSON: \(JSON)")
//        
//        guard let photoJsons = JSON.valueForKey("photos") as? [NSDictionary] else { return }
//        
//        photoJsons.forEach{
//            guard let nsfw = $0["nsfw"] as? Bool, let id = $0["id"] as? Int, let url = $0["image_url"] as? String
//                where nsfw == false  else { return }
//            
//            self.photos.insert(PhotoInfo.init(id: id, url: url))
//        }
//        
//        self.collectionView?.reloadData()
//    }
    
    
    }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: CollectionView
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoBrowserCellIdentifier, forIndexPath: indexPath) as! PhotoBrowserCollectionViewCell
    
    let photoInfo = self.photos[self.photos.startIndex.advancedBy(indexPath.item)]
    
    Alamofire.request(.GET, photoInfo.url).response { (_, _, data, _) in
        guard let data = data else { return }
        let image = UIImage(data: data)
        cell.imageView.image = image
        
    }
    return cell
  }
  
  override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: PhotoBrowserFooterViewIdentifier, forIndexPath: indexPath) as UICollectionReusableView
  }
  
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    performSegueWithIdentifier("ShowPhoto", sender: self.photos[self.photos.startIndex.advancedBy(indexPath.item)].id)
  }
  
  // MARK: Helper
  
  func setupView() {
    navigationController?.setNavigationBarHidden(false, animated: true)
    
    guard let collectionView = self.collectionView else { return }
    let layout = UICollectionViewFlowLayout()
    let itemWidth = (view.bounds.size.width - 2) / 3
    layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
    layout.minimumInteritemSpacing = 1.0
    layout.minimumLineSpacing = 1.0
    layout.footerReferenceSize = CGSize(width: collectionView.bounds.size.width, height: 100.0)
    
    collectionView.collectionViewLayout = layout
    
    let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 60.0, height: 30.0))
    titleLabel.text = "Photomania"
    titleLabel.textColor = UIColor.whiteColor()
    titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
    navigationItem.titleView = titleLabel
    
    collectionView.registerClass(PhotoBrowserCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: PhotoBrowserCellIdentifier)
    collectionView.registerClass(PhotoBrowserCollectionViewLoadingCell.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: PhotoBrowserFooterViewIdentifier)
    
    refreshControl.tintColor = UIColor.whiteColor()
    refreshControl.addTarget(self, action: #selector(PhotoBrowserCollectionViewController.handleRefresh), forControlEvents: .ValueChanged)
    collectionView.addSubview(refreshControl)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ShowPhoto" {
      (segue.destinationViewController as! PhotoViewerViewController).photoID = sender!.integerValue
      (segue.destinationViewController as! PhotoViewerViewController).hidesBottomBarWhenPushed = true
    }
  }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
//        一旦滚动超过了 80% 的页面，那么scrollViewDidScroll()方法将会加载更多的图片
        if scrollView.contentOffset.y + self.view.frame.size.height > scrollView.contentSize.height * 0.8 {
            self.populatePhotos()
        }
    }
    
    func populatePhotos() {
        // 2
        if populatingPhotos {
            return
        }
        
        populatingPhotos = true
        
        // 3
        Alamofire.request(Five100px.Router.PopularPhotos(self.currentPage)).responseJSON() {
            response in
            func failed() { self.populatingPhotos = false }
            guard let JSON = response.result.value else { failed(); return }
            if response.result.error != nil { failed(); return }
            
            // 4
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                // 5
                guard let photoJsons = JSON.valueForKey("photos") as? [NSDictionary] else { return }
                
                // 6
                let lastItem = self.photos.count
                
                // 7
                photoJsons.forEach {
                    guard let nsfw = $0["nsfw"] as? Bool,
                        let id = $0["id"] as? Int,
                        let url = $0["image_url"] as? String
                        where nsfw == false else { return }
                    // 8
                    self.photos.insert(PhotoInfo(id: id, url: url))
                }
                
                // 9
                let indexPaths = (lastItem..<self.photos.count).map { NSIndexPath(forItem: $0, inSection: 0) }
                
                // 10
                dispatch_async(dispatch_get_main_queue()) {
                    self.collectionView!.insertItemsAtIndexPaths(indexPaths)
                }
                
                self.currentPage += 1
                
            }
        }
        self.populatingPhotos = false
    }
    
  
  func handleRefresh() {
    
  }
}

class PhotoBrowserCollectionViewCell: UICollectionViewCell {
  let imageView = UIImageView()
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = UIColor(white: 0.1, alpha: 1.0)
    
    imageView.frame = bounds
    addSubview(imageView)
  }
}

class PhotoBrowserCollectionViewLoadingCell: UICollectionReusableView {
  let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    spinner.startAnimating()
    spinner.center = self.center
    addSubview(spinner)
  }
}
