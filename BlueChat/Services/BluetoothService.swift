//
//  BluetoothService.swift
//  BlueChat
//
//  Created by Korisnik on 11/04/2019.
//  Copyright © 2019 Josip Rezic. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothServiceDeviceDelegate: class {
    func bluetoothService(didChangePeripherals peripherals: [BluetoothDevice])
}

protocol BluetoothServiceMessageDelegate: class {
    func bluetoothService(didReceiveTextMessage message: String, fromPeripheral peripheral: BluetoothDevice)
}

class BluetoothDevice {
    let name: String
    let peripheral: CBPeripheral?
    
    init(name: String, peripheral: CBPeripheral? = nil) {
        self.name = name
        self.peripheral = peripheral
    }
}

class BluetoothService: NSObject {
    
    static let shared = BluetoothService()
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    weak var deviceDelegate: BluetoothServiceDeviceDelegate?
    weak var messageDelegate: BluetoothServiceMessageDelegate?
    
    private final var centralManager: CBCentralManager?
    private final var peripheralManager: CBPeripheralManager?
    private final var peripherals: [CBPeripheral] = []
    private final let serviceUUID: CBUUID = CBUUID(string: "D391A2A2-894D-4264-8B21-87D33F76B8C8") // generated by uuidgen
    
    private final let WR_UUID = CBUUID(string: "2C6FAC6E-E353-4AAF-87B9-E37AB409AF17") // generated by uuidgen
    private final let WR_PROPERTIES: CBCharacteristicProperties = .write
    private final let WR_PERMISSIONS: CBAttributePermissions = .writeable
    
    private final var writeCharacteristic: CBCharacteristic?
    
    
    private final func startScan() {
        debugPrint("Start scanning...")
        peripherals = []
        centralManager?.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    final func connect(toDevice device: BluetoothDevice?) {
        guard let peripheral = device?.peripheral else { return }
        centralManager?.connect(peripheral, options: nil)
    }
    
    final func sendMessage(message: String, toDevice: BluetoothDevice?) {
        let messageText = message
        guard let data = messageText.data(using: .utf8) else {print("Test 33"); return}
        guard let wc = writeCharacteristic else { print("Test 52"); return}
        peripherals[0].writeValue(data, for: wc, type: CBCharacteristicWriteType.withResponse)
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        debugPrint("centralManagerDidUpdateState:")
        switch central.state {
        case .unknown:
            debugPrint(".unknown")
        case .resetting:
            debugPrint(".resetting")
        case .unsupported:
            debugPrint(".unsupported")
        case .unauthorized:
            debugPrint(".unauthorized")
        case .poweredOff:
            debugPrint(".poweredOff")
        case .poweredOn:
            debugPrint(".poweredOn")
            startScan()
        @unknown default:
            debugPrint(".default")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        debugPrint("didDiscover peripheral: \(peripheral.name ?? "")")
        debugPrint("RSSI: \(RSSI.intValue)")
        peripherals.append(peripheral)
        
        let devices = peripherals.map({ peripheral -> BluetoothDevice in
            return BluetoothDevice(name: peripheral.name ?? "Device", peripheral: peripheral)
        })
        
        deviceDelegate?.bluetoothService(didChangePeripherals: devices)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
}

extension BluetoothService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        debugPrint("peripheralManagerDidUpdateState:")
        switch peripheral.state {
        case .unknown:
            debugPrint("unknown")
        case .resetting:
            debugPrint("resetting")
        case .unsupported:
            debugPrint("unsupported")
        case .unauthorized:
            debugPrint("unauthorized")
        case .poweredOff:
            debugPrint("poweredOff")
        case .poweredOn:
            debugPrint("poweredOn")
            //let advertisementData = String(format: "%@|%d|%d", "userData.name", "userData.avatarId", "userData.colorId")
            
            
            
            let serialService = CBMutableService(type: serviceUUID, primary: true)
            
            
            let writeCharacteristics = CBMutableCharacteristic(type: WR_UUID, properties: WR_PROPERTIES, value: nil, permissions: WR_PERMISSIONS)
            serialService.characteristics = [writeCharacteristics]
            peripheralManager?.add(serialService)
            peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[serviceUUID], CBAdvertisementDataLocalNameKey: "Jopara"])
        @unknown default:
            debugPrint("default")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("didReceiveWrite requests")
        for request in requests {
            if let value = request.value {
                let messageText = String(data: value, encoding: String.Encoding.utf8) as! String
                debugPrint("message text: \(messageText)")
                self.peripheralManager?.respond(to: request, withResult: .success)
                messageDelegate?.bluetoothService(didReceiveTextMessage: messageText, fromPeripheral: BluetoothDevice(name: "Some device"))
            }
        }
    }
}

extension BluetoothService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            let characteristic = characteristic as CBCharacteristic
            print("current UUID: \(characteristic.uuid.uuidString)")
            if characteristic.uuid.uuidString.isEqual(WR_UUID.uuidString) {
                if writeCharacteristic == nil {
                    self.writeCharacteristic = characteristic
                }
                sendMessage(message: "Test2", toDevice: nil)
                return
                
                let messageText = "Test message"
                guard let data = messageText.data(using: .utf8) else {print("Test 555"); return}
                peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
}
