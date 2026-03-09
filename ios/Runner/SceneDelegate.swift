import UIKit
import Flutter

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Create window for this scene
    window = UIWindow(windowScene: windowScene)
    
    // Use the FlutterViewController from AppDelegate's window
    if let existingWindow = appDelegate.window, let existingVC = existingWindow.rootViewController {
      window?.rootViewController = existingVC
      appDelegate.window = window
    }
    
    window?.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_ scene: UIScene) {
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
  }

  func sceneWillResignActive(_ scene: UIScene) {
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
  }
}
