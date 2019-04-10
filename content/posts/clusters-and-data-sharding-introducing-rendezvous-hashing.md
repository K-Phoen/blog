---
title: "Clusters and data sharding: introducing rendezvous hashing"
date: 2019-04-07
draft: true
---

In a [previous article](/2019/01/29/clusters-and-membership-discovering-the-swim-protocol/),
I started playing with distributed systems by implementing a distributed key-value
store.

At the end of this article I had a way to create a cluster, know its members
and monitor their health. But I still didn't touch the main feature of my store:
actually distributing data. We'll address that here.

<!--more-->

Before talking about a possible solution, let's lay out a few properties that we
want it to have:

* **load balancing**: each of the <code>n</code> nodes is equally likely to receive the key <code>K</code> ;
* **low overhead**: the overhead introduced by routing objects to the right node
  should be minimal, as to not decrease the overall performance of the system ;
* **minimal disruption**: whenever a node fails or is added to the cluster, the
  number of keys to relocate to another node should be as small as possible ;
* **distributed agreement**: for a given key, all the nodes should choose the
  same node as recipient.

## Hashtable-like approach

When I started thinking about how I could distribute data across the cluster,
my first thought was to take the principles used by "standard" hashtables and
see what would happen in a distributed environment.

The main idea behind hashtables is to turn a string (the key) into a number,
which will then be used to determine the location where the data will be stored.

The transformation of the key into a number is done by a hash function. These
functions have all kinds of interesting properties, which make them useful for
all sorts of uses. In this case, we are interested in one property in particular:
[uniformity](https://en.wikipedia.org/wiki/Hash_function#Uniformity).

Bucket selection inside a hashtable could look like this (where <code>N</code>
is the number of buckets):

```go
bucket := bucketsList[hash(key) % N]
```

Similarly, if we have <code>N</code> servers, we could use the same algorithm to
determine which one will be responsible of the given key:

```go
server := serversList[hash(key) % N]
```

It's simple, but it works!

## Evaluating the "hashtable-like" approach

Now that we have an algorithm, let's see how it fares in light of the goals we
defined earlier.

* **load balancing**: this property directly depends on the hashing function
  that is used and if it uniformly distributes keys or not. Depending on the
  nature of your data, [different types of functions](https://en.wikipedia.org/wiki/Hash_function#Hash_function_algorithms)
  can be used so we can safely assume that we can find a hash function that will
  do the job ;
* **low overhead**: computing a single hash is fast (as long as you don't use a
  cryptographic hash function — which can be slow on purpose) and does not
  require any network call, so the overhead is negligible ;
* **distributed agreement**: for this algorithm to work, all the servers in the
  cluster must use the same hash function. No further coordination is needed as
  all the work can be done locally ;
* **minimal disruption**: whenever a node fails or is added to the cluster,
  almost all every key already stored has to be moved. This is a serious issue.

To go further on the last point, when a node is added or removed to the cluster,
one of the main input of our algorithm changes. For a key to stay where it is,
the following has to be true:
`bucketList[hash(key) % N] == bucketList[hash(key) % (N + 1)]` (in case of a node
being added).

If the chosen hash function does a perfect job at distributing data, each node
would end up with <code>1/N</code> of the data.

If a new server is added/removed, we want to preserve this ratio. Furthermore,
keys that have to be moved should be taken from the "old" servers and **only move
from an old server to a new one**, never between old servers. Transferring data
between servers being expensive, the less data we transfer, the better.

And that's the main issue with this algorithm: a lot of data would have to be
moved around each time the cluster' state changes.

## Rendezvous hashing

After googling for a while, I stumbled upon a paper called « [A Named-Based
Mapping Scheme for Rendezvous](http://www.eecs.umich.edu/techreports/cse/96/CSE-TR-316-96.pdf) »
which introduced and described rendezvous hashing (also known as *Highest Random
Weight (HRW) Mapping*).

The algorithm itself is pretty straightforward:

1. a <code>weight</code> function is defined. It takes a key and a server address
    as input and returns the associated weight ;
2. for each server, the key-server weight is computed ;
3. the server with the highest weight is chosen to handle the request.

Here is what the server selection could look like, implemented in Go:

```go
// assuming that this exists: func hash(key string) int

func (n Node) weight(key string) int {
	return hash(fmt.Sprintf("%s:%s", n.Address(), key))
}

func ResponsibleNode(nodes []Node, key string) Node {
	var node Node
	maxWeight := 0

	for _, candidate := range nodes {
		weight := candidate.weight(key)

		if weight > maxWeight {
			maxWeight = weight
			node = candidate
		}
	}

	return node
}
```

## Evaluating rendezvous hashing

This algorithm is pretty similar to the "hashtable-style" one in the sense where
it relies on hash functions to map objects to servers.

The main difference lies on how you map a key to a server. Instead of hashing
the key and using a <code>mod</code> to select the server, the hash number is
considered as a weight. This makes the whole process almost immune to cluster
changes.

If we take a look at the properties we want for our system:

* **load balancing**: as long as we choose a correct hash function, this
  property still holds ;
* **low overhead**: we now have to compute <code>N</code> hashes instead of one,
  which makes the process <code>O(n)</code> instead of constant time. But we
  could also argue that it's "fast enough" (©) compared to network calls ;
* **distributed agreement**: once again, all nodes rely on the same algorithm
  and hash function and no external knowledge or communication is needed, which
  make distributed agreement easy, with local-only operations ;
* **minimal disruption**: because the way data is distributed across the cluster
  isn't tied to the cluster' size anymore, this algorithm exhibits nice
  properties. When a node is added, only <code>1/N</code> keys must be
  relocated. Similarly, if a node goes down (for maintenance, for instance), its
  keys can be moved to another node and when it comes back, the original mapping
  will be restored without needing additional coordination.

To sum up: we have a simple, coordination-free algorithm to map a key to a
server. And that with nice properties regarding load balancing and low disruption
in case of failures.

Quite impressive for an algorithm that simple, isn't it?

### Going further with rendezvous hashing

### playing with different hash functions

## Other algorithms

* consistent hashing
* jump hash
