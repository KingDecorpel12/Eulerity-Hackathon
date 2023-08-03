//
//  EulerityViewController.swift
//  EulerityAppChallenge
//
//  Created by Omar Hegazy on 7/19/23.

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
    
    // MARK: - Display Data
    
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
            
            // Add tap gesture recognizer to each imageView
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(tapGesture)
            
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
        
        // Constrain the bottom of the scroll view to the last image view (if exists)
        if let lastImageView = imageViews.last {
            scrollView.bottomAnchor.constraint(equalTo: lastImageView.bottomAnchor, constant: 16).isActive = true
        }
    }
    
    // MARK: - Save & Upload Images
    
    // Handle tap on the imageView to show the action sheet for image upload options
    @objc func handleImageTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let imageView = gestureRecognizer.view as? UIImageView,
              let image = imageView.image else {
            return
        }
        
        showUploadOptions(image: image)
    }
    
    // Function to create and show an action sheet for image upload options
    func showUploadOptions(image: UIImage) {
        let actionSheet = UIAlertController(title: "Upload Image", message: "Choose an option", preferredStyle: .actionSheet)
        
        // Add an action to upload the image
        let uploadAction = UIAlertAction(title: "Upload", style: .default) { [weak self] _ in
            // Show an alert for entering the App Id
            self?.showAppIdAlert(image: image)
        }
        actionSheet.addAction(uploadAction)
        
        // Add a cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        // Present the action sheet
        present(actionSheet, animated: true, completion: nil)
    }
    
    // Function to create and show an alert for entering App Id
    func showAppIdAlert(image: UIImage) {
        let alert = UIAlertController(title: "Enter App Id", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "App Id"
        }
        
        // Add an action to upload the image with the entered App Id
        let uploadAction = UIAlertAction(title: "Upload", style: .default) { [weak self] _ in
            if let appId = alert.textFields?.first?.text {
                self?.uploadImageToServer(image, appId: appId)
            }
        }
        alert.addAction(uploadAction)
        
        // Add a cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        // Present the alert
        present(alert, animated: true, completion: nil)
    }
    
    // Function to save the image locally on the device and return the URL
    func saveImageLocally(_ image: UIImage, imageName: String) -> URL? {
        if let data = image.jpegData(compressionQuality: 1.0) {
            let fileManager = FileManager.default
            if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentsDirectory.appendingPathComponent("\(imageName).jpg")
                do {
                    try data.write(to: fileURL)
                    print("Image saved locally.")
                    return fileURL
                } catch {
                    print("Error saving image locally: \(error)")
                }
            }
        }
        return nil
    }
    
    // Function to get the URL of the locally saved image
    func getLocalImageURL() -> URL? {
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            return documentsDirectory.appendingPathComponent("uploaded_image.jpg")
        }
        return nil
    }
    
    // Function to handle image upload to the server with the provided App Id
    func uploadImageToServer(_ image: UIImage, appId: String) {
        // Save the image locally
        if let imageUrl = saveImageLocally(image, imageName: "uploaded_image") {
            print("Local image URL: \(imageUrl)")
        }
        
        // Get the upload URL from the server
        APICaller.getUploadURL { [weak self] result in
            switch result {
            case .success(let uploadURL):
                // Upload the image to the server with the provided App Id
                APICaller.uploadImage(imageURL: (self?.getLocalImageURL())!, appID: appId, originalURL: uploadURL) { uploadResult in
                    switch uploadResult {
                    case .success(let uploaded):
                        if uploaded {
                            print("Image uploaded successfully.")
                        } else {
                            print("Image upload failed.")
                        }
                    case .failure(let error):
                        print("Image upload error: \(error)")
                    }
                }
            case .failure(let error):
                print("Error fetching upload URL: \(error)")
            }
        }
    }
    
    // MARK: - Other
    
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
}

// MARK: - Extensions

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
