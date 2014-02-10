// Include the Ruby headers and goodies
#include <ruby.h>
#include <rubyio.h>
#include <rubysig.h>
#include <util.h>
#include "ruby_bluetooth.h"
#include <arpa/inet.h>

VALUE bt_module;
VALUE bt_devices_class;
VALUE bt_socket_class;
VALUE bt_rfcomm_socket_class;
VALUE bt_l2cap_socket_class;
VALUE bt_service_class;
VALUE bt_services_class;
VALUE bt_cBluetoothDevice;

// The initialization method for this module
void Init_bluetooth()
{
    bt_module = rb_define_module("Bluetooth");

    rb_define_singleton_method(bt_devices_class, "scan", bt_devices_scan, 0);
    rb_undef_method(bt_devices_class, "initialize");

    bt_socket_class = rb_define_class_under(bt_module, "BluetoothSocket", rb_cIO);
    rb_define_method(bt_socket_class, "inspect", bt_socket_inspect, 0);
    rb_define_method(bt_socket_class, "for_fd", bt_socket_s_for_fd, 1);
    rb_define_method(bt_socket_class, "listen", bt_socket_listen, 1);
    rb_define_method(bt_socket_class, "accept", bt_socket_accept, 0);
    rb_undef_method(bt_socket_class, "initialize");

    bt_rfcomm_socket_class = rb_define_class_under(bt_module, "RFCOMMSocket", bt_socket_class);
    rb_define_method(bt_rfcomm_socket_class, "initialize", bt_rfcomm_socket_init, -1);
    rb_define_method(bt_rfcomm_socket_class, "connect", bt_rfcomm_socket_connect, 2);
    rb_define_method(bt_rfcomm_socket_class, "bind", bt_rfcomm_socket_bind, 1);

    bt_l2cap_socket_class = rb_define_class_under(bt_module, "L2CAPSocket", bt_socket_class);
    rb_define_method(bt_l2cap_socket_class, "initialize", bt_l2cap_socket_init, -1);
    rb_define_method(bt_l2cap_socket_class, "connect", bt_l2cap_socket_connect, 2);
    rb_define_method(bt_l2cap_socket_class, "bind", bt_l2cap_socket_bind, 1);

    bt_services_class = rb_define_class_under(bt_module, "Services", rb_cObject);
    //rb_define_singleton_method(bt_services_class, "scan", bt_services_scan, 3);
    rb_undef_method(bt_services_class, "initialize");

    bt_service_class = rb_define_class_under(bt_module, "Service", rb_cObject);
    rb_define_singleton_method(bt_service_class, "new", bt_service_new, 4);
    rb_define_method(bt_service_class, "register", bt_service_register, 1);
    rb_define_method(bt_service_class, "unregister", bt_service_unregister, 0);
    rb_define_attr(bt_service_class, "uuid", Qtrue, Qfalse);
    rb_define_attr(bt_service_class, "name", Qtrue, Qfalse);
    rb_define_attr(bt_service_class, "description", Qtrue, Qfalse);
    rb_define_attr(bt_service_class, "provider", Qtrue, Qfalse);

    rb_define_method(bt_service_class, "registered?", bt_service_registered, 0);

    bt_cBluetoothDevice = rb_const_get(mBluetooth, rb_intern("Device"));
}

static VALUE bt_socket_accept(VALUE self) {
    OpenFile *fptr;
    VALUE sock2;
    char buf[1024];
    socklen_t len = sizeof(buf);

    //	struct sockaddr_rc rcaddr;
    //	addr_len = sizeof(rcaddr);

    GetOpenFile(self, fptr);
    //sock2 = s_accept(bt_socket_class, fileno(fptr->f), (struct sockaddr *)&rcaddr, &addr_len);
    sock2 = s_accept(bt_socket_class, fileno(fptr->f), (struct sockaddr *)buf, &len);
    return rb_assoc_new(sock2, rb_str_new(buf, len));
}


static VALUE
bt_socket_listen(sock, log)
VALUE sock, log;
{
    OpenFile *fptr;
    int backlog;

    rb_secure(4);
    backlog = NUM2INT(log);
    GetOpenFile(sock, fptr);
    if (listen(fileno(fptr->f), backlog) < 0)
        rb_sys_fail("listen(2)");

    return INT2FIX(0);
}


