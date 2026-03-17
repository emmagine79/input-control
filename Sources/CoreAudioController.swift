import CoreAudio
import Foundation

enum AudioDeviceError: LocalizedError {
    case osStatus(OSStatus, String)

    var errorDescription: String? {
        switch self {
        case let .osStatus(status, context):
            let reason = Self.readableStatus(status)
            return "\(context) failed — \(reason)."
        }
    }

    private static func readableStatus(_ status: OSStatus) -> String {
        switch status {
        case kAudioHardwareNotRunningError:
            return "the audio system is not running"
        case kAudioHardwareBadDeviceError:
            return "the device does not exist or was disconnected"
        case kAudioHardwareBadStreamError:
            return "the audio stream is invalid"
        case kAudioHardwareUnsupportedOperationError:
            return "this operation is not supported"
        case kAudioDeviceUnsupportedFormatError:
            return "the audio format is not supported"
        case kAudioHardwareUnknownPropertyError:
            return "the requested property does not exist"
        case kAudioHardwareBadPropertySizeError:
            return "unexpected property data size"
        default:
            return "error code \(status)"
        }
    }
}

final class CoreAudioController: @unchecked Sendable {
    private static let audioPropertyDidChange: AudioObjectPropertyListenerProc = { _, _, _, clientData in
        guard let clientData else {
            return noErr
        }

        let controller = Unmanaged<CoreAudioController>.fromOpaque(clientData).takeUnretainedValue()
        controller.lock.lock()
        let callback = controller._onChange
        controller.lock.unlock()
        callback?()
        return noErr
    }

    private let systemObjectID = AudioObjectID(kAudioObjectSystemObject)
    private var listenerAddresses: [AudioObjectPropertyAddress] = []
    private let lock = NSLock()
    private var _onChange: (() -> Void)?

    var onChange: (() -> Void)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _onChange
        }
        set {
            lock.lock()
            _onChange = newValue
            lock.unlock()
        }
    }

    init() {
        registerSystemListeners()
    }

    deinit {
        for var address in listenerAddresses {
            AudioObjectRemovePropertyListener(
                systemObjectID,
                &address,
                Self.audioPropertyDidChange,
                Unmanaged.passUnretained(self).toOpaque()
            )
        }
    }

    func inputDevices() throws -> [AudioDevice] {
        let defaultInputID = try defaultInputDeviceID()

        return try allDeviceIDs()
            .filter { try hasInputChannels(deviceID: $0) }
            .filter { try deviceIsAlive(deviceID: $0) }
            .map { deviceID in
                AudioDevice(
                    id: try deviceUID(deviceID: deviceID),
                    audioDeviceID: deviceID,
                    name: try deviceName(deviceID: deviceID),
                    isDefault: deviceID == defaultInputID,
                    transportType: try transportType(deviceID: deviceID)
                )
            }
            .sorted { lhs, rhs in
                if lhs.isDefault, !rhs.isDefault {
                    return true
                }

                if !lhs.isDefault, rhs.isDefault {
                    return false
                }

                if lhs.transportLabel != rhs.transportLabel {
                    return lhs.transportLabel.localizedStandardCompare(rhs.transportLabel) == .orderedAscending
                }

                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    func defaultInputDeviceID() throws -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID()
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

        try check(
            AudioObjectGetPropertyData(systemObjectID, &address, 0, nil, &propertySize, &deviceID),
            context: "Reading the default input device"
        )

        return deviceID
    }

    func setDefaultInputDevice(_ deviceID: AudioDeviceID) throws {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = deviceID
        let propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

        try check(
            AudioObjectSetPropertyData(systemObjectID, &address, 0, nil, propertySize, &deviceID),
            context: "Changing the default input device"
        )
    }

    private func registerSystemListeners() {
        let addresses = [
            AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDevices,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            ),
            AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultInputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
        ]

        for var address in addresses {
            let status = AudioObjectAddPropertyListener(
                systemObjectID,
                &address,
                Self.audioPropertyDidChange,
                Unmanaged.passUnretained(self).toOpaque()
            )

            if status == noErr {
                listenerAddresses.append(address)
            }
        }
    }

    private func allDeviceIDs() throws -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var propertySize = UInt32(0)

        try check(
            AudioObjectGetPropertyDataSize(systemObjectID, &address, 0, nil, &propertySize),
            context: "Reading the audio device list size"
        )

        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(), count: deviceCount)

        try check(
            AudioObjectGetPropertyData(systemObjectID, &address, 0, nil, &propertySize, &deviceIDs),
            context: "Reading the audio device list"
        )

        return deviceIDs
    }

    func deviceUID(deviceID: AudioDeviceID) throws -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        return try readCFString(from: deviceID, address: &address, context: "Reading an audio device UID")
            ?? "\(deviceID)"
    }

    func deviceID(forUID uid: String) -> AudioDeviceID? {
        guard let allIDs = try? allDeviceIDs() else {
            return nil
        }
        for id in allIDs {
            if let deviceUID = try? deviceUID(deviceID: id), deviceUID == uid {
                return id
            }
        }
        return nil
    }

    private func deviceName(deviceID: AudioDeviceID) throws -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        return try readCFString(from: deviceID, address: &address, context: "Reading an audio device name")
            ?? "Unknown Input"
    }

    private func transportType(deviceID: AudioDeviceID) throws -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transportType = UInt32(0)
        var propertySize = UInt32(MemoryLayout<UInt32>.size)

        try check(
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &propertySize, &transportType),
            context: "Reading an audio device transport type"
        )

        return transportType
    }

    private func deviceIsAlive(deviceID: AudioDeviceID) throws -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsAlive,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var isAlive = UInt32(0)
        var propertySize = UInt32(MemoryLayout<UInt32>.size)

        try check(
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &propertySize, &isAlive),
            context: "Reading an audio device availability"
        )

        return isAlive != 0
    }

    private func hasInputChannels(deviceID: AudioDeviceID) throws -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var propertySize = UInt32(0)

        try check(
            AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &propertySize),
            context: "Reading an input channel layout size"
        )

        let buffer = UnsafeMutableRawPointer.allocate(
            byteCount: Int(propertySize),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer {
            buffer.deallocate()
        }

        try check(
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &propertySize, buffer),
            context: "Reading an input channel layout"
        )

        let bufferList = buffer.assumingMemoryBound(to: AudioBufferList.self)
        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)

        return buffers.contains { $0.mNumberChannels > 0 }
    }

    /// Reads a CFString property from a CoreAudio object safely.
    /// CoreAudio string properties (name, UID) follow CF "Get" rule — caller does not own the reference.
    private func readCFString(
        from objectID: AudioDeviceID,
        address: inout AudioObjectPropertyAddress,
        context: String
    ) throws -> String? {
        var propertySize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var unmanagedRef: Unmanaged<CFString>?

        try check(
            AudioObjectGetPropertyData(objectID, &address, 0, nil, &propertySize, &unmanagedRef),
            context: context
        )

        guard let ref = unmanagedRef else {
            return nil
        }
        let value = (ref.takeUnretainedValue() as String).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func check(_ status: OSStatus, context: String) throws {
        guard status == noErr else {
            throw AudioDeviceError.osStatus(status, context)
        }
    }
}
