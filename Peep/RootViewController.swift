//
//  RootViewController.swift
//  Peep
//
//  Created by Regynald Augustin on 11/22/18.
//  Copyright © 2018 Regynald Augustin. All rights reserved.
//

import UIKit

class RootViewController: UIPageViewController {

    let pages: [UIViewController] = {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return [storyboard.instantiateViewController(withIdentifier: Constants.CameraViewControllerIdentifier), storyboard.instantiateViewController(withIdentifier: Constants.SettingsViewControllerIdentifier)]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        
        guard let initialPage = pages.first else { return }
        self.setViewControllers([initialPage], direction: .forward, animated: true, completion: nil)
    }

}

extension RootViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let previousIndex = index - 1

        guard previousIndex >= 0,
            previousIndex < pages.count
        else { return nil }
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let nextIndex = index + 1
        
        guard nextIndex >= 0,
            nextIndex < pages.count
            else { return nil }
        return pages[nextIndex]
    }
    
}
