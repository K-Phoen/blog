---
layout: post
title: Best practices for exploitable logs
description: >
    « **What to log?** » — That's the question I often ask myself when I launch new
    projects or work on existing applications.

    And by « what », I mean which events should be logged? Using which format? Where
    should they be sent?

    To answer these questions, we need to ask ourselves why do we need logs in the
    first place?
tldr: >
    * choose a logging strategy: are you more interested by performance, user actions or business metrics?

    * make sure that all relevant events are logged, not only the errors!

    * add some context to your events. Customer identifier? Order reference? Anything that might prove useful is appreciated.

    * include dates in a standard format to give make the events chronology explicit.

    * ensure that your logs follow a precise, textual format. It should be easily understandable by both humans and machines.

    * categorize and correlate logs using log levels, subsystems identifiers and request identifiers.
---

« **What to log?** » — That's the question I often ask myself when I launch new
projects or work on existing applications.

And by « what », I mean which events should be logged? Using which format? Where
should they be sent?

To answer these questions, we need to ask ourselves why do we need logs in the
first place?

## Determine your logging strategy

Logging everything would be counter-productive as we would end up with too much
data to search and the important information would probably be hidden in
non-essential logs.

Therefore, the first step is to determine what your logs will be used for.

Common logging strategies include:

* **performance and resources**: memory consumption, CPU/IO/network usage,
  external API calls and their response times, …
  Helps to monitor, debug and improve the general performance of the system.
* **errors**: exceptions, warnings, unexpected responses, …
  Helps detecting and troubleshooting issues with the system or its environment.
* **user actions**: actions performed by your users.
  Useful to help users when they come across an issue.
* **business metrics**: business-related events.
  Can be used as a _poor man's BI tool_.

That's why the logging strategy employed in these applications is
_"user actions"-oriented_.

## Log, log, log

Now that your logging strategy is identified, **be sure that all the relevant
events are logged**.

Most of the time, I need logs to help me debug a running system. Be it an API
that returns unexpected or incorrect responses or an e-commerce platform failing
randomly during the checkout process.

In this case, **error logs are not enough** to know what your users were doing
before the system failed. That's why I add logs for every significant action
performed by the user. I see these logs as "checkpoints" like we would find in
video games: they allow me to see what the user was doing before it all went
wrong.

## Logs and context

For your logs to be useful, they have to vehiculate enough data.

Let's say that our system produces a log each time a user signs in. Would you
rather produce something like this?

```
User logged in.
```

Or like this?

```
[2016-02-03T10:04:51.965Z] User "K-Phoen" logged in after 2 attemps.
```

That's right, the last one is more useful and gives you a better understanding
of what happened.

As a rule of thumb, I try to include as much context as possible in my logs. If
a user is logged in, I join its identifier. If an order was being processed, I
give its reference. **If an error occurs**, I include all the previous details
to which I **join the error message and its backtrace**.

You don't know what kind of nasty bugs your users will encounter so do yourself
a favor: **be proactive and include as much context as you can**.

Including a date at the beginning of each log entry is also a must-have.

**Bonus point** for using a standard format for the date (ISO 8601 is fine) and
including the timezone.

Be sure that you **do not log anything secret**, be it in the log message itself
or in the context. I particularly think of passwords, API secrets, …

## Logs should be machine readable and human understandable

My previous example was far from being perfect.

Even if the log message was quite descriptive and provided some context, the log
itself would have been "hard" to process by a program.
For instance, extracting the context would have required the use of regular
expressions… which is not exactly great for performance.

**Logs should be written in plain text** so that both humans and machines can
read and process them.

If you have to log additional, structured data in addition to the event
description, use a format like JSON:

```
[2016-02-03T10:04:51.965Z] User {login} logged in after {attemps_count} attempts -- {"login": "K-Phoen", "email": "contact@kevingomez.fr", "attempts_count": 2, "authentication_mode": "http_basic"}
```

The log entry is as readable as before but includes more context and remains
easily indexable by a machine.

**Bonus point** for using placeholders in your log descriptions can ease logs
aggregation done by tools such as Sentry or Airbrake.

Be sure to **avoid multi-line logs** as they make the logs processing more
complex. Consider breaking multi-line events into separate events.

## Categorize and correlate events

Speaking about events processing: categorizing events is a great way to help
logs exploration.

The first thing to do is to use **the appropriate level** when logging an event.
Which level to use is ultimately the developer's decision but the available
levels and their meaning is defined in [the RFC 5424](https://tools.ietf.org/html/rfc5424#page-11)
(the one describing the Syslog protocol).

The minimum log level to choose in production depends on the application's
stability. I would switch to DEBUG level for new or unstable applications
whereas for stable ones I would prefer INFO.

In addition to log levels, I like to **identify the subsystems emitting the
events** by including its name in the log entry:

```
[2016-02-03T10:04:51.965Z] [security] [INFO] User {login} logged in after {attemps_count} attempts -- {"login": "K-Phoen", "email": "contact@kevingomez.fr", "attempts_count": 2, "authentication_mode": "http_basic"}
```

Using the appropriate log level in addition to a subsystem identifier allows us
to quickly obtain information on a specific event that happened in the
application.

But so far, we do not have anything to link these event together or, for
instance, to retrieve all the events associated to the same request.
To achieve that, a _request identifier_ should be generated as early as possible
in the request lifecyle and included in all the log events.

This identifier can even be generated by Nginx if you want to correlate your
access logs and your application logs.

```
[2016-02-03T10:04:51.965Z] [routing] [INFO] Request matched route {route} -- {"route": "login", "method": "GET", "controller": "…"} {"request_id": "7d5e8092-a13d-45b8-adb4-b26c18806825"}
[2016-02-03T10:04:51.965Z] [security] [INFO] User {login} logged in after {attemps_count} attempts -- {"login": "K-Phoen", "email": "contact@kevingomez.fr", "attempts_count": 2, "authentication_mode": "http_basic"} {"request_id": "7d5e8092-a13d-45b8-adb4-b26c18806825"}
```

I often include two sets of metadata in my log entries:
* the first represents a _log context_ and is associated to the event itself ;
* the other represents _extra metadata_ automatically added to any event
  emitted by the application.

These two set of information are kept separated to avoid collisions.

## Infrastructure considerations

In this blog post, I just wanted to lay out a few practices that I consider
useful in regards to our logging strategies.
How logs are used and with which tools is not a subject that I tried to cover
here. That's why you did not find any mention to projects such as Kibana,
Splunk, Graylog, …

That being said, I wanted to introduce two practices that are more related to
infrastructure considerations than applicative ones.

The first concerns logs storage on the applicative server: **ensure that your log
files are rotated, compressed and eventually removed**.

If you do not log to a file but to some kind of log server like [Syslog](https://syslog-ng.org/)
or a forwarder like [Beats](https://www.elastic.co/products/beats), be sure that
these agents are running locally, directly on the application server. You do
not want to loose your logs in case of a network failure!
