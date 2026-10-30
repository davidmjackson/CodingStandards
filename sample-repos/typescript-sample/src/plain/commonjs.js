'use strict';

const path = require('node:path');

function resolveData(name) {
  return path.join(process.cwd(), name);
}

module.exports = { resolveData };
