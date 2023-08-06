//
//  NearbyStatusView.swift
//  Nearby_iOS
//
//  Created by Ben Gottlieb on 9/10/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class NearbyStatusView: UIView {
	var configured = false
	
	public var parentViewController: UIViewController?
	
	var reloadButton: UIButton!
	
	override public func didMoveToSuperview() {
		super.didMoveToSuperview()
		
		if self.configured { return }
		
		self.reloadButton = UIButton(type: .custom)
		self.reloadButton.setTitle("↺", for: .normal)
		self.reloadButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 23)
		self.reloadButton.setTitleColor(.blue, for: .normal)
		let size: CGFloat = 44
		self.reloadButton.frame = CGRect(x: self.bounds.width - size, y: self.bounds.height - size, width: size, height: size)
		self.addSubview(self.reloadButton)
		self.reloadButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
		self.reloadButton.addTarget(self, action: #selector(reloadTapped), for: .touchUpInside)
		
		self.configured = true
		NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NearbyDevice.Notifications.deviceChangedInfo, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NearbyDevice.Notifications.deviceDisconnected, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NearbyDevice.Notifications.deviceConnected, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NearbyDevice.Notifications.deviceChangedState, object: nil)
	}
	
	@objc func reloadTapped() {
		self.updateUI()
	}
	
	var buttons: [DeviceButton] = []
	
	func button(for device: NearbyDevice) -> DeviceButton? {
		for button in self.buttons { if button.device == device { return button }}
		return nil
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		let contentFrame = self.bounds.insetBy(dx: 5, dy: 5)
		var left: CGFloat = contentFrame.minX
		var top: CGFloat = contentFrame.minY
		let rowHeight: CGFloat = 30
		let spacing: CGFloat = 2
		
		for button in self.buttons {
			let size = button.bounds.size
			if left > contentFrame.origin.x, (left + size.width) > contentFrame.maxX {
				top += rowHeight + spacing
				left = contentFrame.minX
			}
			button.frame = CGRect(x: left, y: top, width: size.width, height: rowHeight)
			left += size.width + spacing
		}
	}
	
	@objc func updateUI() {
		
		for device in NearbySession.instance.devices.values {
			if let button = self.button(for: device) {
				button.update()
				continue
			}
			
			let button = DeviceButton(device: device)
			button.sizeToFit()
			self.buttons.append(button)
			self.addSubview(button)
		}
	}
}

extension NearbyStatusView {
	class DeviceButton: UIButton {
		var device: NearbyDevice?
		
		convenience init(device: NearbyDevice) {
			self.init(type: .custom)
			self.device = device
			self.update()
			self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
			self.layer.borderColor = UIColor.black.cgColor
			self.layer.cornerRadius = 15
			self.layer.borderWidth = 1
		}
		
		@objc func tapped() {
			guard let device = self.device else { return }
			
			var message = ""
			for (key, value) in device.discoveryInfo ?? [:] {
				message += "\(key): \(value)\n"
			}
			
			for (key, value) in device.deviceInfo ?? [:] {
				message += "\(key): \(value.description.trimmed(to: 20))\n"
			}
			message += "State: \(device.state.description)\n"
			message += "MCState: \(device.lastReceivedSessionState.description)";
			
			let alert = UIAlertController(title: device.name, message: message, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			alert.addAction(UIAlertAction(title: "Send Connected", style: .default, handler: { _ in
				NearbyDevice.Notifications.deviceConnected.post(with: device)
			}))
			alert.addAction(UIAlertAction(title: "Send Provisioned", style: .default, handler: { _ in
				NearbyDevice.Notifications.deviceProvisioned.post(with: device)
			}))

			(self.superview as? NearbyStatusView)?.parentViewController?.present(alert, animated: true, completion: nil)
		}
		
		func update() {
			guard let device = self.device else {
				self.alpha = 0.2
				return
			}
			self.alpha = 1.0
			self.setTitle("   \(device.name)   ", for: .normal)
			self.setTitleColor(device.state.contrastingColor, for: .normal)
			self.backgroundColor = device.stateColor
		}
	}
}

extension String {
	func trimmed(to length: Int) -> String {
		if self.count > length { return String(self[...self.index(self.startIndex, offsetBy: length)]) }
		return self
	}
}
#endif
