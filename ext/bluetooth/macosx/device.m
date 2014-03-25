#import "ruby_bluetooth.h"

#import <IOBluetooth/objc/IOBluetoothDevicePair.h>

static IOBluetoothDevice *rbt_device_get(VALUE self) {
    BluetoothDeviceAddress address;
    IOBluetoothDevice *device;
    VALUE address_bytes;
    char * tmp = NULL;

    address_bytes = rb_funcall(self, rb_intern("address_bytes"), 0);

    if (RSTRING_LEN(address_bytes) != 6) {
        VALUE inspect = rb_inspect(address_bytes);
        rb_raise(rb_eArgError, "%s doesn't look like a bluetooth address",
                 StringValueCStr(inspect));
    }

    tmp = StringValuePtr(address_bytes);

    memcpy(address.data, tmp, 6);

    device = [IOBluetoothDevice deviceWithAddress: &address];

    return device;
}

VALUE rbt_device_link_quality(VALUE self) {
    IOBluetoothDevice *device;
    BluetoothHCIRSSIValue RSSI;
    VALUE rssi;
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    RSSI = [device RSSI];

    [pool release];

    rssi = INT2NUM(RSSI);

    rb_iv_set(self, "@link_quality", rssi);

    return rssi;
}

VALUE rbt_device_open_connection(VALUE self) {
    IOBluetoothDevice *device;
    IOReturn status;
    NSAutoreleasePool *pool;
    VALUE result;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    if (![device isConnected]) {
        status = [device openConnection];

        rbt_check_status(status, pool);
    }

    result = rb_yield(Qundef);

    status = [device closeConnection];

    [pool release];

    rbt_check_status(status, nil);

    return result;
}

VALUE rbt_device_pair(VALUE self) {
    PairingDelegate *delegate;
    IOBluetoothDevice *device;
    IOBluetoothDevicePair *device_pair;
    IOReturn status;
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    delegate = [[PairingDelegate alloc] init];
    delegate.device = self;

    device_pair = [IOBluetoothDevicePair pairWithDevice: device];
    [device_pair setDelegate: delegate];

    status = [device_pair start];

    rbt_check_status(status, pool);

    CFRunLoopRun();

    [pool release];

    status = (IOReturn)NUM2INT(rb_iv_get(self, "@pair_error"));

    rbt_check_status(status, nil);

    return Qtrue;
}

VALUE rbt_device_request_name(VALUE self) {
    IOBluetoothDevice *device;
    IOReturn status;
    VALUE name;
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    status = [device remoteNameRequest: nil];

    rbt_check_status(status, pool);

    name = rb_str_new2([[device name] UTF8String]);
    rb_enc_associate(name, rb_utf8_encoding());

    [pool release];

    return name;
}

VALUE rbt_device_rssi(VALUE self) {
    IOBluetoothDevice *device;
    BluetoothHCIRSSIValue rawRSSI;
    VALUE raw_rssi;
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];

    device = rbt_device_get(self);

    rawRSSI = [device rawRSSI];

    [pool release];

    raw_rssi = INT2NUM(rawRSSI);

    rb_iv_set(self, "@rssi", raw_rssi);

    return raw_rssi;
}

@implementation PairingDelegate

- (VALUE) device {
    return device;
}

- (void) setDevice: (VALUE)input {
    device = input;
}

- (void) devicePairingConnecting: (id)sender {
}

- (void) devicePairingStarted: (id)sender {
}

- (void) devicePairingFinished: (id)sender
                         error: (IOReturn)error {
    CFRunLoopStop(CFRunLoopGetCurrent());

    rb_iv_set(device, "@pair_error", INT2NUM(error));
}

- (void) devicePairingPasskeyNotification: (id)sender
				  passkey: (BluetoothPasskey)passkey {
    printf("passkey %ld!  I don't know what to do!", (unsigned long)passkey);
}

- (void) devicePairingPINCodeRequest: (id)sender {
    puts("PIN code! I don't know what to do!");
}

- (void) devicePairingUserConfirmationRequest: (id)sender
				 numericValue: (BluetoothNumericValue)numericValue {
    BOOL confirm;
    VALUE result = Qtrue;
    VALUE numeric_value = ULONG2NUM((unsigned long)numericValue);
    VALUE callback = rb_iv_get(device, "@pair_confirmation_callback");

    if (RTEST(callback))
        result = rb_funcall(callback, rb_intern("call"), 1, numeric_value);

    if (RTEST(result)) {
        confirm = YES;
    } else {
        confirm = NO;
    }

    [sender replyUserConfirmation: confirm];
}

@end

