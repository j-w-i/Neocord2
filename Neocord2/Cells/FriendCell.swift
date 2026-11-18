import UIKit
import SwiftcordLegacy
import UIKitExtensions
import UIKitCompatKit
import SFSymbolsCompatKit

class FriendCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    static let reuseID = "FriendCell"

    /// Avatars already resized to the cell's 40x40, keyed by user and avatar hash. Resizing on every configure
    /// kept a background thread busy while scrolling, which on a single-core iPod takes the main thread's time.
    private static let resizedAvatars = NSCache<NSString, UIImage>()

    private var friendAvatar: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 20
        iv.layer.masksToBounds = true
        return iv
    }()
    
    private var friendName: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 17)
        lbl.textColor = .white
        lbl.backgroundColor = .clear
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private var backgroundGlass: UIView? = {
        let bg = UIView()
        bg.layer.cornerRadius = 22
        bg.translatesAutoresizingMaskIntoConstraints = false
        return bg
    }()
    
    private var stack: UIStackView = {
        let st = UIStackView()
        st.axis = .horizontal
        st.spacing = 8
        st.alignment = .center
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()
    
    private var friend: User?
    
    var presenceUpdateObserver: NSObjectProtocol?
    
    private lazy var presenceIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = presenceColor
        view.layer.cornerRadius = 6
        return view
    }()

    private var presenceColor: UIColor = .offlineGray
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        addTapGesture()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupViews() {
        guard let backgroundGlass = backgroundGlass else {
            return
        }

        contentView.addSubview(backgroundGlass)
        contentView.addSubview(stack)
        stack.addArrangedSubview(friendAvatar)
        stack.addArrangedSubview(friendName)
        contentView.addSubview(presenceIndicator)
        
        NSLayoutConstraint.activate([
            backgroundGlass.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundGlass.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundGlass.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundGlass.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            friendAvatar.widthAnchor.constraint(equalToConstant: 40),
            friendAvatar.heightAnchor.constraint(equalToConstant: 40),
            
            presenceIndicator.widthAnchor.constraint(equalToConstant: 12),
            presenceIndicator.heightAnchor.constraint(equalToConstant: 12),

            presenceIndicator.bottomAnchor.constraint(equalTo: friendAvatar.bottomAnchor),
            presenceIndicator.trailingAnchor.constraint(equalTo: friendAvatar.trailingAnchor)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        removePresenceObserver()
        presenceColor = .offlineGray
        updatePresenceIndicatorColor()
        friendAvatar.image = nil
        friendName.text = nil
        friend = nil
    }

    deinit {
        if let observer = self.presenceUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        self.presenceUpdateObserver = nil
    }
    
    private func updatePresenceIndicatorColor() {
        presenceIndicator.backgroundColor = presenceColor
    }

    /// Each configure registers a presence observer. Without this, every reuse left the previous one registered
    /// and every PRESENCE_UPDATE ran one closure per cell ever configured.
    private func removePresenceObserver() {
        if let observer = presenceUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
            presenceUpdateObserver = nil
        }
    }

    func configure(with user: User) {
        self.friendName.text = user.nickname ?? user.displayname ?? user.username
        self.friend = user
        
        let presence = activeClient.presences[user.id!] ?? .offline
        presenceColor = PresenceColor.color(for: presence)
        updatePresenceIndicatorColor()

        removePresenceObserver()
        presenceUpdateObserver = NotificationCenter.default.addObserver(forName: .presenceUpdate, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            if let presenceDict = notification.object as? [Snowflake: PresenceType], let updatedPresence = presenceDict[user.id!] {
                self.presenceColor = PresenceColor.color(for: updatedPresence)
                DispatchQueue.main.async {
                    if self.friend?.id == user.id {
                        self.updatePresenceIndicatorColor()
                    }
                }
            }
        }
        
        let resizedKey = "\(String(describing: user.id))-\(user.avatarString ?? "default")" as NSString
        if let cached = FriendCell.resizedAvatars.object(forKey: resizedKey) {
            friendAvatar.image = cached
            return
        }

        AvatarCache.shared.avatar(for: user) { [weak self] image, color in

            DispatchQueue.global(qos: .userInitiated).async {

                guard let self = self else { return }

                if let image = image, let color = color {
                    let resized = image.resizeImage(image, targetSize: CGSize(width: 40, height: 40))
                    FriendCell.resizedAvatars.setObject(resized, forKey: resizedKey)

                    DispatchQueue.main.async {
                        // The cell may have been reused for someone else while this ran.
                        if self.friend?.id == user.id {
                            self.friendAvatar.image = resized
                        }
                    }
                } else {
                    let defaultPFP = UIImage(named: "defaultavatar")!
                    let resized = defaultPFP.resizeImage(defaultPFP, targetSize: .init(width: 40, height: 40))
                    DispatchQueue.main.async {
                        if self.friend?.id == user.id {
                            self.friendAvatar.image = resized
                        }
                    }
                }
            }
        }
    }
    
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileClick(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc func profileClick(_ gesture: UITapGestureRecognizer) {
        if #available(iOS 10.0, *) {
            let haptic = UISelectionFeedbackGenerator()
            haptic.selectionChanged()
        }
        if let textVC = self.parentViewController as? ViewController {
            if let friend = self.friend {
                textVC.presentProfileView(for: friend)
            }
        }
    }
}
