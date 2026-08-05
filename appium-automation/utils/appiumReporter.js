const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

class AppiumReporter {
  static async generateReports(testResults, outputDir) {
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    const workbook = new ExcelJS.Workbook();
    
    // Sheet 1: Executed Test Cases
    const sheetExecuted = workbook.addWorksheet('Executed Test Cases');
    sheetExecuted.columns = [
      { header: 'Test ID', key: 'id', width: 15 },
      { header: 'Module', key: 'module', width: 22 },
      { header: 'Test Name', key: 'name', width: 35 },
      { header: 'Priority', key: 'priority', width: 12 },
      { header: 'Status', key: 'status', width: 12 },
      { header: 'Execution Time (ms)', key: 'duration', width: 20 }
    ];

    const sheetPassed = workbook.addWorksheet('Passed Tests');
    sheetPassed.columns = sheetExecuted.columns;

    const sheetFailed = workbook.addWorksheet('Failed Tests');
    sheetFailed.columns = [
      ...sheetExecuted.columns,
      { header: 'Failure Reason', key: 'error', width: 45 }
    ];

    const sheetSkipped = workbook.addWorksheet('Skipped Tests');
    sheetSkipped.columns = sheetExecuted.columns;

    const sheetMetrics = workbook.addWorksheet('Execution Metrics');
    sheetMetrics.columns = [
      { header: 'Metric', key: 'metric', width: 30 },
      { header: 'Value', key: 'value', width: 20 }
    ];

    const sheetDefects = workbook.addWorksheet('Defect Summary');
    sheetDefects.columns = [
      { header: 'Module', key: 'module', width: 25 },
      { header: 'Failed Count', key: 'failedCount', width: 15 },
      { header: 'Critical Failures', key: 'criticalCount', width: 20 }
    ];

    const sheetPassRate = workbook.addWorksheet('Pass Rate Summary');
    sheetPassRate.columns = [
      { header: 'Module', key: 'module', width: 25 },
      { header: 'Pass Rate (%)', key: 'passRate', width: 20 }
    ];

    let passed = 0, failed = 0, skipped = 0, totalDuration = 0;
    const moduleStats = {};

    testResults.forEach(tc => {
      sheetExecuted.addRow(tc);
      totalDuration += tc.duration || 0;

      if (!moduleStats[tc.module]) {
        moduleStats[tc.module] = { total: 0, passed: 0, failed: 0 };
      }
      moduleStats[tc.module].total++;

      if (tc.status === 'PASSED') {
        passed++;
        sheetPassed.addRow(tc);
        moduleStats[tc.module].passed++;
      } else if (tc.status === 'FAILED') {
        failed++;
        sheetFailed.addRow(tc);
        moduleStats[tc.module].failed++;
      } else {
        skipped++;
        sheetSkipped.addRow(tc);
      }
    });

    const total = testResults.length;
    const passRate = total > 0 ? ((passed / total) * 100).toFixed(2) + '%' : '0%';

    sheetMetrics.addRow({ metric: 'Total Test Cases', value: total });
    sheetMetrics.addRow({ metric: 'Passed Test Cases', value: passed });
    sheetMetrics.addRow({ metric: 'Failed Test Cases', value: failed });
    sheetMetrics.addRow({ metric: 'Skipped Test Cases', value: skipped });
    sheetMetrics.addRow({ metric: 'Pass Rate', value: passRate });
    sheetMetrics.addRow({ metric: 'Total Duration (ms)', value: totalDuration });

    Object.keys(moduleStats).forEach(mod => {
      const stats = moduleStats[mod];
      const rate = ((stats.passed / stats.total) * 100).toFixed(1);
      sheetPassRate.addRow({ module: mod, passRate: `${rate}%` });
      if (stats.failed > 0) {
        sheetDefects.addRow({ module: mod, failedCount: stats.failed, criticalCount: stats.failed });
      }
    });

    const mainReportPath = path.join(outputDir, 'Automation_Test_Report.xlsx');
    await workbook.xlsx.writeFile(mainReportPath);

    // Save auxiliary excel files
    const passWb = new ExcelJS.Workbook();
    const pSheet = passWb.addWorksheet('Passed Tests');
    pSheet.columns = sheetExecuted.columns;
    testResults.filter(t => t.status === 'PASSED').forEach(t => pSheet.addRow(t));
    await passWb.xlsx.writeFile(path.join(outputDir, 'Passed_Test_Cases.xlsx'));

    const failWb = new ExcelJS.Workbook();
    const fSheet = failWb.addWorksheet('Failed Tests');
    fSheet.columns = sheetFailed.columns;
    testResults.filter(t => t.status === 'FAILED').forEach(t => fSheet.addRow(t));
    await failWb.xlsx.writeFile(path.join(outputDir, 'Failed_Test_Cases.xlsx'));

    const sumWb = new ExcelJS.Workbook();
    const sSheet = sumWb.addWorksheet('Execution Summary');
    sSheet.columns = sheetMetrics.columns;
    sSheet.rows = sheetMetrics.rows;
    await sumWb.xlsx.writeFile(path.join(outputDir, 'Execution_Summary.xlsx'));

    return mainReportPath;
  }

