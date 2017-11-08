var exec = require('cordova/exec');

exports.detectMuteSwitch = function(callback) {
  exec(callback, null, 'MuteSwitchDetector', 'checkMuteSwitch');
};
