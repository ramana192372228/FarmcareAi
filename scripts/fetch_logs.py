import urllib.request
import zipfile
import io
import os

def fetch_run_logs(run_id="31069755902"):
    url = f"https://api.github.com/repos/ramana192372228/FarmcareAi/actions/runs/{run_id}/logs"
    req = urllib.request.Request(url, headers={"User-Agent": "Python-GH-Log-Fetcher"})
    try:
        with urllib.request.urlopen(req) as resp:
            zip_bytes = resp.read()
            z = zipfile.ZipFile(io.BytesIO(zip_bytes))
            print("Zip contents:", z.namelist())
            for name in z.namelist():
                if "Security" in name or "security" in name:
                    print(f"=== LOG FILE: {name} ===")
                    content = z.read(name).decode('utf-8', errors='ignore')
                    print(content[-2000:])
    except Exception as e:
        print(f"Error fetching zip logs: {e}")

if __name__ == "__main__":
    fetch_run_logs()
