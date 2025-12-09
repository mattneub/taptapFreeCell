import UIKit

final class ExportViewController: UIViewController, ReceiverPresenter {
    weak var processor: (any Receiver<ExportAction>)?

    lazy var exportLabel = UILabel().applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = UIFont.systemFont(ofSize: 17)
        $0.numberOfLines = 0
    }

    lazy var importLabel = UILabel().applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = UIFont.systemFont(ofSize: 17)
        $0.numberOfLines = 0
    }

    lazy var cancelButton1 = UIButton(configuration: .bordered()).applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.configuration?.title = "Cancel"
        $0.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            $0.font(UIFont.systemFont(ofSize: 15))
        }
        $0.addTarget(self, action: #selector(doCancel), for: .primaryActionTriggered)
    }

    lazy var exportButton = UIButton(configuration: .bordered()).applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.configuration?.title = "Export"
        $0.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            $0.font(UIFont.systemFont(ofSize: 15))
        }
        $0.addTarget(self, action: #selector(doExport), for: .primaryActionTriggered)
    }

    lazy var cancelButton2 = UIButton(configuration: .bordered()).applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.configuration?.title = "Cancel"
        $0.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            $0.font(UIFont.systemFont(ofSize: 15))
        }
        $0.addTarget(self, action: #selector(doCancel), for: .primaryActionTriggered)
    }

    lazy var importButton = UIButton(configuration: .bordered()).applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.configuration?.title = "Import and Deal"
        $0.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            $0.font(UIFont.systemFont(ofSize: 15))
        }
        $0.addTarget(self, action: #selector(doImportAndDeal), for: .primaryActionTriggered)
    }

    lazy var textView = UITextView().applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = UIFont.systemFont(ofSize: 14)
    }

    lazy var scrollView = UIScrollView().applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.keyboardDismissMode = .interactive
    }

    lazy var contentView = UIView().applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
        ])
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).activate()
        contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).activate(priority: 100)
        contentView.addSubview(exportLabel)
        NSLayoutConstraint.activate([
            exportLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            exportLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            exportLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
        contentView.addSubview(cancelButton1)
        NSLayoutConstraint.activate([
            cancelButton1.topAnchor.constraint(equalTo: exportLabel.bottomAnchor, constant: 16),
            cancelButton1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
        ])
        contentView.addSubview(exportButton)
        NSLayoutConstraint.activate([
            exportButton.topAnchor.constraint(equalTo: exportLabel.bottomAnchor, constant: 16),
            exportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
        contentView.addSubview(importLabel)
        NSLayoutConstraint.activate([
            importLabel.topAnchor.constraint(equalTo: exportLabel.bottomAnchor, constant: 80),
            importLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            importLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
        contentView.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: importLabel.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            textView.heightAnchor.constraint(equalToConstant: 150)
        ])
        contentView.addSubview(cancelButton2)
        NSLayoutConstraint.activate([
            cancelButton2.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            cancelButton2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
        ])
        contentView.addSubview(importButton)
        NSLayoutConstraint.activate([
            importButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            importButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            importButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
        Task {
            await processor?.receive(.initialData)
        }
    }

    func present(_ state: ExportState) async {
        exportLabel.text = state.exportText
        importLabel.text = state.importText
    }

    @objc func doCancel() {
        Task {
            await processor?.receive(.cancel)
        }
    }

    @objc func doImportAndDeal() {
        Task {
            await processor?.receive(.import(textView.text))
        }
    }

    @objc func doExport() {
        Task {
            await processor?.receive(.export)
        }
    }
}
