---
title: Parallel bundle install
date: 2015-07-12
tags: [til]
url: /til/2015/07/12/parallel-bundle-install/
---

In ruby projects, the `bundle install` command is known to be quite slow. To
mitigate this, Bundler provides an option allowing to install gems using
parallel workers: `bundle install --jobs 4`. Just tell Bundler how many
concurrent jobs can be launched and let it work.
