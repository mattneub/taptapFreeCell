import Foundation
import BackgroundTasks
import MessageUI

final class Services {
    var bundle: any BundleType = Bundle.main
    var cleaner: any CleanerType = Cleaner()
    var fileManager: any FileManagerType = FileManager.default
    var exporter: any ExporterType = Exporter()
    var dateType: any DateType.Type = Date.self
    var deckFactory: any DeckFactoryType = DeckFactory()
    var lifetime: any LifetimeType = Lifetime()
    var mailer: any MailerType = Mailer()
    var mailComposeViewControllerType: any MailComposeViewControllerType.Type = MFMailComposeViewController.self
    var persistence: any PersistenceType = Persistence()
    var previewer: any PreviewerType = Previewer()
    var safariProvider: any SafariProviderType = SafariProvider()
    var stats: any StatsType = Stats()
    var taskScheduler: any TaskSchedulerType = BGTaskScheduler.shared
    var userDefaults: any UserDefaultsType = UserDefaults.standard
}
