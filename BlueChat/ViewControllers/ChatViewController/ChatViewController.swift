//
//  ChatViewController.swift
//  BlueChat
//
//  Created by Korisnik on 11/04/2019.
//  Copyright © 2019 Josip Rezic. All rights reserved.
//

import UIKit
import CoreBluetooth

class ChatViewController: UIViewController {

    var periferal: CBPeripheral?
    var messages = [String]()
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        BluetoothService.shared.messageDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.addSubview(tableView)
        tableView.frame = view.frame
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = messages[indexPath.row]
        return cell
    }
}

extension ChatViewController: BluetoothServiceMessageDelegate {
    func bluetoothService(didReceiveTextMessage message: String, fromPeripheral peripheral: BluetoothDevice) {
        messages.append(message)
        tableView.reloadData()
    }
}
