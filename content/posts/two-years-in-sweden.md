---
title: Two years in Sweden
date: 2021-11-01

tldr: >
    * A lot happened during these two years and a half of silence. This post is **me, taking a step back** and trying to put words on my growth.

    * From a "mid-level" backend engineer, I was recognized as a "senior" engineer and **evolved into a Platform/Developer Experience role**.

    * It's only the beginning, there is a lot I need to learn still!

    * Still a backend engineer at heart, I now realize that **my interests and impact surface extends way further than writing code**. Through an awesome **developer experience**, well-thought architecture, and processes that make sense, I can **help people build better**.
---

A bit more than two years and a half ago I left my home country – France – to live and
work in Stockholm.

Judging by the lack of content on this blog during this period, one could
imagine that a lot has happened since.

<!--more-->

Everything started in 2018 when I decided to [leave my previous
job](/2018/05/14/looking-for-a-new-job/). I felt like I was stagnating but I
wasn't sure what my next move should be. So took my backpack out of the closet,
brought some good shoes and went off across half of Europe. Both to figure
things out and also to take some time for myself.

Fast-forward a year.

I'm landing in Stockholm with my trusted backpack, a laptop and the one-way
ticket that brought me here.

<img src="/img/two-years-sweden/stockholm.jpg" width="100%" alt="Beautiful Kungsholmen" />

The question I usually get at this point is "Why?". Well… because why not?

I guess I always had some attraction to the Nordics. I spent some time in Stockholm
during my year off and I enjoyed Stockholm more than other Scandinavian cities.
More importantly: as a European software engineer, I have the luxury of being able
to show up in pretty much any country in Europe and find a job, without the
hassle of having to deal with visas or a lengthy administrative process.