static VALUE bt_service_register(VALUE self, VALUE socket) {
    VALUE registered = rb_iv_get(self, "@registered");
    if (registered == Qfalse) {
        VALUE port_v = rb_iv_get(socket, "@port");
        if(Qnil == port_v) {
            rb_raise (rb_eIOError, "a bound socket must be passed");
        }

        //        uint32_t service_uuid_int[] = { 0, 0, 0, 0xABCD };
        const char *service_name = STR2CSTR(rb_iv_get(self, "@name"));
        const char *service_dsc = STR2CSTR(rb_iv_get(self, "@description"));
        const char *service_prov = STR2CSTR(rb_iv_get(self, "@provider"));

        uuid_t root_uuid, l2cap_uuid, rfcomm_uuid, svc_uuid;
        sdp_list_t *l2cap_list = 0,
                                 *rfcomm_list = 0,
                                                *root_list = 0,
                                                             *proto_list = 0,
                                                                           *access_proto_list = 0;
        sdp_data_t *channel = 0, *psm = 0;

        sdp_record_t *record = sdp_record_alloc();

        // set the general service ID
        //        sdp_uuid128_create( &svc_uuid, &service_uuid_int );
        char *service_id = STR2CSTR(rb_iv_get(self, "@uuid"));
        if(str2uuid(service_id, &svc_uuid) != 0) {
            rb_raise (rb_eIOError, "a valid uuid must be passed");
        }
        sdp_set_service_id( record, svc_uuid );

        // make the service record publicly browsable
        sdp_uuid16_create(&root_uuid, PUBLIC_BROWSE_GROUP);
        root_list = sdp_list_append(0, &root_uuid);
        sdp_set_browse_groups( record, root_list );

        // set l2cap information
        sdp_uuid16_create(&l2cap_uuid, L2CAP_UUID);
        l2cap_list = sdp_list_append( 0, &l2cap_uuid );
        if (bt_l2cap_socket_class == CLASS_OF(socket)) {
            uint16_t l2cap_port = FIX2UINT(port_v);
            psm = sdp_data_alloc(SDP_UINT16, &l2cap_port);
            sdp_list_append(l2cap_list, psm);
        }
        proto_list = sdp_list_append( 0, l2cap_list );

        // set rfcomm information
        sdp_uuid16_create(&rfcomm_uuid, RFCOMM_UUID);
        rfcomm_list = sdp_list_append( 0, &rfcomm_uuid );
        if (bt_rfcomm_socket_class == CLASS_OF(socket)) {
            uint16_t rfcomm_channel = FIX2UINT(port_v);
            channel = sdp_data_alloc(SDP_UINT8, &rfcomm_channel);
            sdp_list_append(rfcomm_list, channel);
        }
        sdp_list_append( proto_list, rfcomm_list );

        // attach protocol information to service record
        access_proto_list = sdp_list_append( 0, proto_list );
        sdp_set_access_protos( record, access_proto_list );

        // set the name, provider, and description
        sdp_set_info_attr(record, service_name, service_prov, service_dsc);
        int err = 0;
        sdp_session_t *session = 0;

        // connect to the local SDP server, register the service record, and
        // disconnect
        session = sdp_connect( BDADDR_ANY, BDADDR_LOCAL, SDP_RETRY_IF_BUSY );
        err = sdp_record_register(session, record, 0);

        // cleanup
        if (channel != 0) {
            sdp_data_free( channel );
        }
        sdp_list_free( l2cap_list, 0 );
        sdp_list_free( rfcomm_list, 0 );
        sdp_list_free( root_list, 0 );
        sdp_list_free( access_proto_list, 0 );

        struct bluetooth_service_struct *bss;
        Data_Get_Struct(self, struct bluetooth_service_struct, bss);
        bss->session = session;
        // Do something
        rb_iv_set(self, "@registered", Qtrue);
    }
    return Qnil;
}

static VALUE bt_service_unregister(VALUE self) {
    VALUE registered = rb_iv_get(self, "@registered");
    if (registered == Qtrue) {
        struct bluetooth_service_struct *bss;
        Data_Get_Struct(self, struct bluetooth_service_struct, bss);
        sdp_close(bss->session);
        bss->session = NULL;
        // Do something
        rb_iv_set(self, "@registered", Qfalse);
    }
    return registered;
}

static VALUE bt_service_registered(VALUE self) {
    VALUE registered = rb_iv_get(self, "@registered");
    if (registered == Qtrue) {
        // Do something
    }
    return registered;
}

static VALUE bt_service_new(VALUE self, VALUE uuid, VALUE name, VALUE description, VALUE provider) {
    struct bluetooth_service_struct *bss;

    VALUE obj = Data_Make_Struct(self,
                                 struct bluetooth_service_struct, NULL,
                                 free, bss);

    rb_iv_set(obj, "@uuid", uuid);
    rb_iv_set(obj, "@name", name);
    rb_iv_set(obj, "@description", description);
    rb_iv_set(obj, "@provider", provider);
    rb_iv_set(obj, "@registered", Qfalse);

    return obj;
}

