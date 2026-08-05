require('dotenv').config();

module.exports = {
  BASE_URL: process.env.BASE_URL || 'https://ramana192372228.github.io/FarmcareAi/',
  TIMEOUT: parseInt(process.env.TIMEOUT || '10000', 10),
  HEADLESS: process.env.HEADLESS !== 'false'
};
