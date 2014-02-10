#import "ruby_bluetooth.h"

@implementation HCIDelegate

- (VALUE) device {
    return device;
}

- (void) setDevice: (VALUE)input {
    device = input;
}


- (void) controllerClassOfDeviceReverted: (id)sender {
    printf("class of device reverted!\n");
}

- (void) readLinkQualityForDeviceComplete: (id)controller
                                   device: (IOBluetoothDevice*)bt_device
                                     info: (BluetoothHCILinkQualityInfo*)info
                                    error: (IOReturn)error {
    CFRunLoopStop(CFRunLoopGetCurrent());

    rb_iv_set(device, "@link_quality_error", INT2NUM(error));
    rb_iv_set(device, "@link_quality", UINT2NUM(info->qualityValue));
}

- (void) readRSSIForDeviceComplete: (id)controller
                            device: (IOBluetoothDevice*)bt_device
                              info: (BluetoothHCIRSSIInfo*)info
                             error: (IOReturn)error {
    CFRunLoopStop(CFRunLoopGetCurrent());

    rb_iv_set(device, "@rssi_error", INT2NUM(error));
    rb_iv_set(device, "@rssi", INT2NUM(info->RSSIValue));
}

@end

