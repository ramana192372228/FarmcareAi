const fs = require('fs');
const path = require('path');

class HtmlReporter {
  static generateReports(testResults, outputDir, baseUrl) {
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    const total = testResults.length;
    const passed = testResults.filter(t => t.status === 'PASSED').length;
    const failed = testResults.filter(t => t.status === 'FAILED').length;
    const skipped = testResults.filter(t => t.status === 'SKIPPED').length;
    const passRate = total > 0 ? ((passed / total) * 100).toFixed(2) : 0;
    const duration = testResults.reduce((acc, curr) => acc + (curr.duration || 0), 0);

    const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FarmCare AI - E2E Execution Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f4f6f9; margin: 0; padding: 20px; }
        .header { background: #1e4620; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .cards { display: flex; gap: 20px; margin-bottom: 20px; }
        .card { background: white; padding: 20px; border-radius: 8px; flex: 1; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; }
        .card .val { font-size: 28px; font-weight: bold; margin-top: 5px; }
        .passed { color: #2e7d32; }
        .failed { color: #c62828; }
        .skipped { color: #f57c00; }
        table { width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #2e7d32; color: white; }
        tr:hover { background-color: #f5f5f5; }
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; color: white; }
        .badge-passed { background: #2e7d32; }
        .badge-failed { background: #c62828; }
        .badge-skipped { background: #f57c00; }
    </style>
</head>
<body>
    <div class="header">
        <h1>FarmCare AI - E2E Automation Execution Report</h1>
        <p>Target Application URL: <strong>${baseUrl}</strong></p>
        <p>Execution Time: ${new Date().toISOString()}</p>
    </div>
    
    <div class="cards">
        <div class="card">Total Test Cases<div class="val">${total}</div></div>
        <div class="card">Passed<div class="val passed">${passed}</div></div>
        <div class="card">Failed<div class="val failed">${failed}</div></div>
        <div class="card">Skipped<div class="val skipped">${skipped}</div></div>
        <div class="card">Pass Rate<div class="val passed">${passRate}%</div></div>
        <div class="card">Total Duration<div class="val">${(duration / 1000).toFixed(2)}s</div></div>
    </div>

    <h2>Test Execution Details</h2>
    <table>
        <thead>
            <tr>
                <th>Test Case ID</th>
                <th>Module</th>
                <th>Test Name</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Duration (ms)</th>
                <th>Details / Error</th>
            </tr>
        </thead>
        <tbody>
            ${testResults.map(tc => `
                <tr>
                    <td>${tc.id}</td>
                    <td>${tc.module}</td>
                    <td>${tc.name}</td>
                    <td>${tc.priority}</td>
                    <td><span class="badge badge-${tc.status.toLowerCase()}">${tc.status}</span></td>
                    <td>${tc.duration || 0}</td>
                    <td>${tc.error || 'N/A'}</td>
                </tr>
            `).join('')}
        </tbody>
    </table>
</body>
</html>`;

    fs.writeFileSync(path.join(outputDir, 'execution-report.html'), htmlContent);
    fs.writeFileSync(path.join(outputDir, 'dashboard.html'), htmlContent);
  }
}

module.exports = HtmlReporter;
