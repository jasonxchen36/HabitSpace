import Foundation
import CoreData

@objc(HabitCompletion)
public class HabitCompletion: NSManagedObject, Identifiable {
    public var wrappedId: UUID { id ?? UUID() }
    public var wrappedTimestamp: Date { timestamp ?? Date() }
    public var wrappedNotes: String { notes ?? "" }
}

extension HabitCompletion {
    static var preview: HabitCompletion {
        let completion = HabitCompletion(context: CoreDataManager.preview.container.viewContext)
        completion.id = UUID()
        completion.timestamp = Date()
        completion.notes = "Great job!"
        return completion
    }
}
