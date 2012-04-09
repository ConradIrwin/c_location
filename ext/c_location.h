/* Load dladdr() function */
#include <dlfcn.h>

#include "ruby.h"

// TODO: why is it necessary to define this here? It ought to be in <dlfcn.h>
typedef struct {
   const char *dli_fname;  /* Pathname of shared object that contains address */
   void       *dli_fbase;  /* Address at which shared object is loaded */
   const char *dli_sname;  /* Name of nearest symbol with address lower than addr */
   void       *dli_saddr;  /* Exact address of symbol named in dli_sname */
} Dl2_info;


#ifdef RUBY_19

typedef enum {
    NOEX_PUBLIC    = 0x00,
    NOEX_NOSUPER   = 0x01,
    NOEX_PRIVATE   = 0x02,
    NOEX_PROTECTED = 0x04,
    NOEX_MASK      = 0x06,
    NOEX_BASIC     = 0x08,
    NOEX_UNDEF     = NOEX_NOSUPER,
    NOEX_MODFUNC   = 0x12,
    NOEX_SUPER     = 0x20,
    NOEX_VCALL     = 0x40,
    NOEX_RESPONDS  = 0x80
} rb_method_flag_t;

typedef enum {
    VM_METHOD_TYPE_ISEQ,
    VM_METHOD_TYPE_CFUNC,
    VM_METHOD_TYPE_ATTRSET,
    VM_METHOD_TYPE_IVAR,
    VM_METHOD_TYPE_BMETHOD,
    VM_METHOD_TYPE_ZSUPER,
    VM_METHOD_TYPE_UNDEF,
    VM_METHOD_TYPE_NOTIMPLEMENTED,
    VM_METHOD_TYPE_OPTIMIZED, /* Kernel#send, Proc#call, etc */
    VM_METHOD_TYPE_MISSING   /* wrapper for method_missing(id) */
} rb_method_type_t;

typedef struct rb_method_cfunc_struct {
    VALUE (*func)(ANYARGS);
    int argc;
} rb_method_cfunc_t;

typedef struct rb_method_attr_struct {
    ID id;
    VALUE location;
} rb_method_attr_t;

typedef struct rb_iseq_struct rb_iseq_t;
typedef struct rb_method_definition_struct {
    rb_method_type_t type; /* method type */
    ID original_id;
    union {
        rb_iseq_t *iseq;            /* should be mark */
        rb_method_cfunc_t cfunc;
        rb_method_attr_t attr;
        VALUE proc;                 /* should be mark */
        enum method_optimized_type {
            OPTIMIZED_METHOD_TYPE_SEND,
            OPTIMIZED_METHOD_TYPE_CALL
        } optimize_type;
    } body;
    int alias_count;
} rb_method_definition_t;

typedef struct rb_method_entry_struct {
    rb_method_flag_t flag;
    char mark;
    rb_method_definition_t *def;
    ID called_id;
    VALUE klass;                    /* should be mark */
} rb_method_entry_t;

#ifdef RUBY_193

struct METHOD {
    VALUE recv;
    VALUE rclass;
    ID id;
    rb_method_entry_t *me;
    struct unlinked_method_entry_list_entry *ume;
};

#else /* RUBY_192 */

struct METHOD {
    VALUE recv;
    VALUE rclass;
    ID id;
    rb_method_entry_t me;
    struct unlinked_method_entry_list_entry *ume;
};

#endif

#else /* RUBY18 */

#include "node.h"

/* Copy-pasted out of Ruby 1.8.7, not part of the official C API.*/
struct METHOD {
    VALUE klass, rklass;
    VALUE recv;
    ID id, oid;
    int safe_level;
    NODE *body;
};

#endif
