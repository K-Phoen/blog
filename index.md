---
layout: default
title: Blog
---

<ul class="posts" itemscope itemtype="http://schema.org/Blog">
    {% for post in site.posts %}
        {% if post.next %}
            {% capture year %}{{ post.date | date: '%Y' }}{% endcapture %}
            {% capture nyear %}{{ post.next.date | date: '%Y' }}{% endcapture %}
        {% endif %}

        {% if forloop.first %}
        <li>
            <h2 class="year">{{ post.date | date: '%Y' }}</h2>
            <ul class="posts-by-year {{ post.date | date: '%Y' }}">
        {% else %}
        {% if year != nyear %}
            </ul>
        </li>
        <li>
            <h2 class="title">{{ post.date | date: '%Y' }}</h2>
            <ul class="posts-by-year {{ post.date | date: '%Y' }}">
        {% endif %}
        {% endif %}
        <li itemscope itemtype="http://schema.org/BlogPosting">
            <time datetime="{{ post.date | date_to_xmlschema }}">
                <meta itemprop="datePublished" content="{{ post.date | date_to_xmlschema }}" />
                {{ post.date | date: '%d %b' }}
            </time>
            <span class="separator"> &raquo; </span><a itemprop="name" href="{{ post.url }}" class="link">{{ post.title }}</a>
        </li>

        {% if forloop.last %}
            </ul>
        </li>
        {% endif %}
    {% endfor %}
</ul>
