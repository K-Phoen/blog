---
title: Write documentation as tests in PHP using Rusty
date: 2016-05-22
tags: [PHP]
---

Languages such as Python, Rust, etc. provide a way to write code samples right
inside doc-strings. They are supposed to be easy to read and they are called
"**documentation as tests**" because they also can be executed.

I thought that it was a great way to ensure that your documentation is
up-to-date with your code so I searched a way to do the same in PHP… but I could
not find anything.

And [Rusty](https://github.com/K-Phoen/Rusty) was born.

Rusty is an attempt at implementing the "documentation as tests" idea in the PHP
world.
It already is able to **extract code samples from** both PHP **doc-blocks and
Markdown** files (your documentation for instance).

I [set up Rusty in RulerZ's Ci process](https://github.com/K-Phoen/rulerz/commit/914a7813ffadd3175aa0ef47df9f5d78f46a20fe)
and [it found a few mistakes](https://github.com/K-Phoen/rulerz/commit/c91d954e537c1b9ee94384807e420c223da71e38)
in the documentation so there is a chance that even in the PHP world were
nothing is compiled, documentation as tests could be beneficial.
