/* Load dladdr() function */
#include <dlfcn.h>

#include "ruby.h"
#include "node.h"

// TODO: why is it necessary to define this here? It ought to be in <dlfcn.h>
typedef struct {
   const char *dli_fname;  /* Pathname of shared object that contains address */
   void       *dli_fbase;  /* Address at which shared object is loaded */
   const char *dli_sname;  /* Name of nearest symbol with address lower than addr */
   void       *dli_saddr;  /* Exact address of symbol named in dli_sname */
} Dl_info;

/* Copy-pasted out of Ruby 1.8.7, not part of the official C API.*/
struct METHOD {
    VALUE klass, rklass;
    VALUE recv;
    ID id, oid;
    int safe_level;
    NODE *body;
};

/* Given the pointer to a C function (called "name" for error handling)
 * return the filename and offset of the compiled byte code for that function.
 *
 * This can then be used with a variety of Linux utilities to find more information about
 * that function. If you're really lucky, and your programs have been compiled with
 * debugging information (CFLAGS=-g) then this can even give you the original location of
 * the source code of the method.
 */
static VALUE file_and_offset(void *func, char *name)
{
    Dl_info info;
    VALUE file;
    VALUE offset;

    if(!dladdr(func, &info)) {
        rb_raise(rb_eRuntimeError, "could not find %s: %s", name, dlerror());
    }

    file = rb_str_new2(info.dli_fname);
    offset = LL2NUM((long long)(func - info.dli_fbase));

    return rb_ary_new3(2, file, offset);
}

static VALUE compiled_location(VALUE self)
{
    struct METHOD *data;
    VALUE name = rb_funcall(self, rb_intern("name"), 0);

    Data_Get_Struct(self, struct METHOD, data);

    if (nd_type(data->body) != NODE_CFUNC) {
        return Qnil;
    }

    return file_and_offset(*data->body->nd_cfnc, StringValueCStr(name));
}

void
Init_c_location()
{
    VALUE rb_mCompiledLocation = rb_define_module("CompiledLocation");

    rb_define_method(rb_mCompiledLocation, "compiled_location", compiled_location, 0);

    rb_include_module(rb_cMethod, rb_mCompiledLocation);
    rb_include_module(rb_cUnboundMethod, rb_mCompiledLocation);
}
