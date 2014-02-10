#import "ruby_bluetooth.h"
#import <IOKit/IOKitLib.h>

extern VALUE rbt_mBluetooth;
extern VALUE rbt_cBluetoothError;

VALUE errors;

void rbt_check_status(IOReturn status, NSAutoreleasePool *pool) {
    if (status != kIOReturnSuccess || status != noErr) {
        [pool release];

        rb_funcall(rbt_cBluetoothError, rb_intern("raise"), 1, INT2NUM(status));
    }
}

void add_error(IOReturn status, const char *name, const char *message) {
    VALUE klass;
    VALUE value;

    klass = rb_define_class_under(rbt_mBluetooth, name, rbt_cBluetoothError);
    value = rb_ary_new3(2, klass, rb_str_new2(message));
    rb_hash_aset(errors, INT2NUM(status), value);
}

void init_rbt_error() {
    VALUE tmp;

    errors = rb_const_get(rbt_mBluetooth, rb_intern("ERRORS"));

    tmp = rb_ary_new3(2, rbt_cBluetoothError, rb_str_new2("general error"));
    rb_hash_aset(errors, INT2NUM(kIOReturnError), tmp);

    // IOKit
    add_error(kIOReturnNoMemory,         "NoMemoryError",
            "can't allocate memory");
    add_error(kIOReturnNoResources,      "NoResourcesError",
            "resource shortage");
    add_error(kIOReturnIPCError,         "IPCError",
            "error during IPC");
    add_error(kIOReturnNoDevice,         "NoDeviceError",
            "no such device");
    add_error(kIOReturnNotPrivileged,    "NotPrivilegedError",
            "privilege violation");
    add_error(kIOReturnBadArgument,      "BadArgumentError",
            "invalid argument");
    add_error(kIOReturnLockedRead,       "LockedReadError",
            "device read locked");
    add_error(kIOReturnLockedWrite,      "LockedWriteError",
            "device write locked");
    add_error(kIOReturnExclusiveAccess,  "ExclusiveAccessError",
            "exclusive access and device already open");
    add_error(kIOReturnBadMessageID,     "BadMessageIDError",
            "sent/received messages had different msg_id");
    add_error(kIOReturnUnsupported,      "UnsupportedError",
            "unsupported function");
    add_error(kIOReturnVMError,          "VMError",
            "misc. VM failure");
    add_error(kIOReturnInternalError,    "InternalError",
            "internal error");
    add_error(kIOReturnIOError,          "IOError",
            "General I/O error");
    add_error(kIOReturnCannotLock,       "CannotLockError",
            "can't acquire lock");
    add_error(kIOReturnNotOpen,          "NotOpenError",
            "device not open");
    add_error(kIOReturnNotReadable,      "NotReadableError",
            "read not supported");
    add_error(kIOReturnNotWritable,      "NotWritableError",
            "write not supported");
    add_error(kIOReturnNotAligned,       "NotAlignedError",
            "alignment error");
    add_error(kIOReturnBadMedia,         "BadMediaError",
            "Media Error");
    add_error(kIOReturnStillOpen,        "StillOpenError",
            "device(s) still open");
    add_error(kIOReturnRLDError,         "RLDError",
            "rld failure");
    add_error(kIOReturnDMAError,         "DMAError",
            "DMA failure");
    add_error(kIOReturnBusy,             "BusyError",
            "Device Busy");
    add_error(kIOReturnTimeout,          "TimeoutError",
            "I/O Timeout");
    add_error(kIOReturnOffline,          "OfflineError",
            "device offline");
    add_error(kIOReturnNotReady,         "NotReadyError",
            "not ready");
    add_error(kIOReturnNotAttached,      "NotAttachedError",
            "device not attached");
    add_error(kIOReturnNoChannels,       "NoChannelsError",
            "no DMA channels left");
    add_error(kIOReturnNoSpace,          "NoSpaceError",
            "no space for data");
    add_error(kIOReturnPortExists,       "PortExistsError",
            "port already exists");
    add_error(kIOReturnCannotWire,       "CannotWireError",
            "can't wire down physical memory");
    add_error(kIOReturnNoInterrupt,      "NoInterruptError",
            "no interrupt attached");
    add_error(kIOReturnNoFrames,         "NoFramesError",
            "no DMA frames enqueued");
    add_error(kIOReturnMessageTooLarge,  "MessageTooLargeError",
            "oversized msg received on interrupt port");
    add_error(kIOReturnNotPermitted,     "NotPermittedError",
            "not permitted");
    add_error(kIOReturnNoPower,          "NoPowerError",
            "no power to device");
    add_error(kIOReturnNoMedia,          "NoMediaError",
            "media not present");
    add_error(kIOReturnUnformattedMedia, "UnformattedMediaError",
            "media not formatted");
    add_error(kIOReturnUnsupportedMode,  "UnsupportedModeError",
            "no such mode");
    add_error(kIOReturnUnderrun,         "UnderrunError",
            "data underrun");
    add_error(kIOReturnOverrun,          "OverrunError",
            "data overrun");
    add_error(kIOReturnDeviceError,      "DeviceError",
            "the device is not working properly!");
    add_error(kIOReturnNoCompletion,     "NoCompletionError",
            "a completion routine is required");
    add_error(kIOReturnAborted,          "AbortedError",
            "operation aborted");
    add_error(kIOReturnNoBandwidth,      "NoBandwidthError",
            "bus bandwidth would be exceeded");
    add_error(kIOReturnNotResponding,    "NotRespondingError",
            "device not responding");
    add_error(kIOReturnIsoTooOld,        "IsoTooOldError",
            "isochronous I/O request for distant past!");
    add_error(kIOReturnIsoTooNew,        "IsoTooNewError",
            "isochronous I/O request for distant future");
    add_error(kIOReturnNotFound,         "NotFoundError",
            "data was not found");
    add_error(kIOReturnInvalid,          "InvalidError",
            "should never be seen");

    // Bluetooth
    add_error(kBluetoothHCIErrorUnknownHCICommand, "UnknownHCICommandError",
            "unknown HCI command");
	add_error(kBluetoothHCIErrorNoConnection, "NoConnectionError",
            "no connection");
    add_error(kBluetoothHCIErrorHardwareFailure, "HardwareFailureError",
            "hardware failure");
	add_error(kBluetoothHCIErrorPageTimeout, "PageTimeoutError",
            "page timeout");
    add_error(kBluetoothHCIErrorAuthenticationFailure,
            "AuthenticationFailureError", "authentication failure");
	add_error(kBluetoothHCIErrorKeyMissing, "KeyMissingError", "key missing");
	add_error(kBluetoothHCIErrorMemoryFull, "MemoryFullError", "memory full");
	add_error(kBluetoothHCIErrorConnectionTimeout, "ConnectionTimeoutError",
            "connection timeout");
    add_error(kBluetoothHCIErrorMaxNumberOfConnections,
            "MaxNumberOfConnectionsError", "maximum number of connections");
    add_error(kBluetoothHCIErrorMaxNumberOfSCOConnectionsToADevice,
            "MaxNumberOfSCOConnectionsToADeviceError",
            "maximum number of synchronous connections to a device");
    add_error(kBluetoothHCIErrorACLConnectionAlreadyExists,
            "ACLConnectionAlreadyExistsError",
            "ACL connection already exists");
    add_error(kBluetoothHCIErrorCommandDisallowed, "CommandDisallowedError",
            "command disallowed");
    add_error(kBluetoothHCIErrorHostRejectedLimitedResources,
            "HostRejectedLimitedResourcesError",
            "host rejected, limited resources");
    add_error(kBluetoothHCIErrorHostRejectedSecurityReasons,
            "HostRejectedSecurityReasonsError",
            "host rejected, security reasons");
    add_error(kBluetoothHCIErrorHostRejectedRemoteDeviceIsPersonal,
            "HostRejectedRemoteDeviceIsPersonalError",
            "host rejected, remote device is personal");
	add_error(kBluetoothHCIErrorHostTimeout, "HostTimeoutError",
            "host timeout");
    add_error(kBluetoothHCIErrorUnsupportedFeatureOrParameterValue,
            "UnsupportedFeatureOrParameterValueError",
            "unsupported feature or parameter value");
    add_error(kBluetoothHCIErrorInvalidHCICommandParameters,
            "InvalidHCICommandParametersError",
            "invalid HCI command parameters");
    add_error(kBluetoothHCIErrorOtherEndTerminatedConnectionUserEnded,
            "OtherEndTerminatedConnectionUserEndedError",
            "the other end terminated the connection, by user");
    add_error(kBluetoothHCIErrorOtherEndTerminatedConnectionLowResources,
            "OtherEndTerminatedConnectionLowResourcesError",
            "the other end terminated the connection, low resources");
    add_error(kBluetoothHCIErrorOtherEndTerminatedConnectionAboutToPowerOff,
            "OtherEndTerminatedConnectionAboutToPowerOffError",
            "the other end terminated the connection, about to power off");
    add_error(kBluetoothHCIErrorConnectionTerminatedByLocalHost,
            "ConnectionTerminatedByLocalHostError",
            "connection terminated by local host");
	add_error(kBluetoothHCIErrorRepeatedAttempts, "RepeatedAttemptsError",
            "repeated attempts");
	add_error(kBluetoothHCIErrorPairingNotAllowed, "PairingNotAllowedError",
            "pairing is not allowed");
	add_error(kBluetoothHCIErrorUnknownLMPPDU, "UnknownLMPPDUError",
            "unknown LMP PDU");
    add_error(kBluetoothHCIErrorUnsupportedRemoteFeature,
            "UnsupportedRemoteFeatureError", "unsupported remote feature");
	add_error(kBluetoothHCIErrorSCOOffsetRejected, "SCOOffsetRejectedError",
            "SCO offset rejected");
    add_error(kBluetoothHCIErrorSCOIntervalRejected, "SCOIntervalRejectedError",
            "SCO interval rejected");
	add_error(kBluetoothHCIErrorSCOAirModeRejected, "SCOAirModeRejectedError",
            "SCO air mode rejected");
    add_error(kBluetoothHCIErrorInvalidLMPParameters,
            "InvalidLMPParametersError",
            "invalid LMP parameters");
	add_error(kBluetoothHCIErrorUnspecifiedError, "UnspecifiedError",
            "unspecified error");
    add_error(kBluetoothHCIErrorUnsupportedLMPParameterValue,
            "UnsupportedLMPParameterValueError",
            "unsupported LMP parameter value");
    add_error(kBluetoothHCIErrorRoleChangeNotAllowed,
            "RoleChangeNotAllowedError",
            "role change not allowed");
	add_error(kBluetoothHCIErrorLMPResponseTimeout, "LMPResponseTimeoutError",
            "LMP response timeout");
    add_error(kBluetoothHCIErrorLMPErrorTransactionCollision,
            "LMPErrorTransactionCollisionError",
            "LMP error transaction collision");
	add_error(kBluetoothHCIErrorLMPPDUNotAllowed, "LMPPDUNotAllowedError",
            "LMP DU not allowed");
    add_error(kBluetoothHCIErrorEncryptionModeNotAcceptable,
            "EncryptionModeNotAcceptableError",
            "encryption mode not acceptable");
	add_error(kBluetoothHCIErrorUnitKeyUsed, "UnitKeyUsedError",
            "unit key used");
	add_error(kBluetoothHCIErrorQoSNotSupported, "QoSNotSupportedError",
            "QoS not supported");
	add_error(kBluetoothHCIErrorInstantPassed, "InstantPassedError",
            "instant passed");
    add_error(kBluetoothHCIErrorPairingWithUnitKeyNotSupported,
            "PairingWithUnitKeyNotSupportedError",
            "pairing with unit key not supported");
    add_error(kBluetoothHCIErrorHostRejectedUnacceptableDeviceAddress,
            "HostRejectedUnacceptableDeviceAddressError",
            "host rejected, unacceptable device address");
    add_error(kBluetoothHCIErrorDifferentTransactionCollision,
            "DifferentTransactionCollisionError",
            "different transaction collision");
    add_error(kBluetoothHCIErrorQoSUnacceptableParameter,
            "QoSUnacceptableParameterError",
            "Qos unacceptable parameter");
	add_error(kBluetoothHCIErrorQoSRejected, "QoSRejectedError",
            "QoS rejected");
    add_error(kBluetoothHCIErrorChannelClassificationNotSupported,
            "ChannelClassificationNotSupportedError",
            "channel classification not supported");
    add_error(kBluetoothHCIErrorInsufficientSecurity,
            "InsufficientSecurityError",
            "insufficient security");
    add_error(kBluetoothHCIErrorParameterOutOfMandatoryRange,
            "ParameterOutOfMandatoryRangeError",
            "parameter out of mandatory range");
	add_error(kBluetoothHCIErrorRoleSwitchPending, "RoleSwitchPendingError",
            "role switch pending");
    add_error(kBluetoothHCIErrorReservedSlotViolation,
            "ReservedSlotViolationError", "reserved slot violation");
    add_error(kBluetoothHCIErrorRoleSwitchFailed, "RoleSwitchFailedError",
            "role switch failed");
    add_error(kBluetoothHCIErrorExtendedInquiryResponseTooLarge,
            "ExtendedInquiryResponseTooLargeError",
            "extended inquiry response too large");
    add_error(kBluetoothHCIErrorSecureSimplePairingNotSupportedByHost,
            "SecureSimplePairingNotSupportedByHostError",
            "secure simple pairing not supported by host");
}

