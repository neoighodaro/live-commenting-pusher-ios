# How to build a live commenting feature in iOS using Pusher

Many applications come with a section where users can comment on the item they are previewing. When a comment is posted, while you are looking at this item, the best UX would be to see the comment immediately as it is made by the user. In this tutorial we would demonstrate how we can achieve this using Pusher on an iOS application.

We will be building a gallery viewing application with comments. You can then add your own comment to the item and it would be available instantly to other users looking at the item. For the sake of brevity, we will be building a very basic application and focusing more on the implementation than the design. When we are done, we should be able to achieve something like what's shown below:

![](https://dl.dropbox.com/s/p2ib69fitms7xwt/how-to-build-a-live-commenting-feature-in-ios-4.gif)

**Note: This is not an XCode or Swift tutorial so you will need some knowledge of XCode and Swift to follow this tutorial.**

### Setting up our XCode project

Create a new project on XCode and call it whatever you want. We will name ours "**showcaze**". You can simply follow the wizard XCode provides. Select the single page application as the base template. Once you are done with this, you will need to prepare the dependencies to be used by the application.

The easiest way install dependencies is by using CocoaPods. If you don’t have CocoaPods installed you can install them via RubyGems.

``` shell
gem install cocoapods
```
Then configure CocoaPods in our application. First initialise the project by running this command in the top-level directory of your XCode project:

``` shell
pod init
```
This will create a file called **Podfile**. Open it in your text editor, and make sure to add the following lines specifying your applications dependencies:

```
# Uncomment the next line to define a global platform for your project
platform :ios, '8.0'

target 'showcaze' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for showcaze
  pod 'PusherSwift', '~> 4.0'
  pod 'AlamofireImage', '~> 3.1'
end
```
And then run `pod install` to download and install the dependencies. When cocoapods asks you to, close XCode. Now open the `project_name.xcworkspace` file in the root of your project, in my case, the `showcaze.xcworkspace` file. This should launch XCode.

> Note: Because we are using the latest version of XCode which contains Swift 3, we are using specific dependency versions that are compatible with it. You might need to use a lower dependency version tag depending on your XCode and Swift version.

### Creating our Comments list view

We want to display the available comments and then allow people add comments to this list. When we are done we want to have a simple view just like this.

![](https://dl.dropbox.com/s/c0ld2pxmezk1gik/how-to-build-a-live-commenting-feature-in-ios-2.png)

Open the Main storyboard and delete the current `View Controller` scene. Drag a new `UITableViewController` into the scene. Create a `CommentsTableViewController` and associate the newly created `View Controller` scene with it. Finally, while the view controller is selected in the storyboard, from XCode toolbar click **Editor > Embed In > Navigation Controller**.

After this, you should add the labels as needed to the prototype cell, add a reuse identifier and create a `CommentTableViewCell` class and make it the custom class for the prototype table cell.

This is the source of the `CommentTableViewCell`:

``` swift
import UIKit

class CommentTableViewCell: UITableViewCell {
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var comment: UITextView!
}
```
> Note there are two `@IBOutlet`s in the class. You need to create the cell label and text view then `Control + Drag` them to the `CommentTableViewCell` class to create IBOutlets.

This is the source of the `CommentsTableViewController`:

``` swift
import UIKit
import Alamofire
import PusherSwift

class CommentsTableViewController: UITableViewController {

    let MESSAGES_ENDPOINT = "http://live-commenting-ios.herokuapp.com/comment"

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
```
To highlight some important parts of the code, lets break a few down.

``` swift
    private func listenForNewComments() -> Void {
        pusher = Pusher(key: "PUSHER_API_KEY")
        let channel = pusher.subscribe("comments")
        let _ = channel.bind(eventName: "new_comment", callback: { (data: Any?) -> Void in
            if let data = data as? [String: AnyObject] {
                let text = data["text"] as! String
                self.comments.insert(text, at: 0)
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                self.tableView.endUpdates()
            }
        })
        pusher.connect()
    }
```
This function basically initialises the Pusher Swift SDK, subscribes to a channel `comments`, listens for an event `new_comment` and then fires a callback when that event is triggered from anywhere. In the callback, the text is appended to the top of the table data, then the `tableView` is updated with the new row.

``` swift
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
```
This block simply adds a compose button at the right of the navigation bar. It fires a `buttonTapped` callback when the button is…well…tapped. The `buttonTap` callback launches an alert view controller with a text field where the comment text is supposed to be entered into.

![](https://dl.dropbox.com/s/cdgarjizwbwtunv/how-to-build-a-live-commenting-feature-in-ios-3.png)

#### Connecting to Pusher

You can create a new Pusher account if you do not already have one. Create a new application and retrieve your keys. This is the key you will use above. When you have your keys, you can plug it above and also below in the back-end service.

### Building the back-end

Now that we have our application subscribed to the pusher event and also posting comments, we would have to build a backend to support it. For the backend, I have made a simple PHP script. It would be uploaded as a part of the repository. You would need to host somewhere if you wish to use the demo, we have chosen [Heroku](http://heroku.com) for this.

Here is our simple PHP script:

``` PHP
<?php
//
require('vendor/autoload.php');

$comment = $_POST['comment'] ?? false;

if ($comment) {
    $status = "success";

    $options = ['encrypted' => true];

    $pusher = new Pusher('PUSHER_API_KEY', 'PUSHER_API_SECRET', 'PUSHER_APP_ID', $options);

    $pusher->trigger('comments', 'new_comment', ['text' => $comment]);
} else {
    $status = "failure";
}

header('Content-Type: application/json');
echo json_encode(["result" => $status]);
```
Heres the `composer.json` file to install dependencies:

``` json
{
    "require": {
        "pusher/pusher-php-server": "^2.6"
    },
    "require-dev": {
      "heroku/heroku-buildpack-php": "*"
    }
}
```
The dev dependency is only useful if you are deploying the test script to Heroku, and heres the `Procfile` if you are:

``` yaml
web: vendor/bin/heroku-php-apache2 ./
```
Now that we have the server running, when ever you make a comment on the application, it will be sent to pusher and then the page will be updated with it.

### Conclusion

Hopefully, you have learnt a thing or two on how to use the Pusher iOS Swift SDK to make real-time updates to your iOS application. Have you done something great on your own, leave a comment below and share it with us.

The source code for the implementation above is available on GitHub [here](http://github.com/neoighodaro/live-commenting-pusher-ios). Star, fork it and play around with it.