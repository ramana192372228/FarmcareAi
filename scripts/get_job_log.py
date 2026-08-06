import urllib.request
import json
import sys

def get_job_log(job_id):
    url = f"https://api.github.com/repos/ramana192372228/FarmcareAi/actions/jobs/{job_id}/logs"
    req = urllib.request.Request(url, headers={"User-Agent": "Python-GH-Checker"})
    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read().decode('utf-8', errors='ignore')
            lines = content.splitlines()
            print("====================================================")
            print(f"LOG OUTPUT FOR JOB {job_id} (last 50 lines)")
            print("====================================================")
            for l in lines[-50:]:
                print(l)
    except Exception as e:
        print(f"Error fetching log for job {job_id}: {e}")

if __name__ == "__main__":
    job_id = sys.argv[1] if len(sys.argv) > 1 else "92516300488"
    get_job_log(job_id)