So here I am, all psyched up after a year of traveling and ready to make my
*grand début* at [Voi](https://www.voiscooters.com/).

While it wasn't my first job abroad, it was the first one that would require me
to speak English every day, all day long.

More than the difference in languages and cultures, the company itself and the
technologies it uses were completely different from what I was used to.

From roughly 20 employees at TEA – my previous employer – I jumped into a
scale-up counting more than 300 people.

From a "traditional" PHP/MySQL stack hosted on dedicated servers, I discovered
the joys of Golang on a GCP-managed Kubernetes cluster.

From the slow and well-established book industry, I joined the new and fast-paced
world of micro-mobility.

A challenge is what I was looking for, challenges are what I got. Two years worth
of them, and counting.

## First steps in Sweden

As expected, my first few weeks in Stockholm were intense. Anybody who has tried
to find a place to live here will tell you how "interesting" the housing market is.

More interesting yet was the fact that I now had to speak English pretty much
all day, every day. While my level wasn't terrible and I didn't have any real
issues being understood, I quickly realized that I struggled with technical
discussions.
The new environment in which I evolved, combined with a foreign language,
required me to take more time to process what was discussed and participate in
the exchange. By the time I was ready to add something to the discussion,
the rest of the team would often have moved on to a different topic.

In addition to being exhausting – having to translate in your head everything
you want to say from French to English will do that to you – it was frustrating.

Yet, there were positive side effects. It made me realize the value of standing
back and listening before opening my mouth, for instance. As well as helping me
improve my English. Unsurprisingly. Still can't say much about my accent though
[insert shrugs here].

Without noticing, speaking English became more and more natural. The frustration
faded away and the level of nuances I was able to express increased.

I can now speak English without any issue and am so used to it that my
inner-voice, my thoughts and dreams are mostly in English as well.

## Backend engineer with interests

I started as a "mid-level" backend engineer in one of the newest product
teams. Other than me, four other people were already part of the team when I
tagged along. A few months later we were a dozen: backend engineers,
mobile engineers, frontend engineers and a UX designer.

It was a truly cross-disciplines team, full of passionate engineers, and with a
real knack for problem-solving and building valuable tools for our users.

Which was precisely my objective when I joined it: get up-to-speed with the
technologies, learn the domain and start making my way towards meaningful
contributions.

To my surprise, I was able to wrap my head around these novelties in a couple of
months and I started being more active.

I spearheaded the use of [OpenAPI](https://www.openapis.org/) to document our HTTP APIs.

I built a prototype of CI/CD pipelines based on [GitHub Actions](https://github.com/features/actions),
which got enough tractions to be adopted — and is still in use today.

I drove the adoption of "[backends for frontends](https://docs.microsoft.com/en-us/azure/architecture/patterns/backends-for-frontends)"
as a way to alleviate the problems generated by having different clients (ex:
public mobile applications vs internal administration tools) and the need to
expose different views of our data to them.

I took on a Scrum Master hat, to better help my team organize itself and keep a
steady delivery flow without falling into unsustainable ways of working.

And most likely other things that I forgot about. It was more than two years ago
after all!

While I expected to spend a fair amount of time learning Golang and Kubernetes,
I got the hang of it pretty quickly and turned myself towards broader, more
important problems.

How can I support Vois's needs for rapid growth and evolution?

What does that mean for engineering practices?

Can we increase the safety and reliability of our services without compromising
on developer efficiency?

All of these questions lead me — after nine months — to my second role at Voi:
Platform engineer.

## Birth of the Platform team

In January 2020, I had the opportunity to become one of the three founding
members of our Platform team.

In short, our mission is to reduce friction for developers by providing reliable
infrastructure, processes, and self-service tools. A sort of foundation that
fellow engineers can rely upon to build our products, from our Cloud
infrastructure and its management to the processes and tools to deploy and
observe services on it.

The state of things in the early days was not exactly glamorous. Largely due to
the fact that no one was responsible for our infrastructure and its reliability,
but also because our engineering community was relatively small and the company
needed to move fast — sounds familiar?

Among our top concerns were:

* the "less than optimal" degree of observability on our services
* the fact that none of our infrastructure was managed "as code"
* the lack of focus on infrastructure security

We tackled these topics as a team but I would like to think that some of my own
initiatives helped so I'll mention a few.

Coming straight out of a "product team", I experienced first-hand what a lack of
basic monitoring could mean. At Voi, all of our micro-services use [`svc`](https://github.com/voi-oss/svc)
as their most basic building block. We combine this "worker life-cycle manager"
with internal HTTP and gRPC workers that – among other things – expose a
unified set of metrics and build our services on top of this common foundation.
I realized that instead of expecting engineers to create sensible default
monitoring dashboards for their services – a tedious and copy/paste intensive
task – we could generate them and push them to Grafana automatically.

[`grabana`](https://github.com/K-Phoen/grabana) was born, we had a way to describe
**Grafana dashboards as code**.

I integrated `grabana` into our engineering CLI tool and it gave us a way to
create a default dashboard for a service by running a command. Sprinkle a bit of
CI/CD pipelines on top and these dashboards were created for every single
service in our systems, thus drastically increasing monitoring and alerting
coverage.

While this approach works great for default dashboards and alerts, it doesn't
allow engineers to easily follow this same *as-code* approach for more
business-specific monitoring.

For this need, engineers need fine-grained control over what the dashboard
covers, how it displays information and what should be alerted on. Ideally,
these dashboards should follow the life-cycle of the application their monitor:
being reviewed as code, deployed, and rolled back when the application is.

[`DARK`](https://github.com/K-Phoen/dark) was born, standing for **D**ashboards
**A**s **R**esources in **K**ubernetes.

A nice benefit of both these tools is that they also enable us to have the same
monitoring dashboards in all our environments (which are completely isolated
from one another).

Working on these tools proved highly beneficial — at the time as well as now,
in hindsight — but is also highlighted another issue: listing all the services
in our platform without forgetting one was hard!

Knowing which team owned them, what capabilities/APIs they exposed, what they
did, …, even more so.

Since we expected our engineering community to grow, making sure that these
questions could be easily answered felt important for new-joiners during their
onboarding as well as old-timers in their daily work.

This is where the idea of having an engineering portal came from. A place that
could be used as a homepage or a gateway towards information needed by engineers.

Luckily – a month or two after I built a proof-of-concept – Spotify announced
[Backstage](https://backstage.io/).

Backstage was in early pre-alpha at the time, but adopting it proved a good
choice. I've closely followed the work being done by their amazing contributors
and it allowed us to benefit from a lot of features coming from Backstage itself
— the software catalog being the main pillar — as well as some custom plugins I
wrote. Some are internal: virtual scooters, enabling us to develop and test
end-to-end flows without requiring physical vehicles. Some are Open-Source, such
as the [Opsgenie plugin](https://github.com/K-Phoen/backstage-plugin-opsgenie/)
and the [Grafana plugin](https://github.com/K-Phoen/backstage-plugin-grafana/).

Its [scaffolding plugin](https://backstage.io/blog/2021/07/26/software-templates-are-now-in-beta)
also allowed us to scrap our custom "service bootstrap" GitHub repository – used
to bootstrap new micro-services – to benefit from a fully automated solution.
Our scaffolding will create a new GitHub repository for the service, generate a
Golang skeleton customized for the use-case at hand, as well as the necessary
Kubernetes manifests and Terraform code necessary to deploy it. From an entire
week required to deploy a new service in production when I joined, it is now
doable in 10 minutes only!

A lot more is available in our engineering portal (documentation, feature
toggles integration, service quality scores, …) and even more features and
information will come, but it already is an important tool.

Besides my work on providing our community with tools, I also introduced the
first versions of various ways of working related to incident management and
reliability. All of which are still used to this day, with minor changes mainly
due to our rapid growth.

For example, I drafted our incident management process. Spent time reading the
industry-standard practices and interviewed various people across the
organization to come up with something that would serve everyone.

To drive adoption, a lot of training with the teams was required as well as
regular incident management drills. We took it one step further and also
introduced SLIs/SLOs as a way to fully enable the teams to own and drive
reliability efforts over their services.

These initiatives are far from being the only ones that I drove or worked on,
but mentioning them helped me realize two things:

1. I still ramble on way too much when I start talking about topics that deeply
   interest me
2. Most of the topics that interest me the most aren't related to the
   core mission of the team I work in

Despite still being interested in backend development and
platform/infrastructure engineering, I now realize that I enjoy way more working
on improving Developer Experience.

Enabling teams to focus on delivering scalable applications with high speed,
quality and performance, without compromising on engineering happiness sounds
like an amazing challenge. With deep ramifications in various areas: tooling and
automation, observability, education and practices, communication and user
research, company strategy, …

Let's take another step back in a year and see how much better our developer
experience has gotten :)
