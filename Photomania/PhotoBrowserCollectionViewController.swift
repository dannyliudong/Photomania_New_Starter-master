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
  
  let PhotoBrowserCellIdentifier = "PhotoBrowserCell"
  let PhotoBrowserFooterViewIdentifier = "PhotoBrowserFooterView"
  
  // MARK: Life-cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupView()
    
    Alamofire.request(.GET, "https://api.500px.com/v1/photos", parameters: ["consumer_key": "5tU9ikrM096SaczrM3AX5lAXTJSkpkK3LQHTuWTN"]).responseJSON { (response) in
        guard let JSON = response.result.value else { return }
        print("JSON: \(JSON)")
        
        guard let photoJsons = JSON.valueForKey("photos") as? [NSDictionary] else { return }
        
        photoJsons.forEach{
            guard let nsfw = $0["nsfw"] as? Bool, let id = $0["id"] as? Int, let url = $0["image_url"] as? String
                where nsfw == false  else { return }
            
            self.photos.insert(PhotoInfo.init(id: id, url: url))
        }
        
        self.collectionView?.reloadData()
    }
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
