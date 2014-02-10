#import "ruby_bluetooth.h"

extern VALUE rbt_cBluetoothDevice;

VALUE rbt_scan(VALUE self) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BluetoothDeviceScanner *bds = [BluetoothDeviceScanner new];

    [bds startSearch];

    CFRunLoopRun();

    [pool release];

    return [bds devices];
}

@implementation BluetoothDeviceScanner

- (void) deviceInquiryComplete:(IOBluetoothDeviceInquiry*)sender
                         error:(IOReturn)error aborted:(BOOL)aborted {
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void) deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry*)sender
                           device:(IOBluetoothDevice*)device {
    VALUE address;
    VALUE name = Qnil;
    const char * device_name = [[device name] UTF8String];

    address = rb_str_new2([[device getAddressString] UTF8String]);

    if (device_name)
        name = rb_str_new2(device_name);

    VALUE dev = rb_funcall(rbt_cBluetoothDevice, rb_intern("new"), 2,
                           address, name);

    rb_ary_push(_devices, dev);
}

- (void) deviceInquiryDeviceNameUpdated:(IOBluetoothDeviceInquiry*)sender
                                 device:(IOBluetoothDevice*)device
                       devicesRemaining:(uint32_t)devicesRemaining {
    // do something
}

- (void) deviceInquiryUpdatingDeviceNamesStarted:(IOBluetoothDeviceInquiry*)sender
                                devicesRemaining:(uint32_t)devicesRemaining {
    // do something
}

- (IOReturn) startSearch {
    IOReturn status;

    [self stopSearch];

    _inquiry = [IOBluetoothDeviceInquiry inquiryWithDelegate:self];
    _devices = rb_ary_new();

    [_inquiry setUpdateNewDeviceNames: TRUE];

    status = [_inquiry start];

    if (status == kIOReturnSuccess) {
        [_inquiry retain];

        _busy = TRUE;
    }

    return status;
}

- (void) stopSearch {
    if (_inquiry) {
        [_inquiry stop];

        [_inquiry release];
        _inquiry = nil;
    }
}

- (VALUE) devices {
    return _devices;
}
@end

