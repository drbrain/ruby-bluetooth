#import "ruby_bluetooth.h"

struct scan_device_args {
    IOBluetoothDevice *device;
    VALUE devices;
};

extern VALUE rbt_cBluetoothDevice;

static void
scan_interrupt(void *ptr) {
    BluetoothDeviceScanner *bds = (BluetoothDeviceScanner *)ptr;

    [bds stopSearch];
}

static void *
scan_add_device(void *ptr) {
    struct scan_device_args *args = (struct scan_device_args *)ptr;
    IOBluetoothDevice *device     = args->device;
    VALUE name                    = Qnil;
    const char * device_name      = [[device name] UTF8String];

    VALUE address = rb_str_new2([[device addressString] UTF8String]);
    rb_enc_associate(address, rb_utf8_encoding());

    if (device_name) {
        name = rb_str_new2(device_name);
        rb_enc_associate(name, rb_utf8_encoding());
    }

    VALUE dev = rb_funcall(rbt_cBluetoothDevice, rb_intern("new"), 2,
                           address, name);

    rb_ary_push(args->devices, dev);

    return NULL;
}

static void *
scan_no_gvl(void *ptr) {
    CFRunLoopRun();

    return NULL;
}

VALUE
rbt_scan(VALUE self) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BluetoothDeviceScanner *bds = [BluetoothDeviceScanner new];

    [bds startSearch];

    rb_thread_call_without_gvl(scan_no_gvl, NULL, scan_interrupt, (void *)bds);

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
    struct scan_device_args args;

    args.device = device;
    args.devices = _devices;

    rb_thread_call_with_gvl(scan_add_device, (void *)&args);
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

