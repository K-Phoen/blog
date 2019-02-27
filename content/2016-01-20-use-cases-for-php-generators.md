---
layout: post
title: Use cases for PHP generators
description: >
    Despite being available since PHP 5.5.0, generators are still largely
    underused. Let's see what how awesome they are through *real-world* cases.
---

Despite being available since PHP 5.5.0, generators are still largely underused.
In fact, it appears than most of the developers I know understand how generators
work but don't seem to see when they could be useful in *real-world* cases.

> Yeah, generators definitely look great but you know… except for computing the
> Fibonacci sequence, I don't see how it could be useful to me.

And they're not wrong, even the examples in PHP's documentation about generators
are pretty simplistic. They only show how to [efficiently implement `range`](http://php.net/manual/en/language.generators.overview.php)
or [iterate over the lines of a file](http://php.net/manual/en/language.generators.comparison.php).

But even from these simple examples we can understand the core aspects of
generators: they are *just* simplified `Iterator`s.

> A generator allows you to write code that uses `foreach` to iterate over a set
> of data without needing to build an array in memory

With that in mind, I'll try to explain why generators are awesome using some
use-cases taken from applications I work on in my company.

## Some context

I currently work for [TEA](https://twitter.com/TEA_tech). Basically, we develop
an e-book reading ecosystem.
It goes all the way from getting the e-book files from the publishers to present
them in an e-commerce website and allowing the final customer to read them online
(using a web-reader written by [@johanpoirier](https://twitter.com/johanpoirier))
or on an e-reader.

In order to be able to sell these e-books and display relevant information to
our customers, we need to have a lot of metadata for our products (title,
format, price, publisher, author(s), …).

For most of the code samples that will be shown below, I'll refer to these
metadata under the name of *e-book*.

So here we go!

## Iterating through large data-sets

For this first use-case, let's assume that I have a large collection of e-books
and I want to filter those which can be read in a web-reader.

Traditionally, I would write something like this:

```php
<?php
private function getEbooksEligibleToWebReader($ebooks)
{
    $rule = 'format = "EPUB" AND protection != "Adobe DRM"';
    $filteredEbooks = [];

    foreach ($ebooks as $ebook) {
        if ($this->rulerz->satisfies($ebook, $rule)) {
            $filteredEbooks[] = $ebook;
        }
    }

    return $filteredEbooks;
}
```

The problem here is easy to see: the more free e-books I have, the more
`$filteredEbooks` will consume memory.

A solution could be to create an iterator that would iterate through the
`$ebooks` and return the ones that are eligible. But we would have to create a
new class just for that and iterators are a bit tedious to write… Lucky us,
since PHP 5.5.0 we can use generators!

```php
<?php
private function getEbooksEligibleToWebReader($ebooks)
{
    $rule = 'format = "EPUB" AND protection != "Adobe DRM"';

    foreach ($ebooks as $ebook) {
        if ($this->rulerz->satisfies($ebook, $rule)) {
            yield $ebook;
        }
    }
}
```

Yep, refactoring the `getEbooksEligibleToWebReader` method to use generators is
as simple as replacing the assignation to `$filteredEbooks` by a `yield`
statement.

Assuming that `$ebooks` isn't an array with all the e-books but an iterator or
a generator (even better!), the memory consumption will now be constant, no
matter the number of eligible books and we are sure to find these books only if
and when we need them.

**Bonus**: [RulerZ](https://github.com/K-Phoen/rulerz) internally uses generators
so we could rewrite the method like this and be as efficient in terms of memory.

```php
<?php
private function getEbooksEligibleToWebReader($ebooks)
{
    $rule = 'format = "EPUB" AND protection != "Adobe DRM"';

    return $this->rulerz->filter($ebooks, $rule);
}
```

## Aggregating several data-sources

Now, let's consider the `$ebooks` retrieval part. I didn't tell you, but these
e-books come in fact from different data-sources: a relational database and
Elasticsearch.

We can then write a simple method to aggregate these two sources:

```php
<?php
private function getEbooks()
{
    $ebooks = [];

    // fetch from the DB
    $stmt = $this->db->prepare("SELECT * FROM ebook_catalog");
    $stmt->execute();
    $stmt->setFetchMode(\PDO::FETCH_ASSOC);

    foreach ($stmt as $data) {
        $ebooks[] = $this->hydrateEbook($data);
    }

    // and from Elasticsearch (findAll uses ES scan/scroll)
    $cursor = $this->esClient->findAll();

    foreach ($cursor as $data) {
        $ebooks[] = $this->hydrateEbook($data);
    }

    return $ebooks;
}
```

But once again, the amount of memory used by this method depends too much on the
number of e-books we have in the database and in Elasticsearch.

We could start by using generators to return the results:

```php
<?php
private function getEbooks()
{
    // fetch from the DB
    $stmt = $this->db->prepare("SELECT * FROM ebook_catalog");
    $stmt->execute();
    $stmt->setFetchMode(\PDO::FETCH_ASSOC);

    foreach ($stmt as $data) {
        yield $this->hydrateEbook($data);
    }

    // and from Elasticsearch (findAll uses ES scan/scroll)
    $cursor = $this->esClient->findAll();

    foreach ($cursor as $data) {
        yield $this->hydrateEbook($data);
    }
}
```

That's better, but we still have a problem: our `getBooks` method does too much
work! We should split the two responsibilities (reading in the database and
calling Elasticsearch) in two separate methods:

```php
<?php
private function getEbooks()
{
    yield from $this->getEbooksFromDatabase();
    yield from $this->getEbooksFromEs();
}

private function getEbooksFromDatabase()
{
    $stmt = $this->db->prepare("SELECT * FROM ebook_catalog");
    $stmt->execute();
    $stmt->setFetchMode(\PDO::FETCH_ASSOC);

    foreach ($stmt as $data) {
        yield $this->hydrateEbook($data);
    }
}

private function getEbooksFromEs()
{
    // and from Elasticsearch (findAll uses ES scan/scroll)
    $cursor = $this->esClient->findAll();

    foreach ($cursor as $data) {
        yield $this->hydrateEbook($data);
    }
}
```

You will notice the use of the `yield from` operator (available since PHP 7.0)
that allows to delegate the use of generators. That's perfect, for instance, to
aggregate several data-sources that use generators.

In fact, the `yield from` keyword works with any `Traversable` object, so arrays
or iterators can also be used with this delegation operator.

Using this keyword, we could aggregate several data-sources with only a few lines
of code:

```php
<?php
private function getEbooks()
{
    yield new Ebook(…);
    yield from [new Ebook(…), new Ebook(…)];
    yield from new ArrayIterator([new Ebook(…), new Ebook(…)]);
    yield from $this->getEbooksFromCSV();
    yield from $this->getEbooksFromDatabase();
}
```

## Complex, on-demand hydration for database rows

Another use-case I found for generators was the implementation of an on-demand
hydration that could handle relationships.

I had to import hundreds of thousands of orders from a legacy database into our
system, each order having several order lines.

Having both the order and the order lines was a pre-requisite for what we needed
to do, so I had to write a method that would be able to return hydrated orders
without being too slow or eating a lot of memory.

The idea is quite naive: join the order and the matching lines, and group order
and order lines together in a loop.

```php
<?php
public function loadOrdersWithItems()
{
    $oracleQuery = <<<SQL
SELECT o.*, item.*
FROM order_history o
INNER JOIN ORDER_ITEM item ON item.order_id = o.id
ORDER BY order.id
SQL;

    if (($stmt = oci_parse($oracleDb, $oracleQuery)) === false) {
        throw new \RuntimeException('Prepare fail in ');
    }
    if (oci_execute($stmt) === false) {
        throw new \RuntimeException('Execute fail in ');
    }

    $currentOrderId = null;
    $currentOrder = null;
    while (($row = oci_fetch_assoc($stmt)) !== false) {
        // did we move to the next order?
        if ($row['ID'] !== $currentOrderId) {
            if ($currentOrderId !== null) {
                yield $currentOrder;
            }

            $currentOrderId = $row['ID'];

            $currentOrder = $row;
            $currentOrder['lines'] = [];
        }

        $currentOrder['lines'][] = $row;
    }

    yield $currentOrder;
}
```

Using a generator, I managed to implement a method that could fetch orders from
the database and join the corresponding order lines. All of this while consuming
a stable amount of memory.
The generator removed the need to keep track of all the orders with their order
lines: the *current order* was all I needed to aggregate all the data.

## Simulating async tasks

Last but not least, generators can also be used to simulate asynchronous tasks.
While writing this post, I stumbled upon [@nikita_ppv](https://twitter.com/nikita_ppv)'s
post about the same subject, and as he is the one who originally implemented
generators in PHP, I'll just link to [his post](https://nikic.github.io/2012/12/22/Cooperative-multitasking-using-coroutines-in-PHP.html).

He quickly explains what are generators and explains (in depth) how we can take
advantage of the fact that they can both be interrupted and *send/receive data*
to implement coroutines and even cooperative multitasking.

## Wrapping up

Generators…

* … are simplified Iterators ;
* … can send an unlimited amount of data, without saturating the memory ;
* … can be aggregated using generators delegation ;
* … can be used to implement cooperative multitasking ;
* … are awesome!
