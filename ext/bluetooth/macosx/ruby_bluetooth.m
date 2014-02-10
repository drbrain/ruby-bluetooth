#import "ruby_bluetooth.h"

VALUE rbt_mBluetooth = Qnil;

VALUE rbt_cBluetoothDevice = Qnil;
VALUE rbt_cBluetoothERRORS = Qnil;
VALUE rbt_cBluetoothError = Qnil;

void Init_bluetooth() {
    rbt_mBluetooth = rb_define_module("Bluetooth");

    rbt_cBluetoothError  = rb_const_get(rbt_mBluetooth, rb_intern("Error"));

    rb_define_singleton_method(rbt_mBluetooth, "scan", rbt_scan, 0);

    rbt_cBluetoothDevice = rb_const_get(rbt_mBluetooth, rb_intern("Device"));

    rb_define_method(rbt_cBluetoothDevice, "connect",
            rbt_device_open_connection, 0);
    rb_define_method(rbt_cBluetoothDevice, "_link_quality",
            rbt_device_link_quality, 0);
    rb_define_method(rbt_cBluetoothDevice, "pair", rbt_device_pair, 0);
    rb_define_method(rbt_cBluetoothDevice, "request_name",
            rbt_device_request_name, 0);
    rb_define_method(rbt_cBluetoothDevice, "_rssi", rbt_device_rssi, 0);

    init_rbt_error();
}

