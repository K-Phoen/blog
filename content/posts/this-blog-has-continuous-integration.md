---
title: This blog has continuous integration
date: 2019-11-24
---

It's probably not a surprise for most of the people reading this blog but I am
a software engineer. And as such I spend most of my time writing code, checked
in a VCS, reviewed by peers and analyzed by tools before being deployed.

Isn't it only natural that the content of this blog followed the same rules?

<!--more-->

For some time now, this [blog](https://github.com/K-Phoen/blog) has been
written in [Markdown](https://en.wikipedia.org/wiki/Markdown) and transformed
into a static website using [Hugo](https://github.com/gohugoio/hugo/).

This works pretty well — especially since the deployment is semi-automated via
a few lines of bash — but occasionally a few mistakes end-up being deployed.
Incorrectly formatted Markdown, words misspelled or even
insensitive/inconsiderate writing (English not being my native tongue doesn't
help).

Like I would do with any piece of code, I decided to introduce a *Continuous
Integration* pipeline in order to minimize the risks. And to be fair, it was
also the perfect occasion to play a bit with GitHub Actions!

This pipeline relies on four different actions:

* [`nosborn/github-action-markdown-cli`](https://github.com/nosborn/github-action-markdown-cli)
  to make sure that the Markdown files are correct ;
* [`reviewdog/action-misspell`](https://github.com/reviewdog/action-misspell)
  to check my spelling ;
* [`theashraf/alex-action`](https://github.com/theashraf/alex-action) to prevent
  any usage of inconsiderate writing ;
* [`peaceiris/actions-hugo`](https://github.com/peaceiris/actions-hugo) to
  ensure that the blog will compile.

The action definition looks like this:

```yaml
name: CI
on: [pull_request]

jobs:
  markdown:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v1
        with:
          depth: 1

      - uses: nosborn/github-action-markdown-cli@master
        with:
          files: ./content/

  language:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v1
        with:
          depth: 1

      - uses: reviewdog/action-misspell@v1
        with:
          github_token: ${{ github.token }}
          locale: "US"

      - name: alexjs
        uses: theashraf/alex-action@master

  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v1
        with:
          depth: 1

      - uses: peaceiris/actions-hugo@v2.3.0
        with:
          hugo-version: '0.59.1'

      - run: hugo
```

And as a bonus, the deployment is also automated using a GitHub action (written
by me, this time):

```yaml
name: Deploy
on:
  push:
    branches: [master]

jobs:
  hugo_deploy:
    name: Hugo
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v1
        with:
          depth: 1
          submodules: true
          token: ${{ secrets.GITHUB_PERSONAL_ACCESS_TOKEN }}

      - uses: K-Phoen/hugo-gh-pages-action@master
        with:
          github_token: ${{ secrets.GITHUB_PERSONAL_ACCESS_TOKEN }}
```

The only thing left for me is to start writing more!
