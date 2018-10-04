# Explore empty struct in C

Executive summary, C guarantees every variable
has a unique address when comparing addresses:

```C
$ cat main.c
#include "stddef.h"
#include "stdint.h"
#include "stdio.h"
#include "stdlib.h"
#include "memory.h"

#undef NDEBUG
#include "assert.h"

struct Empty {};

struct NestedEmpty {
  struct Empty e;
};

struct Full {
  struct Empty e1;
  int32_t a;
  struct Empty e2;
};

int main() {
  int32_t a = 0;
  struct Empty s;
  struct NestedEmpty ne;
  struct Full f;

  f.a = 1;
  
  printf("%-10s=%20zu\n", "sizeof(a)", sizeof(a));
  printf("%-10s=%20zu\n", "sizeof(s)", sizeof(s));
  printf("%-10s=%20zu\n", "sizeof(ne)", sizeof(ne));
  printf("%-10s=%20zu\n", "sizeof(f)", sizeof(f));
  assert(sizeof(a) == 4);
  assert(sizeof(s) == 0);
  assert(sizeof(ne) == 0);
  assert(sizeof(f) == 4);

  printf("%-10s=%20p\n", "&a", &a);
  printf("%-10s=%20p\n", "&s", &s);
  printf("%-10s=%20p\n", "&ne", &ne);
  printf("%-10s=%20p\n", "&ne.e", &ne.e);
  printf("%-10s=%20p\n", "&f", &f);
  printf("%-10s=%20p\n", "&f.e1", &f.e1);
  printf("%-10s=%20p\n", "&f.a", &f.a);
  printf("%-10s=%20p\n", "&f.e2", &f.e2);
  assert(&a != NULL);
  assert(&s != NULL);
  assert(&ne != NULL);
  assert(&ne.e != NULL);
  assert(&f.e1 != NULL);
  assert(&f.a != NULL);
  assert(&f.e2 != NULL);
  assert((uintptr_t)&a != (uintptr_t)&s);
  assert((uintptr_t)&s != (uintptr_t)&ne);
  assert((uintptr_t)&ne == (uintptr_t)&ne.e);
  assert((uintptr_t)&f != (uintptr_t)&ne);
  assert((uintptr_t)&f == (uintptr_t)&f.e1);
  assert((uintptr_t)&f.e1 == (uintptr_t)&f.a);
  assert((uintptr_t)&f.a != (uintptr_t)&f.e2);
        
  printf("%-35s=%4zu\n", "offsetof(struct NestedEmpty, e)", offsetof(struct NestedEmpty, e));
  printf("%-35s=%4zu\n", "offsetof(struct Full, e1)", offsetof(struct Full, e1));
  printf("%-35s=%4zu\n", "offsetof(struct Full, a)", offsetof(struct Full, a));
  printf("%-35s=%4zu\n", "offsetof(struct Full, e2)", offsetof(struct Full, e2));
  assert(offsetof(struct NestedEmpty, e) == 0);
  assert(offsetof(struct Full, e1) == 0);
  assert(offsetof(struct Full, a) == 0);
  assert(offsetof(struct Full, e2) == 4);

  return 0;
}
```

All asserts pass and all variables have different addresses:
```
$ make clean && make && ./main
rm -rf main *.o *.s
gcc -O0 -c main.c -o main.o
gcc -o main main.o
sizeof(a) =                   4
sizeof(s) =                   0
sizeof(ne)=                   0
sizeof(f) =                   4
&a        =      0x7ffc7fc22530
&s        =      0x7ffc7fc2252e
&ne       =      0x7ffc7fc2252f
&ne.e     =      0x7ffc7fc2252f
&f        =      0x7ffc7fc22534
&f.e1     =      0x7ffc7fc22534
&f.a      =      0x7ffc7fc22534
&f.e2     =      0x7ffc7fc22538
offsetof(struct NestedEmpty, e)    =   0
offsetof(struct Full, e1)          =   0
offsetof(struct Full, a)           =   0
offsetof(struct Full, e2)          =   4
```

An interesting observation is that when using clang and -O2
the addresses of `s` and `ne` are actually the same value,
0x7ffc98290b38. But the compiler "knows" they are not
supposed to be equal and optimizes appropriately:
```
$ make clean && make CC=clang CFLAGS=-O2 && ./main
rm -rf main *.o *.s
clang -O2 -c main.c -o main.o
clang -o main main.o
sizeof(a) =                   4
sizeof(s) =                   0
sizeof(ne)=                   0
sizeof(f) =                   4
&a        =      0x7ffc98290b34
&s        =      0x7ffc98290b38
&ne       =      0x7ffc98290b38
&ne.e     =      0x7ffc98290b38
&f        =      0x7ffc98290b30
&f.e1     =      0x7ffc98290b30
&f.a      =      0x7ffc98290b30
&f.e2     =      0x7ffc98290b34
offsetof(struct NestedEmpty, e)    =   0
offsetof(struct Full, e1)          =   0
offsetof(struct Full, a)           =   0
offsetof(struct Full, e2)          =   4
```

So, for instance, if I change the `assert((uintptr_t)&s != (uintptr_t)&ne);`
to `==` the code will abort:
```
$ make clean && make CC=clang CFLAGS=-O2 && ./main
rm -rf main *.o *.s
clang -O2 -c main.c -o main.o
clang -o main main.o
sizeof(a) =                   4
sizeof(s) =                   0
sizeof(ne)=                   0
sizeof(f) =                   4
&a        =      0x7ffdd29b8454
&s        =      0x7ffdd29b8448
&ne       =      0x7ffdd29b8448
&ne.e     =      0x7ffdd29b8448
&f        =      0x7ffdd29b8450
&f.e1     =      0x7ffdd29b8450
&f.a      =      0x7ffdd29b8450
&f.e2     =      0x7ffdd29b8454
main: main.c:55: int main(): Assertion `(uintptr_t)&s == (uintptr_t)&ne' failed.
Aborted (core dumped)
```
