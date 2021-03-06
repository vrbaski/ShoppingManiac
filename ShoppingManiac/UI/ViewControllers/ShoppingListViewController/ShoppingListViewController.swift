//
//  ShoppingListViewController.swift
//  ShoppingManiac
//
//  Created by Dmitry Matyushkin on 21/05/2017.
//  Copyright © 2017 Dmitry Matyushkin. All rights reserved.
//

import UIKit
import CoreStore
import MessageUI
import SwiftyBeaver
import CloudKit
import RxSwift
import RxCocoa
import PKHUD

class ShoppingListViewController: ShoppingManiacViewController, UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate, UICloudSharingControllerDelegate, UpdateDelegate {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var totalLabel: UILabel!
    @IBOutlet private weak var shareButton: UIButton!
    
    let model = ShoppingListModel()
    private let cloudShare = CloudShare(cloudKitUtils: CloudKitUtils(operations: CloudKitOperations(), storage: CloudKitTokenStorage()))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.model.shoppingList == nil {
            self.model.setLatestList()
        }
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.setBottomInset(inset: 70)
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.model.delegate = self
        self.model.totalText.asObservable().observeOnMain().bind(to: self.totalLabel.rx.text).disposed(by: self.model.disposeBag)
        self.model.reloadData()
        if let controllers = self.navigationController?.viewControllers {
            self.navigationController?.viewControllers = controllers.filter({!($0 is AddShoppingListViewController)})
        }
    }
    
    func reloadData() {
        self.tableView.reloadData()
    }
    
    func moveRow(fromPath: IndexPath, toPath: IndexPath) {
        UIView.animate(withDuration: 0.5, animations: {[weak self] () -> Void in
            self?.tableView.moveRow(at: fromPath, to: toPath)
        }, completion: {[weak self] (_) -> Void in
            self?.tableView.reloadRows(at: [fromPath, toPath], with: UITableView.RowAnimation.none)
        })
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        self.tableView.setEditing(editing, animated: animated)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.model.sectionsCount()
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model.rowsCount(forSection: section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell: ShoppingListTableViewCell = tableView.dequeueCell(indexPath: indexPath) {
            cell.setup(withItem: self.model.item(forIndexPath: indexPath))
            return cell
        } else {
            fatalError()
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.model.sectionTitle(forSection: section)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.model.sectionTitle(forSection: section) == nil ? 0.01 : 44
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.model.togglePurchased(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let item = self.model.item(forIndexPath: indexPath)
        let deleteAction = UITableViewRowAction(style: UITableViewRowAction.Style.default, title: "Delete") { [weak self] _, _ in
            let alertController = UIAlertController(title: "Delete purchase", message: "Are you sure you want to delete \(item.itemName) from your purchase list?", confirmActionTitle: "Delete") {[weak self] in
				guard let self = self else { return }
                self.tableView.isEditing = false
				self.model.removeItem(from: indexPath)
            }
            self?.present(alertController, animated: true, completion: nil)
        }
        deleteAction.backgroundColor = UIColor.red
        let editAction = UITableViewRowAction(style: UITableViewRowAction.Style.default, title: "Edit") { [weak self] _, indexPath in
            tableView.isEditing = false
            self?.performSegue(withIdentifier: "editShoppingListItemSegue", sender: indexPath)
        }
        editAction.backgroundColor = UIColor.gray

        return [deleteAction, editAction]
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.section != destinationIndexPath.section {
            self.model.moveItem(from: sourceIndexPath, toGroup: destinationIndexPath.section)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addShoppingListItemSegue", let destination = segue.destination as? AddShoppingItemViewController {
            destination.model.shoppingList = self.model.shoppingList
        } else if segue.identifier == "editShoppingListItemSegue", let indexPath = sender as? IndexPath, let destination = segue.destination as? AddShoppingItemViewController {
            let item = self.model.item(forIndexPath: indexPath)
            destination.model.shoppingListItem = CoreStoreDefaults.dataStack.fetchExisting(item.objectId)
            destination.model.shoppingList = self.model.shoppingList
        }
    }

    @IBAction private func shoppingList(unwindSegue: UIStoryboardSegue) {
        if unwindSegue.identifier == "addShoppingItemSaveSegue" {
            self.model.resyncData()
        }
    }

    @IBAction private func shareAction(_ sender: Any) {
        if AppDelegate.discoverabilityStatus {
            let controller = UIAlertController(title: "Sharing", message: "Select sharing type", preferredStyle: .actionSheet)
            let smsAction = UIAlertAction(title: "Text message", style: .default) {[weak self] _ in
                self?.smsShare()
            }
            let icloudAction = UIAlertAction(title: "iCloud", style: .default) {[weak self] _ in
                self?.icloudShare()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in

            }
            controller.addAction(smsAction)
            controller.addAction(icloudAction)
            controller.addAction(cancelAction)
            controller.popoverPresentationController?.sourceView = self.shareButton
            controller.popoverPresentationController?.sourceRect = self.shareButton.frame
            self.present(controller, animated: true, completion: nil)
        } else {
            self.smsShare()
        }
    }

    private func smsShare() {
        if MFMessageComposeViewController.canSendText() {
            let picker = MFMessageComposeViewController()
            picker.messageComposeDelegate = self
            picker.body = self.model.shoppingList.textData()
            if MFMessageComposeViewController.canSendAttachments() {
                if let data = self.model.shoppingList.jsonData() {
                    picker.addAttachmentData(data as Data, typeIdentifier: "public.json", filename: "\(self.model.shoppingList.title).smstorage")
                }
            }
            self.present(picker, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Error", message: "Unable to send text messages from this device", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Close", style: .default) { _ in
                alert.dismiss(animated: true)
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func icloudShare() {
        HUD.show(.labeledProgress(title: "Creating share", subtitle: nil))
        self.cloudShare.shareList(list: self.model.shoppingList).observeOnMain().subscribe(onNext: self.createSharingController, onError: self.showSharingError).disposed(by: self.model.disposeBag)
    }
    
    private func createSharingController(share: CKShare) {
        let controller = UICloudSharingController(share: share, container: CKContainer.default())
        controller.delegate = self
        controller.availablePermissions = [.allowReadWrite, .allowPublic]
        controller.popoverPresentationController?.sourceView = self.shareButton
        controller.popoverPresentationController?.sourceRect = self.shareButton.frame
        HUD.hide()
        self.present(controller, animated: true, completion: nil)
    }
    
    private func showSharingError(error: Error) {
        HUD.flash(.labeledError(title: "iCloud sharing error", subtitle: error.localizedDescription), delay: 3)
    }
    
    // MARK: - Cloud sharing controller delegate
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        AppDelegate.showAlert(title: "Cloud sharing", message: error.localizedDescription)
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return "Shopping list"
    }

    // MARK: - MFMessageComposeViewControllerDelegate

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
