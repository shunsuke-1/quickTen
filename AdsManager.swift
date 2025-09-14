import Foundation
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport
import UIKit

enum AdUnitID {
    // ✅ テスト用（Google公式）
    static let interstitialTest = "ca-app-pub-3940256099942544/4411468910"
    // 🔁 本番用（あなたのID）に差し替えてOK
    static let interstitialProd = "ca-app-pub-6616707526225848/8720179188"
}

final class AdsManager: NSObject, FullScreenContentDelegate {
    static let shared = AdsManager()

    private var interstitial: InterstitialAd?
    private var onDismiss: (() -> Void)?
    private var allowPersonalized = true
    private var currentAdUnitID = AdUnitID.interstitialProd  // 開発中はテストを使う

    private override init() { super.init() }

    // 起動時に一度だけ呼ぶ
    func start(allowPersonalized: Bool, useProductionIDs: Bool = false, completion: (() -> Void)? = nil) {
        self.allowPersonalized = allowPersonalized
        self.currentAdUnitID = useProductionIDs ? AdUnitID.interstitialProd : AdUnitID.interstitialTest

        MobileAds.shared.start { _ in
            self.loadInterstitial()
            completion?()
        }
    }

    // ATT（必要なら）
    static func requestTrackingIfNeeded(_ completion: @escaping (ATTrackingManager.AuthorizationStatus)->Void) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                completion(status)
            }
        } else {
            completion(.authorized)
        }
    }

    var isReady: Bool { interstitial != nil }

    func loadInterstitial() {
        let request = Request()
        if !allowPersonalized {
            let extras = Extras()
            extras.additionalParameters = ["npa": "1"]  // 非パーソナライズ
            request.register(extras)
        }

        InterstitialAd.load(with: currentAdUnitID, request: request) { [weak self] ad, error in
            guard let self else { return }
            if let error = error {
                print("Interstitial load error:", error.localizedDescription)
                self.interstitial = nil
                return
            }
            ad?.fullScreenContentDelegate = self
            self.interstitial = ad
            print("Interstitial loaded ✅")
        }
    }

    // SwiftUIから呼ぶ：表示できれば表示。できなければ即 after を実行
    func showInterstitial(after: @escaping () -> Void) {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController
        else { after(); return }

        if let ad = interstitial {
            onDismiss = after
            ad.present(from: root)
        } else {
            // 未ロードなら即実行し、裏でプリロード
            after()
            loadInterstitial()
        }
    }

    // MARK: - GADFullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // 閉じたら遷移＆次回分をロード
        let completion = onDismiss
        onDismiss = nil
        completion?()
        loadInterstitial()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Interstitial present error:", error.localizedDescription)
        let completion = onDismiss
        onDismiss = nil
        completion?()
        loadInterstitial()
    }
}
