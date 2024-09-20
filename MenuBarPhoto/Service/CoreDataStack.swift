//
//  CoreDataStack.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/14/24.
//

import AppKit
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    static var preview: CoreDataStack = {
        let result = CoreDataStack(inMemory: true)
        return result
    }()

    let persistentContainer: NSPersistentContainer

    init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(name: "Model")
        if inMemory {
            persistentContainer.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
    }
}

extension CoreDataStack {
    func save() {
        guard persistentContainer.viewContext.hasChanges else { return }

        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("Failed to save the context:", error.localizedDescription)

        }
    }
}

// MARK: - Photo

extension CoreDataStack {
    func savePhoto(_ data: Data) {
        let photo = Photo(context: persistentContainer.viewContext)

        photo.photoData = data
        photo.dateCreated = Date()
        photo.photoId = UUID()

        save()
    }

    func fetchPhotos() -> [Photo] {
        let request = NSFetchRequest<Photo>(entityName: "Photo")
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: true)]

        do {

            return try persistentContainer.viewContext.fetch(request)

        } catch {
            print("Error fetching photos: \(error)")
            return []
        }
    }

    func deletePhoto(id: UUID?) {
        guard let id else { return }
        let request = NSFetchRequest<Photo>(entityName: "Photo")
        request.predicate = NSPredicate(format: "photoId == %@", id as CVarArg)

        do {
            let results = try persistentContainer.viewContext.fetch(request)
            if let photoToDelete = results.first {
                persistentContainer.viewContext.delete(photoToDelete)
                save()
            }
        } catch {
            print("Error deleting photo: \(error)")
        }

    }
}

// MARK: - Preview

extension CoreDataStack {

    var samplePhotos: [Photo] {
        let context = Self.preview.persistentContainer.viewContext
        var photos: [Photo] = []

        for i in 0..<5  {
            let systemName = "\(i).circle"

            // Create NSImage from the system name
            if let image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil) {
                // Convert NSImage to Data
                let imageData = image.tiffRepresentation

                // Create new Photo and assign properties
                let newPhoto = Photo(context: context)
                newPhoto.photoData = imageData
                newPhoto.dateCreated = Date()
                newPhoto.photoId = UUID()

                photos.append(newPhoto)
            }
        }

        return photos
    }
}
