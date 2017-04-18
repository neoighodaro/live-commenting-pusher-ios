//
//  CommentsTableViewController.swift
//  showcaze
//
//  Created by Neo Ighodaro on 15/04/2017.
//  Copyright © 2017 CreativityKills Labs. All rights reserved.
//

import UIKit
import Alamofire
import PusherSwift

class CommentsTableViewController: UITableViewController {

    let MESSAGES_ENDPOINT = "https://live-commenting-ios-pusher.herokuapp.com/"

    var pusher: Pusher!

    var comments = [
        ["username": "John", "comment": "Amazing application nice!"],
        ["username": "Samuel", "comment": "How can I add a photo to my profile? This is longer than the previous comment."]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = 78;
        navigationItem.title = "View Comments"

        listenForNewComments()
        addComposeButtonToNavigationBar()
    }


    private func listenForNewComments() -> Void {
        pusher = Pusher(key: "PUSHER_API_KEY")
        let channel = pusher.subscribe("comments")
        let _ = channel.bind(eventName: "new_comment", callback: { (data: Any?) -> Void in
            if let data = data as? [String: AnyObject] {
                let comment = ["username":"Anonymous", "comment": (data["text"] as! String)]

                self.comments.insert(comment, at: 0)

                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                self.tableView.endUpdates()
            }
        })
        pusher.connect()
    }

    private func addComposeButtonToNavigationBar() -> Void {
        let button = UIBarButtonItem(barButtonSystemItem: .compose,
                                     target: self,
                                     action: #selector(buttonTapped))
        navigationItem.setRightBarButton(button, animated: false)
    }

    func buttonTapped() -> Void {
        let alert = UIAlertController(title: "Post",
                                      message: "Enter a comment and see it inserted in real time using Pusher",
                                      preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = nil
            textField.placeholder = "Enter comment"
        }

        alert.addAction(UIAlertAction(title: "Add Comment", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]

            if (textField?.hasText)! {
                self.postComment(comment: (textField?.text)!)
            }
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    private func postComment(comment: String) -> Void {
        Alamofire.request(MESSAGES_ENDPOINT, method: .post, parameters: ["comment": comment])
            .validate()
            .responseJSON { response in
                switch response.result {
                    case .success:
                        print("Posted successfully")
                    case .failure(let error):
                        print(error)
            }
        }
   }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentTableViewCell

        cell.username?.text = "👤 " + (comments[indexPath.row]["username"] ?? "Anonymous")
        cell.comment?.text  = comments[indexPath.row]["comment"]

        return cell
    }
}
