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
        
        searchBar.delegate = self // Set the ViewController as the UISearchBarDelegate
        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 44) // Set a fixed height for the search bar
        ])
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        fetchPetsData() // API Caller function
        
        // Add a tap gesture recognizer to the scrollView to handle tap events
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        scrollView.addGestureRecognizer(tapGesture)
    }
    
    // Handle tap on the scrollView to hide the keyboard and close the search bar
    @objc func handleTap() {
        view.endEditing(true)
        searchBar.resignFirstResponder()
    }
    
    func fetchPetsData() {
        let apiUrl = URL(string: "https://eulerity-hackathon.appspot.com/pets")!
        
        URLSession.shared.dataTask(with: apiUrl) { [weak self] data, _, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            guard let data = data else {
                print("Error: No data received")
                return
            }
            
            do {
                let pets = try JSONDecoder().decode([Pet].self, from: data)
                
                DispatchQueue.main.async { [weak self] in
                    self?.allPets = pets
                    self?.filteredPets = pets
                    self?.displayPets(pets)
                }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
        .resume()
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
