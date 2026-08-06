import urllib.request
import json
import sys

def check_all_recent():
    runs_url = "https://api.github.com/repos/ramana192372228/FarmcareAi/actions/runs"
    req = urllib.request.Request(runs_url, headers={"User-Agent": "Python-GH-Checker"})
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            runs = data.get("workflow_runs", [])
            print("====================================================")
            print("RECENT WORKFLOW RUNS SUMMARY")
            print("====================================================")
            for r in runs[:5]:
                print(f"Run #{r['run_number']} | ID: {r['id']} | Status: {r['status']} | Conclusion: {r['conclusion']} | Commit: {r['head_sha'][:7]} | Msg: {r['head_commit']['message'].splitlines()[0]}")
                j_url = f"https://api.github.com/repos/ramana192372228/FarmcareAi/actions/runs/{r['id']}/jobs"
                j_req = urllib.request.Request(j_url, headers={"User-Agent": "Python-GH-Checker"})
                with urllib.request.urlopen(j_req) as j_resp:
                    j_data = json.loads(j_resp.read().decode('utf-8'))
                    for j in j_data.get("jobs", []):
                        print(f"  - Job: {j['name']} | Status: {j['status']} | Conclusion: {j['conclusion']}")
                print("-" * 50)
    except Exception as e:
        print(f"Error checking GitHub Actions: {e}")

if __name__ == "__main__":
    check_all_recent()
