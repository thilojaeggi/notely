import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    guard let url = URLContexts.first?.url else {
      super.scene(scene, openURLContexts: URLContexts)
      return
    }

    if url.scheme == "notely" {
      if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
        appDelegate.handleDeepLink(url.absoluteString)
      }
      return
    }

    super.scene(scene, openURLContexts: URLContexts)
  }
}
