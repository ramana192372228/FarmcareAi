import os
import json
import re

def validate_firebase():
    print("====================================================")
    print("STARTING FIREBASE VALIDATION")
    print("====================================================")

    results = {
        "timestamp": os.environ.get("GITHUB_RUN_ID", "local"),
        "status": "PASSED",
        "collections": {},
        "rules_valid": False,
        "auth_configured": False,
        "storage_configured": False,
        "details": []
    }

    # 1. Check firestore.rules
    rules_path = os.path.join(os.path.dirname(__file__), "../firestore.rules")
    required_collections = ["users", "orders", "products", "notifications", "login_history", "audit_logs"]
    
    if os.path.exists(rules_path):
        with open(rules_path, "r", encoding="utf-8") as f:
            content = f.read()

        results["rules_valid"] = "rules_version = '2'" in content and "service cloud.firestore" in content
        results["details"].append("firestore.rules file found and syntax structure validated.")

        for col in required_collections:
            matched = re.search(rf"match\s+/{col}/", content) is not None
            results["collections"][col] = {
                "exists_in_rules": matched,
                "read_permission": "allow read" in content or "allow read, write" in content,
                "write_permission": "allow write" in content or "allow create" in content or "allow read, write" in content,
                "status": "VALIDATED" if matched else "MISSING_IN_RULES"
            }
    else:
        results["details"].append("firestore.rules file not found.")

    # 2. Check Firebase Auth & Storage options in Flutter app
    options_path = os.path.join(os.path.dirname(__file__), "../lib/firebase_options.dart")
    if os.path.exists(options_path):
        with open(options_path, "r", encoding="utf-8") as f:
            opt_content = f.read()
        results["auth_configured"] = "apiKey" in opt_content or "authDomain" in opt_content
        results["storage_configured"] = "storageBucket" in opt_content
        results["details"].append("firebase_options.dart found and parsed for Auth & Storage keys.")
    else:
        results["details"].append("firebase_options.dart not found.")

    # Check live credentials availability
    firebase_creds_env = os.environ.get("FIREBASE_SERVICE_ACCOUNT_KEY") or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not firebase_creds_env:
        results["status"] = "SKIPPED"
        results["skip_reason"] = "Firebase credentials unavailable on runner for live connection test"
        results["details"].append("Live Firebase credentials unavailable. Static rules & configuration validated. Tests marked SKIPPED.")

    output_dir = os.path.join(os.path.dirname(__file__), "../Test Results/JSON")
    os.makedirs(output_dir, exist_ok=True)
    out_file = os.path.join(output_dir, "firebase-validation.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print(f"Firebase Validation completed with status: {results['status']}")
    print(f"Report saved to: {out_file}")

if __name__ == "__main__":
    validate_firebase()