static VALUE
bt_l2cap_socket_connect(VALUE self, VALUE host, VALUE port)
{
    OpenFile *fptr;
    int fd;

    GetOpenFile(self, fptr);
    fd = fileno(fptr->f);

    struct sockaddr_l2 addr = { 0 };
    char *dest = STR2CSTR(host);

    // set the connection parameters (who to connect to)
    addr.l2_family = AF_BLUETOOTH;
    addr.l2_psm = (uint8_t) FIX2UINT(port);
    str2ba( dest, &addr.l2_bdaddr );

    // connect to server
    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        rb_sys_fail("connect(2)");
    }

    return INT2FIX(0);
}

static VALUE
bt_rfcomm_socket_connect(VALUE self, VALUE host, VALUE port)
{
    OpenFile *fptr;
    int fd;

    GetOpenFile(self, fptr);
    fd = fileno(fptr->f);

    struct sockaddr_rc addr = { 0 };
    char *dest = STR2CSTR(host);

    // set the connection parameters (who to connect to)
    addr.rc_family = AF_BLUETOOTH;
    addr.rc_channel = (uint8_t) FIX2UINT(port);
    str2ba( dest, &addr.rc_bdaddr );

    // connect to server
    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        rb_sys_fail("connect(2)");
    }

    return INT2FIX(0);
}

static VALUE
bt_socket_s_for_fd(VALUE klass, VALUE fd)
{
    OpenFile *fptr;
    VALUE sock = bt_init_sock(rb_obj_alloc(klass), NUM2INT(fd));

    GetOpenFile(sock, fptr);
    return sock;
}

static VALUE
bt_rfcomm_socket_bind(VALUE self, VALUE port)
{
    OpenFile *fptr;
    int fd;

    GetOpenFile(self, fptr);
    fd = fileno(fptr->f);

    struct sockaddr_rc loc_addr = { 0 };
    loc_addr.rc_family = AF_BLUETOOTH;
    loc_addr.rc_bdaddr = *BDADDR_ANY;
    loc_addr.rc_channel = (uint8_t) FIX2UINT(port);

    if (bind(fd, (struct sockaddr *)&loc_addr, sizeof(loc_addr)) >= 0)
        rb_iv_set(self, "@port", port);
    return INT2FIX(0);
}

static VALUE
bt_l2cap_socket_bind(VALUE self, VALUE port)
{
    OpenFile *fptr;
    int fd;

    GetOpenFile(self, fptr);
    fd = fileno(fptr->f);

    struct sockaddr_l2 loc_addr = { 0 };
    loc_addr.l2_family = AF_BLUETOOTH;
    loc_addr.l2_bdaddr = *BDADDR_ANY;
    loc_addr.l2_psm = (uint8_t) FIX2UINT(port);

    if (bind(fd, (struct sockaddr *)&loc_addr, sizeof(loc_addr)) >= 0)
        rb_iv_set(self, "@port", port);
    return INT2FIX(0);
}

static VALUE bt_socket_inspect(VALUE self)
{
    return self;
}

static int
bt_ruby_socket(int domain, int type, int proto)
{
    int fd;

    fd = socket(domain, type, proto);
    if (fd < 0) {
        if (errno == EMFILE || errno == ENFILE) {
            rb_gc();
            fd = socket(domain, type, proto);
        }
    }
    return fd;
}

static VALUE
bt_init_sock(VALUE sock, int fd)
{
    OpenFile *fp = NULL;

    MakeOpenFile(sock, fp);

    fp->f = rb_fdopen(fd, "r");
    fp->f2 = rb_fdopen(fd, "w");
    fp->mode = FMODE_READWRITE;

    rb_io_synchronized(fp);

    return sock;
}

// Initialization of a RFCOMM socket
static VALUE bt_rfcomm_socket_init(int argc, VALUE *argv, VALUE sock)
{
    int fd = bt_ruby_socket(AF_BLUETOOTH, SOCK_STREAM, BTPROTO_RFCOMM);
    if (fd < 0) {
        rb_sys_fail("socket(2) - bt");
    }
    VALUE ret = bt_init_sock(sock, fd);
    return ret;
}

// Initialization of a L2CAP socket
static VALUE bt_l2cap_socket_init(int argc, VALUE *argv, VALUE sock)
{
    int fd = bt_ruby_socket(AF_BLUETOOTH, SOCK_SEQPACKET, BTPROTO_L2CAP);
    if (fd < 0) {
        rb_sys_fail("socket(2) - bt");
    }
    VALUE ret = bt_init_sock(sock, fd);
    return ret;
}

