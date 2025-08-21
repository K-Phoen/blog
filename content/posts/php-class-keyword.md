---
title: PHP ::class keyword
date: 2016-01-15
tags: [til, PHP]
url: /til/2016/01/15/php-class-keyword/
tldr: >
    The `::class` keyword also works on classes that does not exist. It will
    only generate a FQCN, without actually autoloading the class and checking
    its existence.
---

According to PHP documentation about the `::class` keyword, it can be used for
class name resolution:

> You can get a string containing the fully qualified name of the ClassName
> class by using ClassName::class.

```php
namespace NS {
    class ClassName {
    }

    echo ClassName::class;
}

// outputs: "NS\ClassName"
```

It's handy when you need to pass FQCN around.
Some people even started using it to make sure that their code was referencing
existing classes.

Except that it's written nowhere in the documentation that this keyword will
ensure that the generated FQCN maps to an existing class!

In fact, you can use this keyword on classes that are neither defined nor
autoloadable.

```php
use Foo\Bar;

namespace NS {
    echo ClassThatDoesNotExist::class . PHP_EOL;
}

echo Bar::class;

// outputs:
// "NS\ClassThatDoesNotExist"
// "Foo\Bar"
```

Yup, `\NS\ClassThatDoesNotExist` won't be autoloaded. It's FQCN will just be
generated using the current namespace or `use` statements.
