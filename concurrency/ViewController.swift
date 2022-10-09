//
//  ViewController.swift
//  concurrency
//
//  Created by Nikolay Kiyko on 09.10.2022.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    private let imageURLs = [
        "https://upload.wikimedia.org/wikipedia/en/thumb/d/d3/Starbucks_Corporation_Logo_2011.svg/1280px-Starbucks_Corporation_Logo_2011.svg.png",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/BMW_logo_%28gray%29.svg/1280px-BMW_logo_%28gray%29.svg.png",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Volkswagen_logo_2019.svg/1280px-Volkswagen_logo_2019.svg.png",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/7/76/Louis_Vuitton_logo_and_wordmark.svg/1024px-Louis_Vuitton_logo_and_wordmark.svg.png"
    ]

    private var images = [Data] ()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = UIColor(red: 224/255,
                                       green: 176/255,
                                       blue: 255/255,
                                       alpha: 1)
        view.axis = .vertical
        view.distribution = .fillEqually
        view.spacing = 20
        return view
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        asyncGroup()
    }

    private func setupViews() {
        view.backgroundColor = UIColor(red: 224/255,
                                       green: 176/255,
                                       blue: 255/255,
                                       alpha: 1)
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.left.right.equalToSuperview()
        }
        stackView.addArrangedSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func asyncGroup() {
        print("\n-------- asyncGroup --------\n")
        let dispatchGroup = DispatchGroup()
        
        // Формирую группу асинхронных операций
        for i in 0...3 {
            dispatchGroup.enter()
            asyncLoadImage(imageURL: URL(string: imageURLs[i])!,
                           runQueue: DispatchQueue.global(),
                           completionQueue: DispatchQueue.main)
            { result, error in
                guard let image1 = result else { return }
                print("изображение \(i) приоритет = \(qos_class_self().rawValue)")
                self.images.append(image1)
                dispatchGroup.leave()
            }
        }
        
        // Блок обратного вызова на всю группу
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.stackView.removeArrangedSubview(self.activityIndicator)
            for i in 0...3 {
                self.addImage(data: self.images[i])
            }
        }
    }
}

private extension ViewController {
    func asyncLoadImage(
        imageURL: URL,
        runQueue: DispatchQueue,
        completionQueue: DispatchQueue,
        completion: @escaping (Data?, Error?) -> ()
    ) {
        runQueue.async {
            do {
                let data = try Data(contentsOf: imageURL)
                sleep(arc4random() % 4) // Симуляция медленной работы интернента
                completionQueue.async { completion(data, nil) }
            } catch let error {
                completionQueue.async {
                    completionQueue.async { completion(nil, error) }
                }
            }
        }
    }
    
    func addImage(data: Data) {
        let view = UIImageView(image: UIImage(data: data))
        view.contentMode = .scaleAspectFit
        self.stackView.addArrangedSubview(view)
    }
}
