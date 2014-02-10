// Prototype for the initialization method - Ruby calls this, not you
void Init_ruby_bluetooth();

struct bluetooth_device_struct
  {
    VALUE addr;
    VALUE name;
  };

static VALUE bt_device_new(VALUE self, VALUE name, VALUE addr);

static VALUE bt_devices_scan(VALUE self);

static VALUE bt_socket_s_for_fd(VALUE klass, VALUE fd);

static VALUE bt_socket_inspect(VALUE self);

static VALUE bt_init_sock(VALUE sock, int fd);

static int bt_ruby_socket(int domain, int type, int proto);

static VALUE bt_rfcomm_socket_init(int argc, VALUE *argv, VALUE sock);

static VALUE bt_rfcomm_socket_connect(VALUE self, VALUE host, VALUE port);
