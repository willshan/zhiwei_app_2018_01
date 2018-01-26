//
//  FamilyList.swift
//  私家厨房
//
//  Created by Will.Shan on 24/01/2018.
//  Copyright © 2018 待定. All rights reserved.
//

import UIKit

class FamilyList: UITableViewController {

    var familyList = ["wife","mother","daughter","father","sister","brother"]
    var selectedIndexPath : IndexPath!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return familyList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()

        cell.textLabel?.text = familyList[indexPath.row]
        // Configure the cell...
        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedIndexPath = indexPath
        
        UIView.animate(withDuration: 0.3) {
            self.performSegue(withIdentifier: SegueID.showFamilyMember, sender: nil)
        }
    }
}

extension FamilyList

{
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case SegueID.showFamilyMember:
            
            guard let viewDetailVC = segue.destination as? FamilyMemberVC else {
                fatalError("Unexpected destination: \(segue.destination)")
            }

            let name = self.familyList[selectedIndexPath.row]
print(name)
            viewDetailVC.memberName = name

        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
}
