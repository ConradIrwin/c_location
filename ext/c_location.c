#include "c_location.h"

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
    Dl2_info info;
    VALUE file;
    VALUE offset;

    if(!dladdr(func, &info)) {
        rb_raise(rb_eRuntimeError, "could not find %s: %s", name, dlerror());
    }

    file = rb_str_new2(info.dli_fname);
    offset = LL2NUM((long long)(func - info.dli_fbase));

    return rb_ary_new3(2, file, offset);
}

static VALUE compiled_location(VALUE self);

void
Init_c_location()
{
    VALUE rb_mCompiledLocation = rb_define_module("CompiledLocation");

    rb_define_method(rb_mCompiledLocation, "compiled_location", compiled_location, 0);

    rb_include_module(rb_cMethod, rb_mCompiledLocation);
    rb_include_module(rb_cUnboundMethod, rb_mCompiledLocation);
}

#ifdef RUBY_19

#ifdef RUBY_193

static VALUE compiled_location(VALUE self)
{
    struct METHOD *data;
    VALUE name = rb_funcall(self, rb_intern("name"), 0);
          name = rb_funcall(name, rb_intern("to_s"), 0);

    // TODO: We're not validating that this is definitely a method struct.
    // It would be nice if we could use TypedData_Get_Struct, but we don't
    // have access to &method_data_type.
    data = (struct METHOD *)DATA_PTR(self);

    if (data->me->def->type != VM_METHOD_TYPE_CFUNC) {
        return Qnil;
    }

    return file_and_offset(*data->me->def->body.cfunc.func, StringValueCStr(name));
}

#else /* RUBY_192 */

static VALUE compiled_location(VALUE self)
{
    struct METHOD *data;
    VALUE name = rb_funcall(self, rb_intern("name"), 0);
          name = rb_funcall(name, rb_intern("to_s"), 0);

    // TODO: We're not validating that this is definitely a method struct.
    // It would be nice if we could use TypedData_Get_Struct, but we don't
    // have access to &method_data_type.
    data = (struct METHOD *)DATA_PTR(self);

    if (data->me.def->type != VM_METHOD_TYPE_CFUNC) {
        return Qnil;
    }

    return file_and_offset(*data->me.def->body.cfunc.func, StringValueCStr(name));
}


#endif
#else /* RUBY18 */

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
#endif
