---
layout: post
title: On Taming Repository Classes in Doctrine… Among other things.
---

A while ago I stumbled upon a - rather old but nonetheless interesting - [post](http://www.whitewashing.de/2013/03/04/doctrine_repositories.html) written by [@beberlei](https://twitter.com/beberlei). In his post, he highlighted the issues of having **too much responsibilities in a repository** and suggested a solution based on the **[Specification pattern](http://en.wikipedia.org/wiki/Specification_pattern)**.

The idea behind this pattern is to isolate simple business rules into small specification objects and compose them later in order to express more complex rules.
For those who need a reminder, it looks like this:
<script src="https://gist.github.com/K-Phoen/04830079aa020b3577b7.js?file=specifications.php"></script>

The combinatorial explosion of methods in the repository is avoided and repositories become unit-testable again.

Have we won? Not quite.

Imagine for instance that we happen to have a use case where we have **multiple repositories** for the same entities (one in memory and another using Doctrine ORM) and we want our specifications to work with all of them.
At this point you notice that the previous specifications are **tied to Doctrine** ORM <code>QueryBuilder</code> objects and that they can not work with anything else. Your carefully crafted specifications can't be used if you want - and you do - filter a simple array of objects stored in memory.

Luckily, since Doctrine 2.4 we can use Doctrine <code>Criteria</code> objects to build [expressions that can be used to filter](http://docs.doctrine-project.org/en/latest/reference/working-with-associations.html#filtering-collections) both <code>QueryBuilders</code> and [Collections](https://github.com/doctrine/collections/). Moreover, as of version 2.5 (still in alpha at this time) <code>ManyToMany</code> relations are supported.

Despite being a little too verbose to me, this solution works. We can refactor our previous specifications to return a <code>Criteria</code> instead of modifying a <code>QueryBuilder</code> and later apply these criterion to a <code>QueryBuilder</code> or a <code>Collection</code>.
<script src="https://gist.github.com/K-Phoen/04830079aa020b3577b7.js?file=criteria.php"></script>

The general concept is the same as before but now we use Doctrine <code>Criteria</code> objects as an **intermediate representation for our specifications**. As both the <code>EntityRepository</code> and the <code>ArrayCollection</code> implement the <code>Selectable</code> interface, we can use the <code>matching()</code> method to apply our specification.
Theoretically, our problem should be solved by this solution.

Have we won? Not quite.

Besides the verbosity of these expressions, we would quickly come across another issue: it's not possible to use **custom operators** or custom functions.

At this point I started to feel a bit desperate so I wrote my own solution, still based on the Specification pattern but not relying on Doctrine collections at all. I wanted a **simple syntax** to express my business rules and of course, I wanted to be able to apply them on **any kind of target**.
With that in mind, I created [RulerZ](https://github.com/K-Phoen/rulerz) (still trying to find a good name for this project...). Based on [hoa/ruler](https://github.com/hoaproject/Ruler), RulerZ is a library which tries to solve this exact problem.

<script src="https://gist.github.com/K-Phoen/04830079aa020b3577b7.js?file=rulerz.php"></script>

As shown by the previous examples, expressing rules is very easy as instead of creating a lot of objects we just use a simple DSL that is very close to SQL. Applying these rule is as easy as before and so is writing Specification classes.
Oh, and I almost forgot: this example also uses a custom operator ("length").

For those who aren't convinced, here is how the specification pattern can be implemented with RulerZ and for all the targets you can imagine:

<script src="https://gist.github.com/K-Phoen/04830079aa020b3577b7.js?file=rulerz_specification.php"></script>

To summarize, Specifications written with RulerZ are **more meaningful** and yet they can be used on several types of targets.
While this project is still a work-in-progress, it's already tested, documented and [integrated in Symfony](https://github.com/K-Phoen/RulerZBundle).
Do not hesitate to browse [RulerZ' documentation](https://github.com/K-Phoen/rulerz/blob/master/doc/index.md) to discover what other features it has to offer.

Have we won? Hell yeah. Or at least, I hope so.
