import CoreAudio
import Foundation

struct AudioDevice: Identifiable, Hashable {
    let id: String
    let audioDeviceID: AudioDeviceID
    let name: String
    let isDefault: Bool
    let transportType: UInt32

    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

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
