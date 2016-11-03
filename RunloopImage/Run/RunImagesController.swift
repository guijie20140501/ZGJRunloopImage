//
//  RunImagesController.swift
//  Run
//
//  Created by macc on 16/11/1.
//  Copyright © 2016年 ZhengGuiJie. All rights reserved.
//

import UIKit

class RunImagesController: UIViewController {

    private lazy var viewModel = PicsViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Run"
        setUpUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension RunImagesController: CycleImageViewDelegate {
    
    private func setUpUI() {
        let runView = CycleImageView(frame: view.bounds, delegate: self, placeholder: UIImage(named: "1.jpg"))
        runView.backgroundColor = UIColor.blackColor()
        view.addSubview(runView)
        runView.numType = .pageControl
        runView.autoScrollTimeInterval = 5
        runView.imageUrls = viewModel.dataSource
    }
    
    func didSelect(at index: Int) {
        print("点击了---\(index)")
    }
}
