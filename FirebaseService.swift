import Foundation
import FirebaseAuth
import FirebaseFirestore

struct RankingEntry: Identifiable, Hashable {
    let id: String          // userId
    let userId: String
    let bestScore: Int
    let updatedAt: Date?
}

enum FBError: Error { case notSignedIn }

final class FirebaseService {
    static let shared = FirebaseService()
    private init() {}

    private var db: Firestore { Firestore.firestore() }

    // 匿名サインイン（起動時に一度呼ばれる想定）
    func ensureAnonymousSignIn() async throws -> String {
        if let uid = Auth.auth().currentUser?.uid { return uid }
        let result = try await Auth.auth().signInAnonymously()
        return result.user.uid
    }
    

    // 自己ベスト取得
    func fetchBestScore(uid: String) async throws -> Int? {
        let snap = try await db.collection("scores").document(uid).getDocument()
        guard snap.exists, let best = snap.data()?["bestScore"] as? Int else { return nil }
        return best
    }

    // ベスト更新なら保存（ルールでも“下げ禁止”にしてある前提）
    // FirebaseService.swift

    // FirebaseService.swift

    func saveIfBestScore(_ score: Int) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { throw FBError.notSignedIn }
        let ref = db.collection("scores").document(uid)

        // 1) Any? で受ける（クロージャ内は throw できないので do/catch で errorPointer に詰める）
        let resultAnyOptional: Any? = try await db.runTransaction({ (tx, errorPointer) -> Any? in
            do {
                let snap = try tx.getDocument(ref)
                let now = Timestamp(date: Date())

                if !snap.exists {
                    tx.setData([
                        "bestScore": score,
                        "userId": uid,
                        "createdAt": now,
                        "updatedAt": now
                    ], forDocument: ref)
                    return true  // Bool を返す
                } else {
                    let cur = (snap.data()?["bestScore"] as? Int) ?? 0
                    if score > cur {
                        tx.updateData([
                            "bestScore": score,
                            "updatedAt": now
                        ], forDocument: ref)
                        return true
                    } else {
                        return false
                    }
                }
            } catch {
                // ここでは throw できない → NSError を渡して nil を返す
                errorPointer?.pointee = error as NSError
                return nil
            }
        })

        // 2) Any? → Bool へ取り出す
        guard let updated = resultAnyOptional as? Bool else {
            throw NSError(domain: "FirestoreTx",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Transaction returned no result"])
        }
        return updated
    }


    

    // ランキング（上位N）
    func fetchRanking(limit: Int = 10) async throws -> [RankingEntry] {
        let qs = try await db.collection("scores")
            .order(by: "bestScore", descending: true)
            .limit(to: limit)
            .getDocuments()

        return qs.documents.map { doc in
            let data = doc.data()
            return RankingEntry(
                id: doc.documentID,
                userId: data["userId"] as? String ?? doc.documentID,
                bestScore: data["bestScore"] as? Int ?? 0,
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
            )
        }
    }
}
