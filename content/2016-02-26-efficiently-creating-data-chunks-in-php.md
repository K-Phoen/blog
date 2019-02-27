---
layout: post
title: Efficiently creating data chunks in PHP
description: >
    How to efficiently create chunks from several iterators in PHP?
---

While I was working on a library to build sitemaps and sitemap indexes, I
identified the need to aggregate several iterators and then build chunks of a
precise size from this aggregate.

To be clearer: given a list of URL providers for a sitemap index, I wanted to
iterate over all the data exposed by these providers in chunks of 50.000 (the
maximum number of URL allowed in a sitemap).

Each provider being an Iterator, I can *chain* them using nikic's [`iter`](https://github.com/nikic/iter)
library:

```php
<?php
$firstUrlProvider = …;
$secondUrlProvider = …;

$aggregatedProvider = iter\chain($firstUrlProvider, $secondUrlProvider);
```

I now have a way to iterate over all the URLs exposed by my providers, with a
single `foreach` statement.

My next issue comes from the need to build as much sitemap as I need, with a
maximum number of 50.000 URL in each sitemap and without knowing how much URL I
have nor storing anything unnecessary in memory.

To put it in other words: I want to be able to generate chunks of 50.000 URL
from my `$aggregatedProvider`, without storing the whole chunks in memory.

Looks like it's a job for PHP generators!

```php
<?php
function chunk(\Iterator $iterable, $size): \Iterator
{
    while ($iterable->valid()) {
        $closure = function() use ($iterable, $size) {
            $count = $size;
            while ($count-- && $iterable->valid()) {
                yield $iterable->current();
                $iterable->next();
            }
        };
        yield $closure();
    }
}
```

In the previous function, I delegate the iteration over my provider to a
Generator, that uses both the provider itself and the desired size of the chunk
to efficiently yield my URLs.

When put together, I obtain a nice way to iterate and make chunks from a large
amount of data.

As I said in [another blog post](http://blog.kevingomez.fr/2016/01/20/use-cases-for-php-generators/),
Generators are awesome!
