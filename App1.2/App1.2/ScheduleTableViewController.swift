//
//  ScheduleTableViewController.swift
//  App1.2
//
//  Created by Bhai Jaiveer Singh on 7/27/17.
//  Copyright © 2017 Jaiveer. All rights reserved.
//

import UIKit

func stringToDate(str: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "HHmm"
    let date = formatter.date(from: str)
    return date!
}

class ScheduleTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
//    schedule is made up of events (profile + time)
    private var schedule = [(profile: Profile, time: Date)](){
        didSet {
            print(schedule)
        }
    }

    override func viewDidLoad() {
        print("here")
        super.viewDidLoad()
        let day: Profile = Profile(name: "Day", temperatureSP: 24, humiditySP: 60, light: 100, blue: 0)!
        let dayTime: Date = stringToDate(str: "0630")
        self.schedule.insert((profile: day, time: dayTime), at:0)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        print("here")
        return 1
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\(schedule.count)")
        return schedule.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath)

        // get the profile and time that is associated with this row
        // that the table view is asking us to provide a UITableViewCell for
        let profile: Profile = schedule[indexPath.row].profile
        let time: Date = schedule[indexPath.row].time
        
        cell.textLabel?.text = profile.name
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        cell.detailTextLabel?.text = formatter.string(from: time)
        
        return cell
    }
    
}
