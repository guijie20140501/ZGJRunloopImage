//
//  RunImageView.swift
//  Run
//
//  Created by macc on 16/11/1.
//  Copyright © 2016年 ZhengGuiJie. All rights reserved.
//

import UIKit
import YYWebImage
/**
 设置的图片类型
 
 - net:   网络
 - local: 本地
 */
enum ShowImageType {
    case net
    case local
}

/**
 当前页显示类型
 
 - label:       UILabel显示---1/4
 - pageControl: UIPageControl显示
 */
enum ShowNumType {
    case label
    case pageControl
}

class CycleImageView: UIView {
    private lazy var imgView = UIImageView()
    private lazy var indexLabel = UILabel()
    private lazy var pageControl = UIPageControl()
    /// 当前显示的index
    private var currentIndex: Int = 0 {
        didSet {
           setImage(with: currentIndex)
        }
    }
    /// 轮播图时间间隔---默认为5秒
    var autoScrollTimeInterval: Double = 5 {
        didSet {
        // 指定定时器开始的时间和间隔的时间
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, Int64(autoScrollTimeInterval)), UInt64(autoScrollTimeInterval) * NSEC_PER_SEC, 0)
        }
    }
    /// 外界传入的url/本地图片名称数组
    var imageUrls: [String] = [] {
        didSet {
            setImage()
            // 当numType不是默认时，轮播图不滑动时，显示当前页的控件不显示问题
            setPage(with: 0)
            guard imageUrls.count > 1 else { return }
            // 设置图片数组后，延迟时间来启动GCDtimer
            GCD.delay(seconds: autoScrollTimeInterval) {
                [weak self] in
                guard let strongSelf = self else { return }
                dispatch_resume(strongSelf.timer)
            }
        }
    }
    /// 设置图片类型---本地/网络---默认为网络
    var showType: ShowImageType = .net {
        didSet {
            guard imageUrls.count > 1 else { return }
            setImage()
        }
    }
    /// 设置显示当前页数字类型---默认是UIPageControl
    var numType: ShowNumType = .pageControl {
        didSet {
            draw()
        }
    }
    /// pageControl显示非当前页时的圆点颜色---默认灰色
    var pageIndicatorTintColor: UIColor = UIColor.grayColor() {
        didSet {
            colorTupe = (pageIndicatorTintColor, currentPageTintColor)
        }
    }
    /// pageControl显示当前页时的圆点颜色---默认白色
    var currentPageTintColor: UIColor = UIColor.whiteColor() {
        didSet {
          colorTupe = (pageIndicatorTintColor, currentPageTintColor)
        }
    }
    /// 数字显示当前页时的字体颜色---默认黑色
    var pageLabelColor: UIColor = UIColor.blackColor() {
        didSet {
            indexLabel.textColor = pageLabelColor
        }
    }
    /// GCD定时器
    private lazy var timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    /// 占位图
    private var placeholder: UIImage?
    /// pageControl的圆点颜色元组
    private var colorTupe: (tintColor: UIColor, current: UIColor) = (UIColor.grayColor(), UIColor.whiteColor())
    /// 图片点击代理
    weak var delegate: CycleImageViewDelegate?
    
    /**
     初始化方法
     
     - parameter frame:       轮播图frame
     - parameter delegate:    轮播图代理---可选
     - parameter placeholder: 轮播图占位图
     
     - returns: 轮播图view
     */
    init(frame: CGRect, delegate: CycleImageViewDelegate?,placeholder: UIImage?) {
        self.placeholder = placeholder
        self.delegate = delegate
        super.init(frame: frame)
        setDefault()
        addGuesture()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CycleImageView {
    private func draw() {
        for sub in subviews {
            sub.removeFromSuperview()
        }
        
        imgView.frame = self.bounds
        imgView.contentMode = .ScaleAspectFit
        imgView.image = placeholder
        addSubview(imgView)
        
        switch numType {
        case .label:
            addSubview(indexLabel)
            indexLabel.font = UIFont.systemFontOfSize(15.0)
            indexLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let rightCon = NSLayoutConstraint(item: indexLabel, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: -20)
            let bottomCom = NSLayoutConstraint(item: indexLabel, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -20)
            addConstraints([rightCon, bottomCom])
        case .pageControl:
            addSubview(pageControl)
            pageControl.currentPage = 0
            
            pageControl.translatesAutoresizingMaskIntoConstraints = false
            
            let bottomCom = NSLayoutConstraint(item: pageControl, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -20)
            let leftCom = NSLayoutConstraint(item: pageControl, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 20)
            let rightCom = NSLayoutConstraint(item: pageControl, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: -20)
            let centerXCom = NSLayoutConstraint(item: pageControl, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
            addConstraints([leftCom, rightCom, bottomCom, centerXCom])
        }
        //设置GCD执行方法
        dispatch_source_set_event_handler(timer) {
            dispatch_async(dispatch_get_main_queue(), {
                [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.currentIndex += 1
                strongSelf.animationTransition(with: .Left)
            })
        }
    }
    
    /**
     设置默认值
     */
    private func setDefault() {
        autoScrollTimeInterval = 5
        numType = .pageControl
        
    }
    /**
     添加手势
     */
    private func addGuesture() {
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(gestureMethod(_:)))
        leftSwipeGesture.direction = .Left
        self.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(gestureMethod(_:)))
        rightSwipeGesture.direction = .Right
        self.addGestureRecognizer(rightSwipeGesture)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tap)
    }
}

