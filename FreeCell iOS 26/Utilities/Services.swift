import Foundation
import BackgroundTasks
import MessageUI

final class Services {
    var fileManager: any FileManagerType = FileManager.default
    var exporter: any ExporterType = Exporter()
    var dateType: any DateType.Type = Date.self
    var deckFactory: any DeckFactoryType = DeckFactory()
    var lifetime: any LifetimeType = Lifetime()
    var mailer: any MailerType = Mailer()
    var mailComposeViewControllerType: any MailComposeViewControllerType.Type = MFMailComposeViewController.self
    var persistence: any PersistenceType = Persistence()
    var stats: any StatsType = Stats()
    var taskScheduler: any TaskSchedulerType = BGTaskScheduler.shared
    var userDefaults: any UserDefaultsType = UserDefaults.standard
}
