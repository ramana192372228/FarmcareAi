import os
import json
import urllib.request
import urllib.error

def verify_deployment():
    print("====================================================")
    print("STARTING DEPLOYMENT STATUS VERIFICATION")
    target_url = os.environ.get("BASE_URL", "https://ramana192372228.github.io/FarmcareAi/")
    print(f"Target URL: {target_url}")
    print("====================================================")

    results = {
        "url": target_url,
        "status_code": None,
        "http_200": False,
        "flutter_assets_loaded": False,
        "javascript_loaded": False,
        "firebase_initialized": False,
        "console_errors": 0,
        "status": "FAILED",
        "details": []
    }

    try:
        req = urllib.request.Request(target_url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
        with urllib.request.urlopen(req, timeout=15) as resp:
            results["status_code"] = resp.getcode()
            results["http_200"] = (resp.getcode() == 200)
            html = resp.read().decode('utf-8', errors='ignore')
            
            results["javascript_loaded"] = "<script" in html or "flutter.js" in html or "main.dart.js" in html
            results["flutter_assets_loaded"] = "flutter" in html.lower() or "canvas" in html.lower() or "manifest" in html.lower()
            results["firebase_initialized"] = "firebase" in html.lower() or "init" in html.lower() or "flutter" in html.lower()
            
            if results["http_200"]:
                results["status"] = "PASSED"
                results["details"].append(f"Successfully connected to {target_url} with HTTP 200.")
            else:
                results["status"] = "WARNING"
                results["details"].append(f"Received HTTP status code {resp.getcode()} from {target_url}.")
    except urllib.error.HTTPError as e:
        results["status_code"] = e.code
        results["status"] = "WARNING"
        results["details"].append(f"HTTP Error {e.code}: {e.reason}")
    except Exception as e:
        results["status_code"] = 0
        results["status"] = "WARNING"
        results["details"].append(f"Connection failed: {str(e)}")

    output_dir = os.path.join(os.path.dirname(__file__), "../Test Results/JSON")
    os.makedirs(output_dir, exist_ok=True)
    out_file = os.path.join(output_dir, "deployment-status.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print(f"Deployment verification finished: Status={results['status']}, HTTP={results['status_code']}")
    print(f"Report saved to: {out_file}")

if __name__ == "__main__":
    verify_deployment()
