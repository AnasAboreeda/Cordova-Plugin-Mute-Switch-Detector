@objc(MuteSwitchDetector) class MuteSwitchDetector : CDVPlugin {

    @objc(checkMuteSwitch:)
    func checkMuteSwitch(command: CDVInvokedUrlCommand) {
        MuteSwitchDetectorCore.shared.isPaused = false

        let muteOn = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Mute switch is On");
        let muteOff = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Mute switch is Off");

        MuteSwitchDetectorCore.shared.notify = { m in

            let pluginResult = m ? muteOn : muteOff

            MuteSwitchDetectorCore.shared.isPaused = true

            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }
}
