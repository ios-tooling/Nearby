//
//  NearbyStatusView.swift
//  Nearby_iOS
//
//  Created by Ben Gottlieb on 9/10/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import UIKit

public class NearbyStatusView: UIView {
	var configured = false
	
	public var parentViewController: UIViewController?
	
	override public func didMoveToSuperview() {
		super.didMoveToSuperview()
		
		if self.configured { return }
		
		self.configured = true
		NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NearbyDevice.Notifications.deviceChangedInfo, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NearbyDevice.Notifications.deviceDisconnected, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NearbyDevice.Notifications.deviceConnected, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NearbyDevice.Notifications.deviceStateChanged, object: nil)
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
			self.showsTouchWhenHighlighted = true
			self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
		}
		
		@objc func tapped() {
			guard let device = self.device else { return }
			
			var message = ""
			for (key, value) in device.discoveryInfo ?? [:] {
				message += "\(key): \(value)\n"
			}
			message += "State: \(device.state.description)"
			
			let alert = UIAlertController(title: device.displayName, message: message, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			(self.superview as? NearbyStatusView)?.parentViewController?.present(alert, animated: true, completion: nil)
		}
		
		func update() {
			guard let device = self.device else { return }
			self.setTitle("   \(device.displayName)   ", for: .normal)
			self.setTitleColor(device.state.contrastingColor, for: .normal)
			self.backgroundColor = device.state.color
			self.layer.borderColor = device.state.contrastingColor.cgColor
			self.layer.cornerRadius = 15
			self.layer.borderWidth = 1
		}
	}
}
