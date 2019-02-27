---
layout:      post
title:       Split Symfony2 YAML validation configuration file
description: Symfony snippet showing how to use several validation files.
---

**Important** : as j0k pointed out in the comments, Symfony 2.5 changed the way validation files are loaded. Refer to [this StackOverflow answer](http://stackoverflow.com/questions/24064813/how-to-split-validation-yaml-files-in-symfony-2-5/24210501#24210501) if you are using Symfony >= 2.5.


Defining validation rules for several entities in the same file can really be a pain. Unfortunately, Symfony2 only looks in the *validation.yml* file by default.
Let's see how we can split the following file:

<script type="text/javascript" src="https://gist.github.com/6974497.js?file=validation.yml"></script>

The solution lies in the <code>AcmeBlogExtension</code> class, and more specifically in the <code>validator.mapping.loader.yaml_files_loader.mapping_files</code> parameter. As this parameter defines the list of files used to map configuration rules to their entities, we just have to add our owns to the list.

<script type="text/javascript" src="https://gist.github.com/6974497.js?file=AcmeBlogExtension.php"></script>

In the extension, I assume that the validation files are stored in the *Resources/config/validation* directory. For the record, here are the files:

<script type="text/javascript" src="https://gist.github.com/6974497.js?file=Post.yml"></script>

<script type="text/javascript" src="https://gist.github.com/6974497.js?file=Comment.yml"></script>

If you don't want to list yourself the files, you can use the <code>Finder</code> class to inspect the directory for you.
