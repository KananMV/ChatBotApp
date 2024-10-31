import UIKit
import SnapKit

class MessageCell: UITableViewCell {
    
    let messageContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logologo")
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    func configure(with message: Message) {
        messageLabel.text = message.textChunks.joined()
        messageContainerView.backgroundColor = message.isSentByUser ? .systemBlue : UIColor(hex: "#243639")
        messageLabel.textAlignment = message.isSentByUser ? .left : .left
        logoImageView.isHidden = message.isSentByUser
        
        setupLayout(isSentByUser: message.isSentByUser)
    }
    
    private func setupLayout(isSentByUser: Bool) {
        messageContainerView.removeFromSuperview()
        messageLabel.removeFromSuperview()
        logoImageView.removeFromSuperview()
        
        contentView.addSubview(messageContainerView)
        messageContainerView.addSubview(messageLabel)
        
        if !isSentByUser {
            messageContainerView.addSubview(logoImageView)
            logoImageView.snp.remakeConstraints { make in
                make.leading.equalTo(messageContainerView.snp.leading)
                make.top.equalTo(messageContainerView.snp.top).offset(10)
                make.width.height.equalTo(24)
            }
            messageLabel.snp.remakeConstraints { make in
                make.leading.equalTo(logoImageView.snp.trailing).offset(8)
                make.trailing.equalTo(messageContainerView.snp.trailing).offset(-12)
                make.top.bottom.equalTo(messageContainerView).inset(12)
            }
        } else {
            messageLabel.snp.remakeConstraints { make in
                make.edges.equalTo(messageContainerView).inset(12)
            }
        }

        messageContainerView.snp.remakeConstraints { make in
            if isSentByUser {
                make.trailing.equalTo(contentView.snp.trailing).offset(-16)
                make.leading.greaterThanOrEqualTo(contentView.snp.leading).offset(100)
            } else {
                make.leading.equalTo(contentView.snp.leading).offset(16)
                make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-100)
            }
            make.top.equalTo(contentView.snp.top).offset(8)
            make.bottom.equalTo(contentView.snp.bottom).offset(-8)
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
