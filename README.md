# Mute Switch Detector on IOS (Cordova plugin)

This plugin allows you to detect the state of mute switch on iPhone.

The plugin is based on code seen in several other existing plugins:

1. [Mute](https://github.com/akramhussein/Mute) By [Akram Hussein](https://github.com/akramhussein)
1. [SoundSwitch](https://github.com/moshegottlieb/SoundSwitch) by [Moshe Gottlieb](https://github.com/moshegottlieb)

Thanks to all of the above mentioned authors for sharing their code openly.

```Bash
cordova plugin add https://github.com/AnasFullStack/Cordova-Plugin-Mute-Switch-Detector.git --nofetch
```

## API reference

### detectMuteSwitch

Detect mute switch status

```Javascript
window.cordova.plugins.DetectMuteSwitch.detectMuteSwitch();
```

## Supported Platforms

- iOS

## Usage Example

Call the `window.cordova.plugins.DetectMuteSwitch.detectMuteSwitch()` method passing a callback function

### Example

```Javascript
window.cordova.plugins.DetectMuteSwitch.detectMuteSwitch(
  function(msg) {
    console.log('Result:', msg);
  }
);

/*

This will print the Mute switch status

Result: Mute switch is Off

OR

Result: Mute switch is On

*/
```