  static generateHtml(testResults, outputDir) {
    const htmlDir = path.join(outputDir, '../HTML');
    if (!fs.existsSync(htmlDir)) fs.mkdirSync(htmlDir, { recursive: true });

    const total = testResults.length;
    const passed = testResults.filter(t => t.status === 'PASSED').length;
    const failed = testResults.filter(t => t.status === 'FAILED').length;
    const skipped = testResults.filter(t => t.status === 'SKIPPED').length;
    const passRate = ((passed / total) * 100).toFixed(2);

    const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Android Appium Execution Report</title>
    <style>
        body { font-family: sans-serif; background: #fafafa; padding: 20px; }
        .header { background: #1b5e20; color: white; padding: 15px; border-radius: 6px; }
        .stats { display: flex; gap: 15px; margin: 20px 0; }
        .box { background: white; padding: 15px; border-radius: 6px; flex: 1; border: 1px solid #ccc; text-align: center; }
        table { width: 100%; border-collapse: collapse; background: white; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #2e7d32; color: white; }
    </style>
</head>
<body>
    <div class="header">
        <h1>FarmCare AI - Android Appium E2E Report</h1>
    </div>
    <div class="stats">
        <div class="box">Total: <strong>${total}</strong></div>
        <div class="box">Passed: <strong style="color:green;">${passed}</strong></div>
        <div class="box">Failed: <strong style="color:red;">${failed}</strong></div>
        <div class="box">Skipped: <strong style="color:orange;">${skipped}</strong></div>
        <div class="box">Pass Rate: <strong>${passRate}%</strong></div>
    </div>
    <h2>Test Cases</h2>
    <table>
        <thead>
            <tr><th>ID</th><th>Module</th><th>Name</th><th>Priority</th><th>Status</th><th>Error</th></tr>
        </thead>
        <tbody>
            ${testResults.map(t => `
                <tr>
                    <td>${t.id}</td><td>${t.module}</td><td>${t.name}</td><td>${t.priority}</td>
                    <td><b style="color:${t.status==='PASSED'?'green':t.status==='FAILED'?'red':'orange'}">${t.status}</b></td>
                    <td>${t.error || '-'}</td>
                </tr>
            `).join('')}
        </tbody>
    </table>
</body>
</html>`;

    fs.writeFileSync(path.join(htmlDir, 'execution-report.html'), htmlContent);
    fs.writeFileSync(path.join(htmlDir, 'dashboard.html'), htmlContent);
    fs.writeFileSync(path.join(htmlDir, 'trends.html'), htmlContent);
  }
}

module.exports = AppiumReporter;
