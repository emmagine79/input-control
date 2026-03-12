import CoreAudio
import Foundation

struct AudioDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let name: String
    let isDefault: Bool
    let transportType: UInt32

    var transportLabel: String {
        switch transportType {
        case kAudioDeviceTransportTypeBuiltIn:
            return "Built-In"
        case kAudioDeviceTransportTypeBluetooth,
             kAudioDeviceTransportTypeBluetoothLE:
            return "Bluetooth"
        case kAudioDeviceTransportTypeUSB:
            return "USB"
        case kAudioDeviceTransportTypeHDMI:
            return "HDMI"
        case kAudioDeviceTransportTypeAirPlay:
            return "AirPlay"
        default:
            return "Audio"
        }
    }

    var shortName: String {
        if name.count <= 24 {
            return name
        }

        return String(name.prefix(21)) + "..."
    }
}
