import UIKit
import SnapKit

class ChatViewController: UIViewController {
    var messages: [Message] = []
    var networkManager = NetworkManager.shared
    var textViewHeightConstraint: Constraint?

    lazy var messageTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.backgroundColor = .black
        tableView.backgroundView = imageIconView
        return tableView
    }()
    private let imageIconView: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "logo")
        image.contentMode = .scaleToFill
        return image
    }()
    
    lazy var messageTextField: UITextView = {
        let textField = UITextView()
        textField.tintColor = .white
        textField.delegate = self
        textField.layer.cornerRadius = 16
        textField.isScrollEnabled = false
        textField.textColor = .white
        textField.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 8, right: 10)
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.backgroundColor = .darkGray
        return textField
    }()
    
    lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "back")
        setupLayout()
        updateBackgroundView()
        
    }
    func updateBackgroundView() {
            if dataSourceIsEmpty() {
                messageTableView.backgroundView = imageIconView
            } else {
                messageTableView.backgroundView = nil
            }
        }
        
    func dataSourceIsEmpty() -> Bool {
        return messages.isEmpty
    }
    func setupLayout() {
        title = "ChatBot"
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.backgroundColor = UIColor(named: "back")
        view.addSubview(messageTableView)
        view.addSubview(messageTextField)
        view.addSubview(sendButton)
        view.addSubview(imageIconView)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        messageTableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(messageTextField.snp.top).offset(-8)
        }
        
        messageTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
            make.height.greaterThanOrEqualTo(40)
            
        }
        
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
            make.height.equalTo(40)
            make.width.equalTo(40)
        }
        imageIconView.snp.makeConstraints{make in
            make.width.height.equalTo(100)
            make.center.equalTo(messageTableView.snp.center)
        }
        
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            
            messageTextField.snp.updateConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-keyboardHeight+20)
            }
            sendButton.snp.updateConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-keyboardHeight+20)
            }
            
            if !messages.isEmpty {
                DispatchQueue.main.async {
                    self.messageTableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: false)
                }
            }
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        messageTextField.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
        
        sendButton.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func sendMessage() {
        guard let messageText = messageTextField.text, !messageText.isEmpty else { return }
        
        addMessage(textChunks: [messageText], isSentByUser: true)
        
        sendMessageToServer(messageText: messageText)
        messageTextField.text = ""
    }

    private func addMessage(textChunks: [String], isSentByUser: Bool) {
        let message = Message(textChunks: textChunks, isSentByUser: isSentByUser)
        messages.append(message)
        
        DispatchQueue.main.async {
            self.messageTableView.reloadData()
            self.scrollToBottom()
        }
    }

    private func scrollToBottom() {
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    private func sendMessageToServer(messageText: String) {
        let messageRequest = MessageRequest(message: messageText)
        networkManager.sendMessageWithStreaming(request: messageRequest, onChunkReceived: { [weak self] chunk in
            guard let self = self else { return }
            
            if var lastMessage = self.messages.last, !lastMessage.isSentByUser {
                lastMessage.textChunks.append(chunk)
            } else {
                self.addMessage(textChunks: [chunk], isSentByUser: false)
            }
            
            DispatchQueue.main.async {
                self.messageTableView.reloadData()
                self.scrollToBottom()
            }
            
        }, completion: { result in
            switch result {
            case .success:
                print("Message sent successfully")
            case .failure(let error):
                print("Error: \(error)")
            }
        })
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        updateBackgroundView()
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        cell.configure(with: message)
        cell.selectionStyle = .none
        return cell
    }
}

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let size = CGSize(width: textView.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        textViewHeightConstraint?.update(offset: estimatedSize.height)
        centerCurrentLineInTextView(textView)
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    private func centerCurrentLineInTextView(_ textView: UITextView) {
        guard let caretPosition = textView.selectedTextRange?.start else { return }
        let caretRect = textView.caretRect(for: caretPosition)
        let topOffset = (textView.bounds.height - caretRect.height) / 2
        let targetOffsetY = caretRect.origin.y - topOffset

        let maxOffsetY = max(0, min(targetOffsetY, textView.contentSize.height - textView.bounds.height))
        textView.setContentOffset(CGPoint(x: 0, y: maxOffsetY), animated: false)
    }
}
