---
layout: post
title: 'Digging into: Humbug'
description: >
    How does Humbug mutate source code?
tldr: >
    In the end, the mutation generation by Humbug is *pretty straightforward*:

    1. it starts by splitting the code in tokens, using the standard `token_get_all()` function

    2. then it applies a list of *mutators* to the previously generated tokens. A
       mutator being responsible to alter tokens (ie: replacing a `+` with a `-`)

    3. once all the mutators are applied, it uses the tokens to rebuild the source
       code.

    4. code having changed, the unit tests should fail. So it launches them and
       expects failures.

    Now I see why I didn't find something like nikic/PHP-parser in the dependencies:
    it simply would have been overkill and too complex to work with an AST.
---

While I've already used [Humbug](https://github.com/padraic/humbug) a few time,
a [recent article](http://blog.eleven-labs.com/en/mutation-testing-check-quality-unit-tests/)
made my realise that I didn't really know how it worked.

That's when I got the idea to dig into Humbug to learn how it works, and publish
my findings here.

Before we start, let's quickly give some context on Humbug.

## What's Humbug?

« *Humbug is a Mutation Testing framework for PHP* »

In a nutshell, you write unit tests to prevent regressions in your application
and use *code coverage* as an indicator of how well your application is tested
or protected.

Mutation testing comes after the redaction of these tests and helps you to judge
how well your unit tests actually protect your code.

To do that, mutation testing tools inject small defects into your source code
and then check if the unit tests noticed the changes. If they did, then the
coverage is sufficient and we say that they *killed the mutation*. If they didn't,
then you have a problem because the *mutation escaped*.

According to Humbug's README, mutations usually involve:
* switching binary arithmetic operators: `+` becomes `-`, `*` becomes `/`, …
* substituting logical operations: `&&` becomes `||`, `true` becomes `false`, …
* inversing conditions: `>` becomes `<`, `===` becomes `!===`, …
* …

The purpose of this article is to answer the following question: how does
Humbug manipulate your code? How are mutations generated?

## The analysis

What follows is a redacted transcription of my investigation in Humbug's source
code.


### First step: `composer.json`

I'll use the `composer.json` file as entry point to this analysis. The goal here
is to see if there is a dependency that could be use to analyse and manipulate
source code. I'm thinking about a library like
[nikic/PHP-Parser](https://github.com/nikic/PHP-Parser) for instance.

```json
{
    …
    "require": {
        "php": ">=5.4.0",
        "phpunit/phpunit": "^4.5|^5.0",
        "symfony/console": "^2.6|^3.0",
        "symfony/finder": "^2.6|^3.0",
        "symfony/process": "^2.6|^3.0",
        "symfony/event-dispatcher": "^2.6|^3.0",
        "sebastian/diff": "^1.1",
        "padraic/phpunit-accelerator": "^1.0.2",
        "padraic/phpunit-extensions": "^1.0.0",
        "padraic/phar-updater": "^1.0.0"
    },
    …
}
```

After reading the dependencies list, I see nothing that would help to manipulate
source code.

I do see interesting things though:
* `phpunit/phpunit` is a hard dependency: meaning that Humbug won't work with
  other test frameworks
* `symfony/finder` and `symfony/process`: common components used to find files
  and launch processes
* `sebastian/diff`: could be used to generate diffs between original source code
  and mutants

If there is nothing useful in the dependencies, it means that the source
manipulation is in Humbug's repository.

### Time to read some code!

When I open the sources, the [`Mutator`](https://github.com/padraic/humbug/tree/06b1c059e432dab8c22c36bc8b6e1ffc7e587c07/src/Mutator)
directory immediately catches my eye. So let's see what's inside.

```
src/Mutator
├── Arithmetic
├── Boolean
├── ConditionalBoundary
├── ConditionalNegation
├── IfStatement
├── Increment
├── MutatorAbstract.php
├── Number
└── ReturnValue
```

First thought: it reminds me of the mutations listed in the README. Let's open a
file to check it. I'll begin with [`src/Mutator/Arithmetic/Addition.php`](https://github.com/padraic/humbug/blob/06b1c059e432dab8c22c36bc8b6e1ffc7e587c07/src/Mutator/Arithmetic/Addition.php).

The `Addition` class contains two methods: `getMutation(array &$tokens, $index)`
and `mutates(array &$tokens, $index)`. Both of them receive an array of *tokens*
which indicates that Humbug operates at the token level, not at the AST level.

**N.B**: a list of *tokens* is usually the result of the lexical analysis,
which is the process of converting a source code into a sequence of strings — or
tokens — with a precise signification (identifier, literal, assignment operator,
…).

The method `getMutation()` seems to be the one applying the mutation:

```php
<?php
/**
 * Replace plus sign (+) with minus sign (-)
 *
 * @param array $tokens
 * @param int $index
 * @return array
 */
public static function getMutation(array &$tokens, $index)
{
    $tokens[$index] = '-';
}
```

The method `mutates()`, on the other hand, checks whether the current mutation
can be applied on the given token. This method's docblock gives a really
meaningful example where it can't: `$var = ['foo' => true] + ['bar' => true]`

**N.B**: I think that the documentation for these two methods is well redacted
and useful.

By reading the implementation of the `mutates()` method, I noticed the usage of
the `T_ARRAY` constant. This constant being provided by PHP itself, its usage leads
me to believe that the tokenization of the source code isn't done by hand by
Humbug, but delegated to a function provided by PHP's standard library:
[`token_get_all()`](http://php.net/manual/fr/function.token-get-all.php).

That being said, the tokenization process itself isn't done in the `Addition`
class. Let's inspect its parent: [`MutatorAbstract`](https://github.com/padraic/humbug/blob/06b1c059e432dab8c22c36bc8b6e1ffc7e587c07/src/Mutator/MutatorAbstract.php)

In addition to the "*utility*" methods, this class has an interesting method
that performs the mutation on the given tokens and returns the result as source
code:

```php
<?php
/**
 * Perform a mutation against the given original source code tokens for
 * a mutable element
 *
 * @param array $tokens
 * @param int $index
 * @return string
 */
public static function mutate(array &$tokens, $index)
{
    static::getMutation($tokens, $index);
    return Tokenizer::reconstructFromTokens($tokens);
}
```

What's interesting here is the usage of a `Tokenizer` class.

At this stage, I already know that Humbug manipulates tokens and rewrites them
to generate *mutants*, but I still didn't see the code responsible for the tokenization
process itself or even the reconstruction of the code source from the modified
tokens.

Logically, I expect to find all of this in the [`Tokenizer`](https://github.com/padraic/humbug/blob/06b1c059e432dab8c22c36bc8b6e1ffc7e587c07/src/Utility/Tokenizer.php).

And bingo! The class contains the two expected methods: `reconstructFromTokens()`
and `getTokens()`.

The tokenization is indeed done using [`token_get_all()`](http://php.net/manual/en/function.token-get-all.php).
According to the documentation, this function returns an array of token identifiers.
Each individual token identifier is either a single character (i.e.: ;, ., >, !, etc...),
or a three element array containing the token index in element 0, the string
content of the original token in element 1 and the line number in element 2.

All of these information allow us to analyze the tokens and reconstruct the
original source code. That's exactly what Humbugs does: mystery solved!

### Where are the mutations generated?

So far, we've seen how a single mutation manipulates the tokens generated by the
`Tokenizer`. The last thing that I'd like to determine is, given a file, how are
the mutations generated?

When going back to the `src/` directory, I notice the `Mutable` class which
could represent a mutable file/source code.

And indeed, when opening it I see that the constructor accepts a file name!
I also notice that the `$mutators` attribute contains a list of all the
possible mutations.

Farther in the file is the `generate()` method. It's were the file is opened,
tokenized (using the `Tokenizer`) and modified using the mutators.

One interesting thing: the mutators are applied only to method bodies!
