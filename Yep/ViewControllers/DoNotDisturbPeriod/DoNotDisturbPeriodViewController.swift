//
//  DoNotDisturbPeriodViewController.swift
//  Yep
//
//  Created by NIX on 15/8/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class DoNotDisturbPeriodViewController: UIViewController {

    var doNotDisturbPeriod = DoNotDisturbPeriod()

    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!

    enum ActiveTime {
        case From
        case To
    }

    let max = Int(INT16_MAX)

    var activeTime: ActiveTime = .From {
        willSet {
            switch newValue {

            case .From:
                fromButton.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
                toButton.backgroundColor = UIColor.whiteColor()

                pickerView.selectRow(max / (2 * 24) * 24 + doNotDisturbPeriod.fromHour, inComponent: 0, animated: true)
                pickerView.selectRow(max / (2 * 60) * 60 + doNotDisturbPeriod.fromMinute, inComponent: 1, animated: true)

            case .To:
                fromButton.backgroundColor = UIColor.whiteColor()
                toButton.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)

                pickerView.selectRow(max / (2 * 24) * 24 + doNotDisturbPeriod.toHour, inComponent: 0, animated: true)
                pickerView.selectRow(max / (2 * 60) * 60 + doNotDisturbPeriod.toMinute, inComponent: 1, animated: true)
            }
        }
    }

    var isDirty = false {
        didSet {
            dirtyAction?(doNotDisturbPeriod)
        }
    }
    var dirtyAction: (DoNotDisturbPeriod -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Mute", comment: "")

        activeTime = .From

        updateFromButton()
        updateToButton()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        let info: JSONDictionary = [
            "mute_started_at_string": doNotDisturbPeriod.fromString,
            "mute_ended_at_string": doNotDisturbPeriod.toString,
        ]

        updateMyselfWithInfo(info, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            dispatch_async(dispatch_get_main_queue()) {
                YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Set Do Not Disturb failed!", comment: ""), inViewController: self)
            }

        }, completion: { success in

            dispatch_async(dispatch_get_main_queue()) {

                let realm = Realm()

                if let
                    myUserID = YepUserDefaults.userID.value,
                    me = userWithUserID(myUserID, inRealm: realm) {

                        var userDoNotDisturb = me.doNotDisturb

                        if userDoNotDisturb == nil {
                            let _userDoNotDisturb = UserDoNotDisturb()
                            _userDoNotDisturb.isOn = true

                            realm.write {
                                me.doNotDisturb = _userDoNotDisturb
                            }

                            userDoNotDisturb = _userDoNotDisturb
                        }

                        if let userDoNotDisturb = me.doNotDisturb {
                            realm.write {
                                userDoNotDisturb.fromHour = self.doNotDisturbPeriod.fromHour
                                userDoNotDisturb.fromMinute = self.doNotDisturbPeriod.fromMinute

                                userDoNotDisturb.toHour = self.doNotDisturbPeriod.toHour
                                userDoNotDisturb.toMinute = self.doNotDisturbPeriod.toMinute
                            }
                        }
                }
            }
        })
    }

    // MARK: - Actions

    func updateFromButton() {
        fromButton.setTitle(NSLocalizedString("From", comment: "") + " " + doNotDisturbPeriod.fromString, forState: .Normal)
    }

    func updateToButton() {
        toButton.setTitle(NSLocalizedString("To", comment: "") + " " + doNotDisturbPeriod.toString, forState: .Normal)
    }

    @IBAction func activeFrom() {
        activeTime = .From
    }

    @IBAction func activeTo() {
        activeTime = .To
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension DoNotDisturbPeriodViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return max
    }

    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 60
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {

        if component == 0 {
            return String(format: "%02d", row % 24)

        } else if component == 1 {
            return String(format: "%02d", row % 60)
        }

        return ""
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        switch activeTime {

        case .From:

            if component == 0 {
                doNotDisturbPeriod.fromHour = row % 24
            } else if component == 1 {
                doNotDisturbPeriod.fromMinute = row % 60
            }

            updateFromButton()

        case .To:
            if component == 0 {
                doNotDisturbPeriod.toHour = row % 24
            } else if component == 1 {
                doNotDisturbPeriod.toMinute = row % 60
            }

            updateToButton()
        }

        isDirty = true
    }
}

