import UIKit

/// Totally unnecessarily elaborate wrapper class, just so we can subclass it for testing
/// construction of the menu.
class MenuBuilderWrapper: UIMenuBuilder {
    func remove(action removedIdentifier: UIAction.Identifier) {
        builder?.remove(action: removedIdentifier)
    }

    func remove(menu removedIdentifier: UIMenu.Identifier) {
        builder?.remove(menu: removedIdentifier)
    }

    func insertElements(_ insertedElements: [UIMenuElement], beforeAction siblingIdentifier: UIAction.Identifier) {
        builder?.insertElements(insertedElements, beforeAction: siblingIdentifier)
    }

    func insertElements(_ insertedElements: [UIMenuElement], afterAction siblingIdentifier: UIAction.Identifier) {
        builder?.insertElements(insertedElements, afterAction: siblingIdentifier)
    }

    func insertElements(_ insertedElements: [UIMenuElement], beforeMenu siblingIdentifier: UIMenu.Identifier) {
        builder?.insertElements(insertedElements, beforeMenu: siblingIdentifier)
    }

    func insertElements(_ insertedElements: [UIMenuElement], afterMenu siblingIdentifier: UIMenu.Identifier) {
        builder?.insertElements(insertedElements, afterMenu: siblingIdentifier)
    }

    func insertElements(_ insertedElements: [UIMenuElement], atStartOfMenu siblingIdentifier: UIMenu.Identifier) {
        builder?.insertElements(insertedElements, atStartOfMenu: siblingIdentifier)
    }

    func insertElements(_ insertedElements: [UIMenuElement], atEndOfMenu siblingIdentifier: UIMenu.Identifier) {
        builder?.insertElements(insertedElements, atEndOfMenu: siblingIdentifier)
    }

    func replace(action replacedIdentifier: UIAction.Identifier, with replacementElements: [UIMenuElement]) {
        builder?.replace(action: replacedIdentifier, with: replacementElements)
    }

    func replace(menu replacedIdentifier: UIMenu.Identifier, with replacementElements: [UIMenuElement]) {
        builder?.replace(menu: replacedIdentifier, with: replacementElements)
    }

    func menu(for identifier: UIMenu.Identifier) -> UIMenu? {
        builder?.menu(for: identifier)
    }

    func replace(menu replacedIdentifier: UIMenu.Identifier, with replacementMenu: UIMenu) {
        builder?.replace(menu: replacedIdentifier, with: replacementMenu)
    }

    func action(for identifier: UIAction.Identifier) -> UIAction? {
        builder?.action(for: identifier)
    }

    func __command(forAction action: Selector, propertyList: Any?) -> UICommand? {
        builder?.__command(forAction: action, propertyList: propertyList)
    }

    func replaceChildren(ofMenu parentIdentifier: UIMenu.Identifier, from childrenBlock: ([UIMenuElement]) -> [UIMenuElement]) {
        builder?.replaceChildren(ofMenu: parentIdentifier, from: childrenBlock)
    }

    func __replaceCommand(forAction replacedAction: Selector, propertyList replacedPropertyList: Any?, with replacementElements: [UIMenuElement]) {
        builder?.__replaceCommand(forAction: replacedAction, propertyList: replacedPropertyList, with: replacementElements)
    }

    func insertSibling(_ siblingMenu: UIMenu, beforeMenu siblingIdentifier: UIMenu.Identifier) {
        builder?.insertSibling(siblingMenu, beforeMenu: siblingIdentifier)
    }

    func insertSibling(_ siblingMenu: UIMenu, afterMenu siblingIdentifier: UIMenu.Identifier) {
        builder?.insertSibling(siblingMenu, afterMenu: siblingIdentifier)
    }

    func insertChild(_ childMenu: UIMenu, atStartOfMenu parentIdentifier: UIMenu.Identifier) {
        builder?.insertChild(childMenu, atStartOfMenu: parentIdentifier)
    }

    func __insert(_ insertedElements: [UIMenuElement], beforeCommandForAction siblingAction: Selector, propertyList siblingPropertyList: Any?) {
        builder?.__insert(insertedElements, beforeCommandForAction: siblingAction, propertyList: siblingPropertyList)
    }

    func __insert(_ insertedElements: [UIMenuElement], afterCommandForAction siblingAction: Selector, propertyList siblingPropertyList: Any?) {
        builder?.__insert(insertedElements, afterCommandForAction: siblingAction, propertyList: siblingPropertyList)
    }

    func insertChild(_ childMenu: UIMenu, atEndOfMenu parentIdentifier: UIMenu.Identifier) {
        builder?.insertChild(childMenu, atEndOfMenu: parentIdentifier)
    }

    func __removeCommand(forAction removedAction: Selector, propertyList removedPropertyList: Any?) {
        builder?.__removeCommand(forAction: removedAction, propertyList: removedPropertyList)
    }

    let builder: (any UIMenuBuilder)?
    var system: UIMenuSystem { builder?.system ?? .main }
    init(builder: (any UIMenuBuilder)?) {
        self.builder = builder
    }
}
