//
//  CoreDataStack.swift
//  GithubUsers
//
//  Created by Yuri on 01.02.2024.
//

import CoreData

actor CoreDataStack {
    static let shared = CoreDataStack()
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GithubUsers")
        container.viewContext.automaticallyMergesChangesFromParent = true
        let description = container.persistentStoreDescriptions.first
        description?.shouldAddStoreAsynchronously = true
        return container
    }()
    
    lazy var mainContext: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    
    func loadPersistentStore() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.loadPersistentStores { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func save() {
        save(context: self.mainContext)
    }
    
    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch let error as NSError {
            print("Unresolved error \(error), \(error.userInfo)")
        }
    }
}

extension NSManagedObject {
    static var entityName: String {
        self.entity().name ?? String(describing: self)
    }
}

// MARK: - CRUD
extension NSManagedObjectContext {
    func batchFetch<T: NSManagedObject>(
        entityClass: T.Type,
        offset: Int = 0,
        fetchLimit: Int = 0,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) -> [T] {
        let request = NSFetchRequest<T>(entityName: T.entityName)
        request.predicate = predicate
        request.fetchOffset = offset
        request.fetchLimit = fetchLimit
        request.sortDescriptors = sortDescriptors
        do {
            let result: [T] = try self.fetch(request)
            return result
        } catch {
            print(error)
            return []
        }
    }
    
    func count<T: NSManagedObject>(entityClass: T.Type, predicate: NSPredicate? = nil) -> Int {
        let request = NSFetchRequest<T>(entityName: entityClass.entityName)
        request.predicate = predicate
        do {
            let result = try self.count(for: request)
            return result
        } catch {
            return 0
        }
    }
    
    func fetchFirst<T: NSManagedObject>(entityClass: T.Type, predicate: NSPredicate? = nil) -> T? {
        return batchFetch(entityClass: entityClass, predicate: predicate).first
    }
    
    func fetchOrCreate<T: NSManagedObject>(by predicate: NSPredicate) -> T {
        guard let item = fetchFirst(entityClass: T.self, predicate: predicate) else {
            return T(context: self)
        }
        return item
    }
}


