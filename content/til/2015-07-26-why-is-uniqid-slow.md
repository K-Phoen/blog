---
layout:      post
title:       Why is uniqid() slow?
category:    til
description: While profiling [RulerZ](https://github.com/K-Phoen/rulerz) with [Blackfire.io](https://blackfire.io/), I noticed that a non-negligible amount of time was consumed by PHP's `uniqid()` function. I found it odd that it consumed so much time and started to investigate why.

tldr: >
    If called without `$more_entropy = true`, `uniqid()` calls sleep for **at
    least** 1 microsecond.
    `uniqid($prefix, $more_entropy = true)` will prevent function from sleeping.
---

While profiling [RulerZ](https://github.com/K-Phoen/rulerz) with
[Blackfire.io](https://blackfire.io/), I noticed that a non-negligible amount of
time was consumed by PHP's `uniqid()` function.

For those who don't know, this function provides an easy way to generate unique
identifiers **based on the current date** and an optional prefix.

Wait, the "*current date*" part can actually be interesting for our performance
issue. What happens if we write something like this:

```php
<?php

foreach ($foo as $bar) {
    $awesomeCollection[] = new CoolObject(uniqid(), $bar);
}
```

A simple loop like this should run pretty fast, so if `uniqid()` simply relies
on the current date we should have collisions... but it is not the case. Why?

The answer to this question lies in [the implementation of
`uniqid()`](https://github.com/php/php-src/blob/cd37e7c90d1745fe433ac66e8e0ec53eda388577/ext/standard/uniqid.c#L68):
in order to avoid time-induced collisions on the same host, `uniqid()` literally
waits before getting the current date. That's why there is a `usleep(1)` call
in the function's implementation.

But wait, there's more. As the *man* page for `usleep` says, "<cite>The usleep()
function **suspends execution** of the calling thread for (**at least**) usec
microseconds.  The sleep may be lengthened slightly by any system activity or by
the time spent processing the call or by the granularity of system timers.</cite>".

Yup, if you're not lucky `usleep(n)` calls can suspend the execution for more
than *n* microseconds.

Now, you may have noticed that the `usleep()` call is conditioned by the
`more_entropy` variable, which happens to be a parameter exposed in the user-land
`uniqid`.
By setting `more_entropy` to `true`, we choose to provide an additional source
of entropy by appending data using [`php_combined_lcg()`](https://github.com/php/php-src/blob/master/ext/standard/lcg.c#L44-L74) (a pseudo-random number
generator), thus preventing time-induced collisions without having to sleep.

So if you use `uniqid()`, make sure that the `$more_entropy` parameter is set
to `true`.
