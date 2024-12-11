import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let containerName = "voyager"
    private let messageEntityName = "LocalChatMessages"
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: containerName)
        
        // 配置存储选项
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = NSSQLiteStoreType
        
        // 获取应用程序的 Documents 目录
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = urls[0]
        let storeURL = docURL.appendingPathComponent("\(containerName).sqlite")
        storeDescription.url = storeURL
        
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        // 启用自动合并更改
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Message Operations
    
    func saveMessage(_ message: ChatMessage) throws {
        let entity = NSEntityDescription.entity(forEntityName: messageEntityName, in: context)!
        let localMessage = NSManagedObject(entity: entity, insertInto: context)
        
        localMessage.setValue(message.id, forKey: "id")
        localMessage.setValue(message.msg.chatID, forKey: "chatId")
        localMessage.setValue(message.msg.userID, forKey: "userId")
        localMessage.setValue(message.msg.roleID, forKey: "roleId")
        localMessage.setValue(message.msg.message, forKey: "message")
        localMessage.setValue(message.type.rawValue, forKey: "messageType")
        localMessage.setValue(message.statusInt, forKey: "status")
        localMessage.setValue(message.msg.timestamp, forKey: "ctime")
        localMessage.setValue(message.mediaURL, forKey: "mediaURL")
        //localMessage.setValue(message.localMediaPath, forKey: "localMediaPath")
        localMessage.setValue(true, forKey: "isFromServer")
        localMessage.setValue(message.uuid?.uuidString, forKey: "uuid")
        try context.save()
    }
    
    func savePendingMessage(_ message: ChatMessage) throws {
        let entity = NSEntityDescription.entity(forEntityName: messageEntityName, in: context)!
        let localMessage = NSManagedObject(entity: entity, insertInto: context)
        localMessage.setValue(message.id, forKey: "id")
        localMessage.setValue(message.msg.chatID, forKey: "chatId")
        localMessage.setValue(message.msg.userID, forKey: "userId")
        localMessage.setValue(message.msg.roleID, forKey: "roleId")
        localMessage.setValue(message.msg.message, forKey: "message")
        localMessage.setValue(message.type.rawValue, forKey: "messageType")
        localMessage.setValue(message.statusInt, forKey: "status")
        localMessage.setValue(message.msg.timestamp, forKey: "ctime")
        localMessage.setValue(message.mediaURL, forKey: "mediaURL")
        //localMessage.setValue(message.localMediaPath, forKey: "localMediaPath")
        localMessage.setValue(true, forKey: "isFromServer")
        localMessage.setValue(message.uuid?.uuidString, forKey: "uuid")
        
        try context.save()
    }
    
    func updateMessageStatus(id: Int64, status: MessageStatus) throws {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: messageEntityName)
        fetchRequest.predicate = NSPredicate(format: "id == %lld", id)
        
        if let message = try context.fetch(fetchRequest).first {
            message.setValue(status.rawValue, forKey: "status")
            try context.save()
        }
    }
    
    func updateMessageStatusByUUID(uuid: String,id:Int64,status: MessageStatus) throws {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: messageEntityName)
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid)
        
        if let message = try context.fetch(fetchRequest).first {
            message.setValue(status.rawValue, forKey: "status")
            message.setValue(id, forKey: "id")
            try context.save()
        }
    }
    
    func fetchMessages(chatId: Int64, limit: Int = 100) throws -> [ChatMessage] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: messageEntityName)
        fetchRequest.predicate = NSPredicate(format: "chatId == %lld", chatId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "ctime", ascending: true)]
        fetchRequest.fetchLimit = limit
        
        let results = try context.fetch(fetchRequest)
        return results.map { managedObject in
            // 将 CoreData 对象转换为 ChatMessage
            convertToMessage(managedObject)
        }
    }
    
    func fetchRecentMessages(chatId: Int64, days: Int = 7) throws -> [ChatMessage] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: messageEntityName)
        let calendar = Calendar.current
        let startTimeStamp = Int64(calendar.date(byAdding: .day, value: -days, to: Date())?.timeIntervalSince1970 ?? 0)
        
        fetchRequest.predicate = NSPredicate(format: "chatId == %lld AND ctime >= %lld", chatId, startTimeStamp)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "ctime", ascending: true)]
        
        let results = try context.fetch(fetchRequest)
        return results.map { convertToMessage($0) }
    }
    
    func cleanupOldMessages(olderThan days: Int = 7) throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: messageEntityName)
        let calendar = Calendar.current
        let oldTimeStamp = Int64(calendar.date(byAdding: .day, value: -days, to: Date())?.timeIntervalSince1970 ?? 0)
        
        fetchRequest.predicate = NSPredicate(format: "ctime < %lld", oldTimeStamp)
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try persistentContainer.persistentStoreCoordinator.execute(batchDeleteRequest, with: context) as? NSBatchDeleteResult
        
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertToMessage(_ managedObject: NSManagedObject) -> ChatMessage {
        var chatMsg = Common_ChatMessage()
        chatMsg.chatID = managedObject.value(forKey: "chatId") as! Int64
        chatMsg.userID = managedObject.value(forKey: "userId") as! Int64
        chatMsg.roleID = managedObject.value(forKey: "roleId") as! Int64
        chatMsg.message = managedObject.value(forKey: "message") as! String
        chatMsg.timestamp = managedObject.value(forKey: "ctime") as! Int64
        let msgItem = ChatMessage(
            id: managedObject.value(forKey: "id") as! Int64,
            msg: chatMsg,
            status: .MessageSendSuccess
        )
        msgItem.type = MessageType(rawValue: Int64(managedObject.value(forKey: "messageType") as! Int)) ?? .MessageTypeText
        if let mediaURL = managedObject.value(forKey: "mediaURL") as? String {
            msgItem.mediaURL = mediaURL
        }
        if let uuid = managedObject.value(forKey: "uuid") as? String {
            msgItem.uuid = UUID(uuidString: uuid)
        }
        return msgItem 
    }

    func debugPrintAllMessages() {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: messageEntityName)
        do {
            let results = try context.fetch(fetchRequest)
            print("Total messages in database: \(results.count)")
            if results.isEmpty {
                print("Database is empty. Checking store URL...")
                if let storeURL = persistentContainer.persistentStoreDescriptions.first?.url {
                    print("Store URL: \(storeURL)")
                    let fileExists = FileManager.default.fileExists(atPath: storeURL.path)
                    print("Database file exists: \(fileExists)")
                }
            }
            for (index, message) in results.enumerated() {
                print("Message \(index):")
                print("- id: \(message.value(forKey: "id") ?? "nil")")
                print("- chatId: \(message.value(forKey: "chatId") ?? "nil")")
                print("- message: \(message.value(forKey: "message") ?? "nil")")
                print("- timestamp: \(message.value(forKey: "ctime") ?? "nil")")
                print("------------------------")
            }
        } catch {
            print("Debug print failed: \(error)")
        }
    }
} 
