#include <unistd.h>
#include <sys/socket.h>
#include <bluetooth/bluetooth.h>
#include <bluetooth/rfcomm.h>
#include <bluetooth/l2cap.h>
#include <bluetooth/hci.h>
#include <bluetooth/hci_lib.h>
#include <bluetooth/sdp.h>
#include <bluetooth/sdp_lib.h>

// Prototype for the initialization method - Ruby calls this, not you
void Init_ruby_bluetooth();

struct bluetooth_device_struct
{
    VALUE addr;
    VALUE name;
};

struct bluetooth_service_struct
{
    VALUE uuid;
    VALUE name;
    VALUE description;
    VALUE provider;
    VALUE registered;
	sdp_session_t *session;
};

static VALUE bt_device_new(VALUE self, VALUE name, VALUE addr);

static VALUE bt_devices_scan(VALUE self);

static int bt_ruby_socket(int domain, int type, int proto);

static VALUE bt_init_sock(VALUE sock, int fd);

static VALUE bt_socket_inspect(VALUE self);

static VALUE bt_socket_s_for_fd(VALUE klass, VALUE fd);

static VALUE bt_socket_listen(VALUE klass, VALUE backlog);

static VALUE bt_socket_accept(VALUE sock);

static VALUE bt_rfcomm_socket_init(int argc, VALUE *argv, VALUE sock);

static VALUE bt_rfcomm_socket_connect(VALUE sock, VALUE host, VALUE port);

static VALUE bt_rfcomm_socket_bind(VALUE sock, VALUE port);

static VALUE bt_l2cap_socket_init(int argc, VALUE *argv, VALUE sock);

static VALUE bt_l2cap_socket_connect(VALUE sock, VALUE host, VALUE port);

static VALUE bt_l2cap_socket_bind(VALUE sock, VALUE port);

static VALUE bt_service_new(VALUE self, VALUE uuid, VALUE name, VALUE description, VALUE provider);

static VALUE bt_service_register(VALUE self, VALUE sock);

static VALUE bt_service_unregister(VALUE self);

static VALUE bt_service_registered(VALUE self);

int str2uuid(char *uuid_str, uuid_t *uuid);

static VALUE s_accept(VALUE klass, int fd, struct sockaddr *sockaddr, socklen_t *len);