extension CycleImageView {
    /**
     手势方法
     - parameter sender: 响应的手势
     */
    func gestureMethod(sender: UISwipeGestureRecognizer) {
        //暂停手势
        dispatch_suspend(timer)
        guard imageUrls.count > 1 else {
            return
        }
        let direction = sender.direction
        switch direction {
        case UISwipeGestureRecognizerDirection.Left:
            currentIndex += 1
        case UISwipeGestureRecognizerDirection.Right:
            currentIndex -= 1
        default:
            break
        }
        animationTransition(with: direction)
        // 添加左右滑动手势，切换图片之后，延迟时间来恢复GCDtimer
        GCD.delay(seconds: autoScrollTimeInterval) {
            [weak self] in
            guard let strongSelf = self else { return }
            dispatch_resume(strongSelf.timer)
        }
    }
    /**
     点击手势
     */
    func tapAction() {
        delegate?.didSelect(at: currentIndex)
    }
    /**
     转场动画
     
     - parameter direction: 手势方向
     */
    private func animationTransition(with direction: UISwipeGestureRecognizerDirection) {
        let transition = CATransition()
        transition.duration = 0.5
        //设置动画的样式
        transition.type = kCATransitionPush
        switch direction {
        case UISwipeGestureRecognizerDirection.Right:
            transition.subtype = "fromLeft"
        case UISwipeGestureRecognizerDirection.Left:
            transition.subtype = "fromRight"
        default:
            break
        }
        imgView.layer.addAnimation(transition, forKey: nil)
    }
    /**
     根据索引设置图片
     
     - parameter index: 索引
     */
    private func setImage(with index: Int) {
        guard imageUrls.count > 1 else {
            return
        }
        if currentIndex > imageUrls.count - 1 {
            currentIndex = 0
        } else if currentIndex < 0 {
            currentIndex = imageUrls.count - 1
        }
        setImage()
        setPage(with: currentIndex)
    }
    /**
     设置页数显示
     
     - parameter index: 当前显示index
     */
    private func setPage(with index: Int) {
        switch numType {
        case .label:
            indexLabel.text = "\(index + 1)/\(imageUrls.count)"
        case .pageControl:
            pageControl.pageIndicatorTintColor = colorTupe.tintColor
            pageControl.currentPageIndicatorTintColor = colorTupe.current
            pageControl.numberOfPages = imageUrls.count
            pageControl.currentPage = index
        }
    }
    /**
     设置图片
     */
    private func setImage() {
        switch  showType {
        case .local:
        imgView.image = UIImage(named: imageUrls[currentIndex])
        case .net:
        imgView.yy_setImageWithURL(NSURL(string: imageUrls[currentIndex]), placeholder: UIImage(named: imageUrls[currentIndex]), options: [.ProgressiveBlur, .SetImageWithFadeAnimation], completion: nil)
        }
    }
}

/// 轮播图代理
protocol CycleImageViewDelegate: class {
    /**
     点击图片回调
     */
    func didSelect(at index: Int)
}


struct GCD {
    /**
     GCD延迟处理
     
     - parameter time:   延迟时间
     - parameter action: 闭包
     */
    static func delay(seconds seconds: Double, action: () -> Void) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            action()
        }
    }
}