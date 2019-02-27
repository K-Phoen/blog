---
layout:      post
title:       Parallel bundle install
category:    til
---

In ruby projects, the `bundle install` command is known to be quite slow. To
mitigate this, Bundler provides an option allowing to install gems using
parallel workers: `bundle install --jobs 4`. Just tell Bundler how many
concurrent jobs can be launched and let it work.
