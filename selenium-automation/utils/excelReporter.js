const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');

class ExcelReporter {
  static async generateReports(testResults, outputDir) {
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    const workbook = new ExcelJS.Workbook();
    
    // Sheet 1: Executed Test Cases
    const sheetExecuted = workbook.addWorksheet('Executed Test Cases');
    sheetExecuted.columns = [
      { header: 'Test ID', key: 'id', width: 15 },
      { header: 'Module', key: 'module', width: 20 },
      { header: 'Test Name', key: 'name', width: 35 },
      { header: 'Priority', key: 'priority', width: 12 },
      { header: 'Status', key: 'status', width: 12 },
      { header: 'Execution Time (ms)', key: 'duration', width: 20 }
    ];

    // Sheet 2: Passed Tests
    const sheetPassed = workbook.addWorksheet('Passed Tests');
    sheetPassed.columns = sheetExecuted.columns;

    // Sheet 3: Failed Tests
    const sheetFailed = workbook.addWorksheet('Failed Tests');
    sheetFailed.columns = [
      ...sheetExecuted.columns,
      { header: 'Failure Reason', key: 'error', width: 45 }
    ];

    // Sheet 4: Skipped Tests
    const sheetSkipped = workbook.addWorksheet('Skipped Tests');
    sheetSkipped.columns = sheetExecuted.columns;

    // Sheet 5: Execution Metrics
    const sheetMetrics = workbook.addWorksheet('Execution Metrics');
    sheetMetrics.columns = [
      { header: 'Metric', key: 'metric', width: 30 },
      { header: 'Value', key: 'value', width: 20 }
    ];

    // Sheet 6: Defect Summary
    const sheetDefects = workbook.addWorksheet('Defect Summary');
    sheetDefects.columns = [
      { header: 'Module', key: 'module', width: 25 },
      { header: 'Failed Count', key: 'failedCount', width: 15 },
      { header: 'Critical Failures', key: 'criticalCount', width: 20 }
    ];

    let passed = 0, failed = 0, skipped = 0, totalDuration = 0;
    const moduleFailures = {};

    testResults.forEach(tc => {
      sheetExecuted.addRow(tc);
      totalDuration += tc.duration || 0;
      if (tc.status === 'PASSED') {
        passed++;
        sheetPassed.addRow(tc);
      } else if (tc.status === 'FAILED') {
        failed++;
        sheetFailed.addRow(tc);
        moduleFailures[tc.module] = (moduleFailures[tc.module] || 0) + 1;
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

    Object.keys(moduleFailures).forEach(mod => {
      sheetDefects.addRow({ module: mod, failedCount: moduleFailures[mod], criticalCount: moduleFailures[mod] });
    });

    const mainReportPath = path.join(outputDir, 'Automation_Test_Report.xlsx');
    await workbook.xlsx.writeFile(mainReportPath);

    // Save individual helper excel reports
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
    await sumWb.xlsx.writeFile(path.join(outputDir, 'Summary_Report.xlsx'));
    await sumWb.xlsx.writeFile(path.join(outputDir, 'Execution_Summary.xlsx'));

    return mainReportPath;
  }
}

module.exports = ExcelReporter;
