//
//  NewsViewController.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 22.12.2025.
//

import UIKit

class NewsViewController: UIViewController {
    private let posts: [UIView] = [V(), PostView(), V(), PostView()]
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    let stackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .vertical
        view.spacing = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        for post in posts {
            post.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                post.heightAnchor.constraint(equalToConstant: 200),
                post.widthAnchor.constraint(equalToConstant: 100),
//                post.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
            ])
            stackView.addArrangedSubview(post)
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
        ])
    }
    
    func setupStackView() {
        
    }
}

class V: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .red
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: 100, height: 100)
    }
}


class PostView: UIView {
    private let frontLayer = CALayer()
    private let inset: CGFloat = 40
    let customMask = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setup() {
        backgroundColor = .clear
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 20
        layer.shadowOpacity = 1
        
        
        frontLayer.mask = customMask
        frontLayer.backgroundColor = UIColor.white.cgColor
        layer.addSublayer(frontLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        frontLayer.frame = bounds
        
        let maskAndShadowPath = UIBezierPath()
        maskAndShadowPath.move(to: CGPoint(x: 0, y: inset))
        maskAndShadowPath.addLine(to: CGPoint(x: inset, y: 0))
        maskAndShadowPath.addLine(to: CGPoint(x: bounds.width - inset, y: 0))
        maskAndShadowPath.addArc(withCenter: CGPoint(x: bounds.width - inset, y: inset),
                                 radius: inset,
                                 startAngle: -CGFloat.pi / 2,
                                 endAngle: 0,
                                 clockwise: true)
        maskAndShadowPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height - inset))
        maskAndShadowPath.addLine(to: CGPoint(x: bounds.width - inset, y: bounds.height))
        maskAndShadowPath.addLine(to: CGPoint(x: inset, y: bounds.height))
        maskAndShadowPath.addArc(withCenter: CGPoint(x: inset, y: bounds.height - inset),
                                 radius: inset,
                                 startAngle: CGFloat.pi / 2,
                                 endAngle: CGFloat.pi,
                                 clockwise: true)
        maskAndShadowPath.close()
        
        customMask.frame = bounds
        customMask.path = maskAndShadowPath.cgPath
        layer.shadowPath = maskAndShadowPath.cgPath
    }
}
