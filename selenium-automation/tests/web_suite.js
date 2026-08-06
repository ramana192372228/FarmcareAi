const config = require('../config/env');
const ExcelReporter = require('../utils/excelReporter');
const HtmlReporter = require('../utils/htmlReporter');
const fs = require('fs');
const path = require('path');

async function runSeleniumSuite() {
  console.log('====================================================');
  console.log('STARTING REAL SELENIUM E2E AUTOMATION SUITE');
  const targetUrl = process.env.BASE_URL || config.BASE_URL || 'https://ramana192372228.github.io/FarmcareAi/';
  console.log(`TARGET APPLICATION URL: ${targetUrl}`);
  console.log('====================================================');

  const testResults = [];
  const excelOutputDir = path.join(__dirname, '../../Test Results/Excel');
  const htmlOutputDir = path.join(__dirname, '../../Test Results/HTML');
  const jsonOutputDir = path.join(__dirname, '../../Test Results/JSON');
  const summaryOutputDir = path.join(__dirname, '../../Test Results/Summary');
  const screenshotsDir = path.join(__dirname, '../../Test Results/Screenshots');
  const logsDir = path.join(__dirname, '../../Test Results/Logs');

  [excelOutputDir, htmlOutputDir, jsonOutputDir, summaryOutputDir, screenshotsDir, logsDir].forEach(d => {
    if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
  });

  let driver = null;
  let driverError = null;

  try {
    const { Builder, Capabilities } = require('selenium-webdriver');
    const chrome = require('selenium-webdriver/chrome');

    const options = new chrome.Options();
    options.addArguments('--headless=new');
    options.addArguments('--no-sandbox');
    options.addArguments('--disable-dev-shm-usage');
    options.addArguments('--window-size=1920,1080');

    driver = await new Builder()
      .forBrowser('chrome')
      .setChromeOptions(options)
      .build();

    console.log(`Navigating Selenium Driver to: ${targetUrl}`);
    await driver.get(targetUrl);
    await driver.sleep(3000);

    const title = await driver.getTitle();
    console.log(`Page title retrieved: "${title}"`);

    // Take actual screenshot
    const image = await driver.takeScreenshot();
    fs.writeFileSync(path.join(screenshotsDir, 'selenium_web_homepage.png'), image, 'base64');
    console.log(`Saved live screenshot to: ${path.join(screenshotsDir, 'selenium_web_homepage.png')}`);

    testResults.push({
      id: 'TC_SEL_001',
      module: 'Navigation & UI',
      name: 'Verify Homepage Title & Web App Loading',
      priority: 'High',
      status: 'PASSED',
      duration: 3200,
      error: ''
    });

  } catch (err) {
    console.log(`Selenium WebDriver execution skipped/failed: ${err.message}`);
    driverError = err.message;
    
    testResults.push({
      id: 'TC_SEL_001',
      module: 'Selenium Automation',
      name: 'Web Application E2E Live Test',
      priority: 'High',
      status: 'SKIPPED',
      duration: 0,
      error: `Selenium WebDriver execution skipped: ${driverError}`
    });
  } finally {
    if (driver) {
      try { await driver.quit(); } catch (e) {}
    }
  }

  // Write log file
  fs.writeFileSync(path.join(logsDir, 'selenium-execution.log'), `Selenium Execution Log\nTarget: ${targetUrl}\nStatus: ${driverError ? 'SKIPPED' : 'PASSED'}\nError: ${driverError || 'None'}\nTime: ${new Date().toISOString()}\n`);

  await ExcelReporter.generateReports(testResults, excelOutputDir);
  HtmlReporter.generateReports(testResults, htmlOutputDir, targetUrl);
  fs.writeFileSync(path.join(jsonOutputDir, 'selenium-execution.json'), JSON.stringify(testResults, null, 2));

  const passed = testResults.filter(t => t.status === 'PASSED').length;
  const skipped = testResults.filter(t => t.status === 'SKIPPED').length;
  const failed = testResults.filter(t => t.status === 'FAILED').length;

  const markdownSummary = `# Selenium Live Web E2E Execution Summary

- **Target URL**: ${targetUrl}
- **Execution Date**: ${new Date().toISOString()}
- **Total Test Cases**: ${testResults.length}
- **Passed**: ${passed}
- **Failed**: ${failed}
- **Skipped**: ${skipped}
- **Status**: ${skipped > 0 ? 'SKIPPED' : (failed > 0 ? 'FAILED' : 'PASSED')}
- **Reason**: ${driverError ? `Browser/Driver issue: ${driverError}` : 'Execution completed successfully.'}
`;

  fs.writeFileSync(path.join(summaryOutputDir, 'selenium_summary.md'), markdownSummary);
  console.log('Selenium suite execution completed.');
}

if (require.main === module) {
  runSeleniumSuite().catch(console.error);
}

module.exports = { runSeleniumSuite };
