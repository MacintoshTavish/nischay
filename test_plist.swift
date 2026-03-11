import Foundation
if let dict = NSDictionary(contentsOfFile: "/Users/himanshuyadav/Desktop/reverse engineer/Nischay/Sources/Nischay/Resources/Info.plist") {
    print("VALID XML!")
} else {
    print("INVALID XML!")
}