// Scan local network for visible remote devices
static VALUE bt_devices_scan(VALUE self)
{
    inquiry_info *ii = NULL;
    int max_rsp, num_rsp;
    int dev_id, sock, len, flags;
    int i;

    dev_id = hci_get_route(NULL);
    sock = hci_open_dev( dev_id );
    if (dev_id < 0 || sock < 0)
    {
        rb_raise (rb_eIOError, "error opening socket");
    }

    len  = 8;
    max_rsp = 255;
    flags = IREQ_CACHE_FLUSH;
    ii = (inquiry_info*)malloc(max_rsp * sizeof(inquiry_info));

    num_rsp = hci_inquiry(dev_id, len, max_rsp, NULL, &ii, flags);
    if( num_rsp < 0 )
        rb_raise(rb_eIOError, "hci_inquiry");

    VALUE devices_array = rb_ary_new();

    // Iterate over every device found and add it to result array
    for (i = 0; i < num_rsp; i++)
    {
        char addr[19] = { 0 };
        char name[248] = { 0 };

        ba2str(&(ii+i)->bdaddr, addr);
        memset(name, 0, sizeof(name));
        if (hci_read_remote_name(sock, &(ii+i)->bdaddr, sizeof(name),
                                 name, 0) < 0)
            strcpy(name, "(unknown)");

        VALUE bt_dev = rb_funcall(bt_cBluetoothDevice, rb_intern("new"), 2,
                rb_str_new(name), rb_str_new2(addr));

        rb_ary_push(devices_array, bt_dev);
    }

    free( ii );
    close( sock );
    return devices_array;
}

static VALUE
s_accept(VALUE klass, int fd, struct sockaddr *sockaddr, socklen_t *len) {
    int fd2;
    int retry = 0;

    rb_secure(3);
retry:
    rb_thread_wait_fd(fd);
#if defined(_nec_ews)
    fd2 = accept(fd, sockaddr, len);
#else
    TRAP_BEG;
    fd2 = accept(fd, sockaddr, len);
    TRAP_END;
#endif
    if (fd2 < 0) {
        switch (errno) {
        case EMFILE:
        case ENFILE:
            if (retry) break;
            rb_gc();
            retry = 1;
            goto retry;
        case EWOULDBLOCK:
            break;
        default:
            if (!rb_io_wait_readable(fd)) break;
            retry = 0;
            goto retry;
        }
        rb_sys_fail(0);
    }
    if (!klass) return INT2NUM(fd2);
    return bt_init_sock(rb_obj_alloc(klass), fd2);
}
// Code from PyBlueZ
int
str2uuid(char *uuid_str, uuid_t *uuid)
{
    uint32_t uuid_int[4];
    char *endptr;

    if(strlen(uuid_str) == 36) {
        // Parse uuid128 standard format: 12345678-9012-3456-7890-123456789012
        char buf[9] = { 0 };

        if(uuid_str[8] != '-' && uuid_str[13] != '-' &&
                uuid_str[18] != '-'  && uuid_str[23] != '-') {
            return -1;
        }
        // first 8-bytes
        strncpy(buf, uuid_str, 8);
        uuid_int[0] = htonl(strtoul(buf, &endptr, 16));
        if(endptr != buf + 8) return -1;

        // second 8-bytes
        strncpy(buf, uuid_str+9, 4);
        strncpy(buf+4, uuid_str+14, 4);
        uuid_int[1] = htonl(strtoul( buf, &endptr, 16));
        if(endptr != buf + 8) return -1;

        // third 8-bytes
        strncpy(buf, uuid_str+19, 4);
        strncpy(buf+4, uuid_str+24, 4);
        uuid_int[2] = htonl(strtoul(buf, &endptr, 16));
        if(endptr != buf + 8) return -1;

        // fourth 8-bytes
        strncpy(buf, uuid_str+28, 8);
        uuid_int[3] = htonl(strtoul(buf, &endptr, 16));
        if(endptr != buf + 8) return -1;

        if(uuid != NULL) sdp_uuid128_create(uuid, uuid_int);
    }

    else if(strlen(uuid_str) == 8) {
        // 32-bit reserved UUID
        uint32_t i = strtoul(uuid_str, &endptr, 16);
        if(endptr != uuid_str + 8) return -1;
        if(uuid != NULL) sdp_uuid32_create(uuid, i);
    }

    else if(strlen(uuid_str) == 6) {
        // 16-bit reserved UUID with 0x on front
        if(uuid_str[0] == '0' && (uuid_str[1] == 'x' || uuid_str[1] == 'X')) {
            // move chars up
            uuid_str[0] = uuid_str[2];
            uuid_str[1] = uuid_str[3];
            uuid_str[2] = uuid_str[4];
            uuid_str[3] = uuid_str[5];
            uuid_str[4] = '\0';
            int i = strtol(uuid_str, &endptr, 16);
            if(endptr != uuid_str + 4) return -1;
            if(uuid != NULL) sdp_uuid16_create(uuid, i);
        }

        else return(-1);
    }

    else if(strlen(uuid_str) == 4) {
        // 16-bit reserved UUID
        int i = strtol(uuid_str, &endptr, 16);
        if(endptr != uuid_str + 4) return -1;
        if(uuid != NULL) sdp_uuid16_create(uuid, i);
    }

    else {
        return -1;
    }

    return 0;
}




