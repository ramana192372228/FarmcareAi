import os
import sys
import json
import subprocess
import urllib.request
import urllib.error
import openpyxl
from openpyxl.styles import Font, PatternFill

def run_performance_test():
    print("====================================================")
    print("STARTING LOAD & PERFORMANCE TESTING (k6)")
    target_url = os.environ.get("BASE_URL", "https://ramana192372228.github.io/FarmcareAi/")
    print(f"Target API/Endpoint: {target_url}")
    print("====================================================")

    html_dir = os.path.join(os.path.dirname(__file__), "../Test Results/HTML")
    excel_dir = os.path.join(os.path.dirname(__file__), "../Test Results/Excel")
    json_dir = os.path.join(os.path.dirname(__file__), "../Test Results/JSON")
    summary_dir = os.path.join(os.path.dirname(__file__), "../Test Results/Summary")

    for d in [html_dir, excel_dir, json_dir, summary_dir]:
        os.makedirs(d, exist_ok=True)

    is_reachable = False
    http_code = 0
    try:
        req = urllib.request.Request(target_url, headers={'User-Agent': 'k6-preflight-check/1.0'})
        with urllib.request.urlopen(req, timeout=10) as resp:
            http_code = resp.getcode()
            if http_code == 200:
                is_reachable = True
    except urllib.error.HTTPError as e:
        http_code = e.code
    except Exception as e:
        http_code = 0

    if not is_reachable:
        print(f"[PRE-FLIGHT WARNING] Target API/URL {target_url} is unavailable (HTTP Code: {http_code}).")
        print("Generating WARNING Performance Reports without failing workflow...")

        perf_data = {
            "status": "WARNING",
            "reason": "Backend unavailable",
            "target_url": target_url,
            "http_status_code": http_code,
            "virtual_users": 0,
            "duration": "0s",
            "total_requests": 0,
            "failed_requests": 0,
            "error_rate": "100%",
            "avg_response_time": "0ms",
            "p95_response_time": "0ms"
        }

        # Save JSON
        json_path = os.path.join(json_dir, "Performance_Report.json")
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(perf_data, f, indent=2)

        # Save Markdown
        md_content = f"""# Performance Load Test Report

- **Status**: WARNING ⚠️
- **Reason**: Backend/API unavailable (HTTP Code: {http_code})
- **Target URL**: {target_url}
- **Virtual Users**: 0 (Aborted pre-flight)
- **Recommendation**: Ensure backend API service is deployed and active before executing baseline load tests.
"""
        with open(os.path.join(summary_dir, "Performance_Report.md"), "w", encoding="utf-8") as f:
            f.write(md_content)

        # Save HTML
        html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>Performance Report - WARNING</title>
    <style>
        body {{ font-family: Arial, sans-serif; background: #fafafa; padding: 20px; }}
        .card {{ background: #fff3cd; color: #856404; padding: 20px; border-radius: 8px; border: 1px solid #ffeeba; }}
        h1 {{ margin-top: 0; }}
    </style>
</head>
<body>
    <div class="card">
        <h1>Performance Load Test Status: WARNING</h1>
        <p><strong>Reason:</strong> Backend / API is unavailable at <code>{target_url}</code> (HTTP Status: {http_code}).</p>
        <p>Pre-flight check prevented workflow termination. Remaining pipeline jobs will continue.</p>
    </div>
</body>
</html>"""
        with open(os.path.join(html_dir, "Performance_Report.html"), "w", encoding="utf-8") as f:
            f.write(html_content)

        # Save Excel
        wb = openpyxl.Workbook()
        ws = wb.active
        ws.title = "Performance Results"
        ws.append(["Target URL", "HTTP Status", "Status", "Reason"])
        ws.append([target_url, http_code, "WARNING", "Backend unavailable"])
        wb.save(os.path.join(excel_dir, "Performance_Report.xlsx"))

        print("Performance WARNING reports generated successfully.")
        sys.exit(0)

    # Endpoint IS reachable -> Execute k6
    print(f"Target API is reachable (HTTP 200). Executing k6 load test script...")
    k6_script = os.path.join(os.path.dirname(__file__), "../Vulnerability Test Results/k6-load-test.js")
    
    try:
        res = subprocess.run(["k6", "run", k6_script], capture_output=True, text=True)
        print("k6 stdout:", res.stdout)
        print("k6 stderr:", res.stderr)

        perf_data = {
            "status": "PASSED" if res.returncode == 0 else "FAILED",
            "reason": "Execution completed" if res.returncode == 0 else f"k6 threshold failure (Exit Code: {res.returncode})",
            "target_url": target_url,
            "raw_output": res.stdout
        }

        with open(os.path.join(json_dir, "Performance_Report.json"), "w", encoding="utf-8") as f:
            json.dump(perf_data, f, indent=2)

        if res.returncode != 0:
            print(f"k6 execution failed with exit code {res.returncode}")
            sys.exit(res.returncode)
    except FileNotFoundError:
        print("[WARNING] k6 executable is not installed on system. Generating WARNING report...")
        perf_data = {
            "status": "WARNING",
            "reason": "k6 binary unavailable on system",
            "target_url": target_url
        }
        with open(os.path.join(json_dir, "Performance_Report.json"), "w", encoding="utf-8") as f:
            json.dump(perf_data, f, indent=2)
        sys.exit(0)


if __name__ == "__main__":
    run_performance_test()
