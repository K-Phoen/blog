# My Blog ![](https://github.com/K-Phoen/blog/workflows/CI/badge.svg)

## Installation

- Fork this repository
- Clone it: `git clone https://github.com/K-Phoen/blog`
- Run `make serve`

You should have a server up and running locally at <http://localhost:1313>.

## Creating a new post

`./bin/hugo new posts/this-blog-has-continuous-integration.md`

## Deployment

Automated using a [Github Action](https://github.com/K-Phoen/blog/blob/master/.github/workflows/deploy.yml).
