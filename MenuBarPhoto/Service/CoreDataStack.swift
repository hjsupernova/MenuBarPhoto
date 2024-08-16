//
//  CoreDataStack.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/14/24.
//

import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {

        let container = NSPersistentContainer(name: "Model")

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()

    private init() { }
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

//        guard let imageData = bitmap.jpegData(compressionQuality: 0.5) else { return }

        photo.imageData = data
        photo.dateCreated = Date()

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
}
