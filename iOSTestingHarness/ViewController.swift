//
//  ViewController.swift
//  iOSTestingHarness
//
//  Created by Ben Gottlieb on 8/16/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
	@IBOutlet var tableView: UITableView!
	
	var devices: [NearbyDevice] = []
	
	@objc func reload( ){
		self.devices = Array(NearbySession.instance.devices.cachedDevices).sorted(by: { $0.displayName < $1.displayName })
		self.tableView.reloadData()
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NearbyDevice.Notifications.deviceConnected, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NearbyDevice.Notifications.deviceDisconnected, object: nil)
		// Do any additional setup after loading the view, typically from a nib.
	}


}

extension ViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.devices.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
		
		cell.textLabel?.text = "\(self.devices[indexPath.row].displayName) - \(self.devices[indexPath.row].state)"
		return cell
	}
}

extension ViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		print("Device: \(devices[indexPath.row])")
		self.devices[indexPath.row].connect()
	}
}

