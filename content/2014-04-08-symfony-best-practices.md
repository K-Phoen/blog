---
layout:      post
title:       Symfony best practices
description: Digest of my best practices for Symfony projects. They are given as is, in no particular order and are far from being exhaustive.
---

Here is a digest of the best practices that are commonly followed for Symfony2
projects.
They are given as is, in no particular order and are far from being exhaustive.

## Naming things

* find a common naming scheme for your team and stick to it
  * be explicit
  * be consistent
* same for routes and services naming
  * use service alias: `mailer` is better than `swiftmailer.mailer.default`
* prefer `Vendor/Bundle/CoolBundle` over `Vendor/CoolBundle` for bundles namespace
  * for an application, you can even skip the vendor part

## Config

Which configuration format should you use?

* bundles config: YAML
* routes: YAML
* entities: YAML/XML
* validation, serializer: YAML
* services: YAML (XML for some use cases)

Create a `routing.yml` file per bundle and import it in `app/config/routing.yml`.
Nest your routing files using prefixes.

Split vendor bundles configurations and import them in `app/config/config.yml`.<br />
[Split validation configuration files](http://blog.kevingomez.fr/2013/10/14/split-symfony2-yaml-validation-configuration-file/).

## Bundles

* should be self-contained
* should provide a feature, not an app (examples: Forum, Admin, ...)
* should follow bundles [structure standards](http://symfony.com/doc/current/cookbook/bundles/best_practices.html)

## Controllers

* should be lightweight
  * do not put logic in them, write handlers/services instead
* avoid extending FrameworkBundle/Controller (expecially if your controller is meant to be distributed)
  * see http://richardmiller.co.uk/2011/06/14/symfony2-moving-away-from-the-base-controller/
  * define them as services
* inject the request into controller actions parameters
* do not hesitate to dispatch events for "add-on actions"
* use Form handlers/persistence handlers

## DependencyInjection

* do not inject the Container (except for some scope-related use cases)
  * see [RequestStack](http://symfony.com/doc/current/book/service_container.html#book-container-request-stack)
  * see [synchronized services](http://symfony.com/doc/current/cookbook/service_container/scopes.html)
* split services definition into several files
  * bonus: easy dynamic loading of services (per env for instance)
* use a semantic configuration
* inject configuration parameters in your services
* environment variables (defined in apache/nginx) can be used!
* know how [tagged services](http://symfony.com/doc/current/components/dependency_injection/tags.html) and [compiler passes ](http://symfony.com/doc/current/cookbook/service_container/compiler_passes.html) work

## Dependencies management

* (learn how-to) use composer
* group you dependencies by "theme" in your composer.json
* do not commit your `vendor` directory or composer.phar, only commit composer.json and
  composer.lock
* use `composer.phar install --no-dev --optimize-autoloader --prefer-dist` in prod
* do not require `dev-master` unless you absolutely have to
* use bounded versions constraints
  * BAD : `>=1.2.0`
  * GOOD: `>=1.2.0,<2.0.0`
  * BETTER: `~1.2`
* know about composer [stability flags](https://igor.io/2013/02/07/composer-stability-flags.html)
* [avoid optional dependencies](http://richardmiller.co.uk/2014/03/17/avoiding-optional-dependencies/)

## Forms

* use Type classes
* always set a default `data_class`
* define types as services
* do not disable CSRF (except for API)
* set the `intention` option

## Doctrine

* activate caches: metadata cache, query cache, result cache
  * and don't forget to clear these caches when you deploy
* register repositories as services and inject them
* do not write queries outside repositories
* only flush from the controller

## Tools

* [PHP-CS-Fixer](https://github.com/fabpot/PHP-CS-Fixer)
* use [static analysis tools](https://chrsm.org/post/static-analysis-tools-for-php/)
* XHProf + XHProf.io
* xdebug + kcachegrind
* [sismo](http://sismo.sensiolabs.org/)
* [Travis-CI](https://travis-ci.org/)
* [Scrutinizer](https://scrutinizer-ci.com/)
* [Vagrant](http://www.vagrantup.com/)
* [capifony](http://capifony.org/)

## Useful bundles

* [FOS](https://github.com/FriendsOfSymfony/)
  * [FOSUserBundle](https://github.com/FriendsOfSymfony/FOSUserBundle/)
  * [FOSRestBundle](https://github.com/FriendsOfSymfony/FOSRestBundle/)
  * [FOSJsRoutingBundle](https://github.com/FriendsOfSymfony/FOSJsRoutingBundle)
* [StofDoctrineExtensionsBundle](https://github.com/stof/StofDoctrineExtensionsBundle)
* e-commerce
  * [Vespolina](http://vespolina.org/)
  * [Sylius](http://sylius.org/)
  * [Sonata e-commerce](http://sonata-project.org/bundles/ecommerce/develop/doc/index.html)
* [Sonata](http://sonata-project.org/)
  * Admin, User
  * SEO, media, news, ...
  * i18n, cache, ...
  * http://sonata-project.org/bundles/
* [GenemuFormBundle](https://github.com/genemu/GenemuFormBundle)
* [WebProfilerExtraBundle](https://github.com/Elao/WebProfilerExtraBundle)
* [LexikMaintenanceBundle](https://github.com/lexik/LexikMaintenanceBundle)
* [BazingaFakerBundle](https://github.com/willdurand/BazingaFakerBundle)
* [BazingaJsTranslationBundle](https://github.com/willdurand/BazingaJsTranslationBundle)
* [LiipFunctionalTestBundle](https://github.com/liip/LiipFunctionalTestBundle)
* [VichUploaderBundle](https://github.com/dustin10/VichUploaderBundle)

## Miscellaneous

* add a .gitignore: only commit your own code
* [PHP The right way](http://www.phptherightway.com/)
* [PSR-0](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-0.md), [PSR-1](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-1-basic-coding-standard.md), [PSR-2](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-2-coding-style-guide.md) and be aware of [PSR-3](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-3-logger-interface.md)
* use APC
* use xdebug (in dev env)
* [store sessions in the database](http://symfony.com/doc/current/cookbook/configuration/pdo_session_storage.html) or in [memcached](http://blog.kevingomez.fr/2012/12/18/storing-symfony2-sessions-in-memcached/)
* translations
  * work with translation keys instead of sentences
  * check for missing translations with tools (like https://github.com/maisonsdumonde/MDMTranslatorCheckerBundle)
* be pragmatic!
