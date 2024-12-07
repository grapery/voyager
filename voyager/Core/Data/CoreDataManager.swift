import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let containerName = "voyager"
    private let messageEntityName = "LocalChatMessage"
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
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
        localMessage.setValue(message.type, forKey: "messageType")
        localMessage.setValue(message.statusInt, forKey: "status")
        localMessage.setValue(Date(), forKey: "timestamp")
        localMessage.setValue(message.mediaURL, forKey: "mediaURL")
        //localMessage.setValue(message.localMediaPath, forKey: "localMediaPath")
        localMessage.setValue(true, forKey: "isFromServer")
        
        try context.save()
    }
    
    func savePendingMessage(_ message: ChatMessage) throws {
        let entity = NSEntityDescription.entity(forEntityName: messageEntityName, in: context)!
        let localMessage = NSManagedObject(entity: entity, insertInto: context)
        
        // 设置基本属性
        localMessage.setValue(message.id, forKey: "id")
        // ... 设置其他属性 ...
        localMessage.setValue(false, forKey: "isFromServer") // 标记为本地消息
        
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
    
    func fetchMessages(chatId: Int64, limit: Int = 100) throws -> [ChatMessage] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: messageEntityName)
        fetchRequest.predicate = NSPredicate(format: "chatId == %lld", chatId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
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
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        fetchRequest.predicate = NSPredicate(format: "chatId == %lld AND timestamp >= %@", chatId, startDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        let results = try context.fetch(fetchRequest)
        return results.map { convertToMessage($0) }
    }
    
    func cleanupOldMessages(olderThan days: Int = 7) throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: messageEntityName)
        let calendar = Calendar.current
        let oldDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        fetchRequest.predicate = NSPredicate(format: "timestamp < %@", oldDate as NSDate)
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try persistentContainer.persistentStoreCoordinator.execute(batchDeleteRequest, with: context)
    }
    
    // MARK: - Helper Methods
    
    private func convertToMessage(_ managedObject: NSManagedObject) -> ChatMessage {
        var chatMsg = Common_ChatMessage()
        chatMsg.chatID = managedObject.value(forKey: "chatId") as! Int64
        chatMsg.userID = managedObject.value(forKey: "userId") as! Int64
        chatMsg.roleID = managedObject.value(forKey: "roleId") as! Int64
        chatMsg.message = managedObject.value(forKey: "message") as! String
        
        let msgItem = ChatMessage(
            id: managedObject.value(forKey: "id") as! Int64,
            msg: chatMsg,
            status: managedObject.value(forKey: "status") as! MessageStatus
        )
        msgItem.type = managedObject.value(forKey: "messageType") as! MessageType
        msgItem.mediaURL = managedObject.value(forKey: "mediaURL") as? String
        //msgItem.localMediaPath = managedObject.value(forKey: "localMediaPath") as? String
        return msgItem 
    }
} 
