//
//  PPRDataController.swift
//  CoreData0805
//
//  Created by leslie on 8/5/20.
//  Copyright © 2020 leslie. All rights reserved.
//

import Foundation
import CoreData

let RECIPE_TYPES = "ppRecipeTypes"

class PPRDataController {
    
    var mainContext: NSManagedObjectContext?
    var writerContext: NSManagedObjectContext?
    var persistenceInitialized = false
    var initializationComplete: (() -> Void)?

    init(completion: @escaping () -> Void) {
      initializationComplete = completion
      initializeCoreDataStack()
    }

    func initializeCoreDataStack() {
        guard let modelURL = Bundle.main.url(forResource: "PPRecipes", withExtension: "momd") else {
            fatalError("Failed to locate DataModel.momd in app bundle")
        }
        
        //MARK: - ManagedObjectModel
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to initialize MOM")
        }
        
        //MARK: - PersistentStoreCoordinator
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        //MARK: - ManagedObjectContext
        ///NSManagedObjectContext can’t be accessed from multiple threads.
        ///Each thread that needs access to data should have its own NSManagedObjectContext.
        let type = NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType
        self.mainContext = NSManagedObjectContext(concurrencyType: type)
        self.mainContext?.persistentStoreCoordinator = psc
        
        //MARK: - PersistentStore
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            let fileManager = FileManager.default
            
            guard let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("Failed to resolve documents directory.")
            }
            
            let storeURL = documentURL.appendingPathComponent("PPRecipes.sqlite")
            
            do {
                ///An NSPersistentStore is a representation of a location in which the data is saved/persisted.
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
            } catch {
                fatalError("Failed to initialize PSC: \(error)")
            }
        }
        
        ///Since we’ve completed this step on a background queue, it’s helpful to notify the UI that it’s ready to be used.
        DispatchQueue.main.sync {
            self.initializationComplete?()
        }
        
    }

}
