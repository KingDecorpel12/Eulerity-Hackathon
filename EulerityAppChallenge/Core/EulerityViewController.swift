//
//  EulerityViewController.swift
//  EulerityAppChallenge
//
//  Created by Omar Hegazy on 7/19/23.
//  In this challenge, I use UIKit to dyanamically create views and programmatically make a GET request to obtain and load images and their related info in a list format.

import UIKit

class EulerityViewController: UIViewController {
    
    var allPets: [Pet] = [] // Store all pets received from the API
    var filteredPets: [Pet] = [] // Store the filtered pets based on the search
    var imageViews: [UIImageView] = []
    let scrollView = UIScrollView()
    let searchBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        updateAppearance()
        
        searchBar.delegate = self // Sets the view controller as the UISearchBarDelegate
        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 44) // Sets a fixed height for the search bar
        ])
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Fetches data from API
        APICaller.fetchPetsData { [weak self] pets, error in
            if let error = error {
                print("Error fetching pets: \(error)")
                return
            }
            
            if let pets = pets {
                DispatchQueue.main.async {
                    self?.allPets = pets
                    self?.filteredPets = pets
                    self?.displayPets(pets)
                }
            }
        }
        
        // Adds a tap gesture recognizer to the scrollView to handle tap events
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        scrollView.addGestureRecognizer(tapGesture)
    }
    
    // Handle tap on the scrollView to hide the keyboard and close the search bar
    @objc func handleTap() {
        view.endEditing(true)
        searchBar.resignFirstResponder()
    }
    
    // Updates the appearance based on the current user interface style (light/dark mode)
    func updateAppearance() {
        
        // Sets the background color of the view controller based on the current user interface style
        if traitCollection.userInterfaceStyle == .dark {
            view.backgroundColor = .black
        } else {
            view.backgroundColor = .white
        }
        
        // Sets the background color of the scrollView
        scrollView.backgroundColor = .clear
        
        // Sets the text color for labels in light and dark mode
        let textColor: UIColor
        if traitCollection.userInterfaceStyle == .dark {
            textColor = .white
        } else {
            textColor = .black
        }
        
        // Sets the text color for the title and description labels inside the scrollView
        for subview in scrollView.subviews {
            if let titleLabel = subview as? UILabel {
                titleLabel.textColor = textColor
            } else if let descriptionLabel = subview as? UILabel {
                descriptionLabel.textColor = textColor
            }
        }
    }
    
    // Updates the appearance when the user interface style (light/dark mode) changes
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearance()
    }
    
    // Displays data in list format with proper constraints
    func displayPets(_ pets: [Pet]) {
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
        imageViews.removeAll()
        
        let imageSize: CGFloat = 200
        let spacing: CGFloat = 16
        var offsetY: CGFloat = 16 // Initial offset from the top
        
        for pet in pets {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(imageView)
            
            // Stores the image view in an array
            imageViews.append(imageView)
            
            // Constrains the image view size
            imageView.heightAnchor.constraint(equalToConstant: imageSize).isActive = true
            imageView.widthAnchor.constraint(equalToConstant: imageSize).isActive = true
            
            // Horizontally centers the image view
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
            
            // Vertically spaces the image view
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: offsetY).isActive = true
            
            // Loads the image asynchronously
            URLSession.shared.dataTask(with: pet.url) { data, _, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }
            }
            .resume()
            
            // Creates and configures the title label
            let titleLabel = UILabel()
            titleLabel.text = pet.title
            titleLabel.textAlignment = .center
            titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(titleLabel)
            
            // Places the title label below the image view
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8).isActive = true
            titleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
            
            // Creates and configures the description label
            let descriptionLabel = UILabel()
            descriptionLabel.text = pet.description
            descriptionLabel.textAlignment = .center
            descriptionLabel.numberOfLines = 0 // Allows multiple lines
            descriptionLabel.lineBreakMode = .byWordWrapping // Wraps text to a new line
            descriptionLabel.font = UIFont.systemFont(ofSize: 14)
            descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(descriptionLabel)
            
            // Places the description label below the title label
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4).isActive = true
            descriptionLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
            
            // Constrain the description label's leading and trailing to the scroll view
            descriptionLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16).isActive = true
            descriptionLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16).isActive = true
            
            // Updates the offsetY for the next set of views
            offsetY += imageSize + spacing + 8 + titleLabel.intrinsicContentSize.height + descriptionLabel.intrinsicContentSize.height + 16
        }
        
        // Constrain the bottom of the scroll view to the last image view
        scrollView.bottomAnchor.constraint(equalTo: imageViews.last!.bottomAnchor, constant: 16).isActive = true
    }
}

// Conforms the view controller to delegate protocol of search bar
extension EulerityViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredPets = allPets
        } else {
            filteredPets = allPets.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText) }
        }
        displayPets(filteredPets)
    }
    
    // Hides the keyboard when the user taps anywhere on the view
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
}
