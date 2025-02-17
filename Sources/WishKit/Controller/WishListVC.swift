//
//  WishListVC.swift
//  wishkit-ios
//
//  Created by Martin Lasek on 2/9/23.
//  Copyright © 2023 Martin Lasek. All rights reserved.
//

#if canImport(UIKit)
import UIKit
import WishKitShared

final class WishListVC: UIViewController {
    enum Kind: Int {
        case requested = 0
        case implemented = 1

        var title: String {
            switch self {
            case .requested:
                return "Requested"
            case .implemented:
                return "Implemented"
            }
        }
    }

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 15
        return stackView
    }()

    private let switchContainer = UIView()

    private lazy var switchListControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [Kind.requested.title, Kind.implemented.title])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = UIColor(WishKit.theme.primaryColor)
        control.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(self, action: #selector(switchListAction), for: .valueChanged)
        return control
    }()

    private let watermarkLabel: UILabel = {
        let label = UILabel()
        label.text = "Powered by Wishkit.io"
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = .systemGray2
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var tableView: TableView = {
        let tableView = TableView()
        tableView.register(WishCell.self, forCellReuseIdentifier: WishCell.identifier)
        tableView.dataSource = wishVM
        tableView.delegate = wishVM
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 80, right: 0)
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchWishList), for: .valueChanged)
        return refreshControl
    }()

    private lazy var addWishButton: AddButton = {
        let button = AddButton()
        button.addTarget(self, action: #selector(createWishAction), for: .touchUpInside)
        return button
    }()

    private let spinner = UIActivityIndicatorView()

    private lazy var wishVM: WishListVM = {
        let wishVM = WishListVM()
        wishVM.delegate = self
        return wishVM
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        applyWishKitConfiguration()
        
        setup()
        spinner.startAnimating()
        fetchWishList()
    }
}

// MARK: - Action

extension WishListVC {

    @objc func switchListAction(_ sender: UISegmentedControl) {
        guard let kind = Kind(rawValue: sender.selectedSegmentIndex) else {
            printError(self, "Could not get kind when using segmented control.")
            return
        }

        wishVM.updateList(to: kind)
    }

    @objc private func fetchWishList() {
        wishVM.fetchWishList()
    }

    @objc private func createWishAction() {
        let vc = CreateWishVC()
        vc.delegate = self

        if let navigationController = navigationController {
            navigationController.pushViewController(vc, animated: true)
        } else {
            present(vc, animated: true)
        }
    }
}

// MARK: - WishKit Configuration

extension WishListVC {
    func applyWishKitConfiguration() {
        switchContainer.isHidden = !WishKit.configuration.showSegmentedControl
    }
}

// MARK: - Setup

extension WishListVC {

    private func setup() {
        view.backgroundColor = .secondarySystemBackground
        navigationItem.title = "Feature Wishlist"
        setupTabBar()

        setupView()
        setupConstraints()
    }

    private func setupTabBar() {
        tabBarItem.image = UIImage(systemName: "lightbulb")
        tabBarItem.selectedImage = UIImage(systemName: "lightbulb.fill")
        tabBarItem.title = "Wishlist"
    }

    private func setupView() {
        view.addSubview(watermarkLabel)
        view.addSubview(spinner)
        view.addSubview(stackView)
        view.addSubview(addWishButton)

        switchContainer.addSubview(switchListControl)
        stackView.addArrangedSubview(switchContainer)
        stackView.addArrangedSubview(tableView)
        tableView.addSubview(refreshControl)
    }

    private func setupConstraints() {

        stackView.anchor(
            top: view.layoutMarginsGuide.topAnchor,
            leading: view.leadingAnchor,
            bottom: view.bottomAnchor,
            trailing: view.trailingAnchor
        )

        switchListControl.anchor(
            top: switchContainer.topAnchor,
            bottom: switchContainer.bottomAnchor,
            centerX: switchContainer.centerXAnchor,
            padding: UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
        )

        watermarkLabel.anchor(
            centerY: addWishButton.centerYAnchor,
            centerX: view.centerXAnchor
        )

        let hasTabBarController = tabBarController != nil
        let bottomPadding: CGFloat = hasTabBarController ? 20 : 0

        addWishButton.anchor(
            bottom: view.layoutMarginsGuide.bottomAnchor,
            trailing: view.trailingAnchor,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: bottomPadding, right: 15)
        )

        spinner.anchor(
            centerY: view.centerYAnchor,
            centerX: view.centerXAnchor
        )
    }
}

// MARK: - WishVMDelegate

extension WishListVC: WishVMDelegate {
    func listWasUpdated() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
            self.watermarkLabel.isHidden = !self.wishVM.shouldShowWatermark
        }
    }

    func didSelect(wishResponse: WishResponse) {
        let vc = DetailWishVC(wishResponse: wishResponse)

        if let navigationController = navigationController {
            navigationController.pushViewController(vc, animated: true)
        } else {
            present(vc, animated: true)
        }
    }
}

// MARK: - CreateWishDelegate

extension WishListVC: CreateWishDelegate {
    func newWishWasSuccessfullyCreated() {
        spinner.startAnimating()
        fetchWishList()
    }
}
#endif
