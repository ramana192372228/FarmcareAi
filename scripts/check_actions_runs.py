import urllib.request
import json
import sys

def check_all():
    runs_url = "https://api.github.com/repos/ramana192372228/FarmcareAi/actions/runs"
    req = urllib.request.Request(runs_url, headers={"User-Agent": "Python-GH-Checker"})
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            runs = data.get("workflow_runs", [])
            latest_run = runs[0] if runs else None
            if not latest_run:
                print("No workflow runs found.")
                return

            print(f"Latest Run ID: {latest_run['id']} | Workflow: {latest_run['name']} | Status: {latest_run['status']} | Conclusion: {latest_run['conclusion']}")
            
            jobs_url = f"https://api.github.com/repos/ramana192372228/FarmcareAi/actions/runs/{latest_run['id']}/jobs"
            j_req = urllib.request.Request(jobs_url, headers={"User-Agent": "Python-GH-Checker"})
            with urllib.request.urlopen(j_req) as j_resp:
                j_data = json.loads(j_resp.read().decode('utf-8'))
                jobs = j_data.get("jobs", [])
                print("====================================================")
                print(f"WORKFLOW JOBS IN RUN #{latest_run['run_number']} ({len(jobs)} total jobs)")
                print("====================================================")
                for j in jobs:
                    print(f"Job #{j['id']} | {j['name']} | Status: {j['status']} | Conclusion: {j['conclusion']}")
                    if j.get('conclusion') == 'failure':
                        print("  Failed Steps:")
                        for s in j.get('steps', []):
                            if s.get('conclusion') == 'failure':
                                print(f"    - {s['name']}: {s['conclusion']}")
    except Exception as e:
        print(f"Error checking GitHub Actions: {e}")

if __name__ == "__main__":
    check_all()
