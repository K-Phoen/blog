---
title: "Clusters and data sharding: introducing rendezvous hashing"
date: 2019-04-11
---

In a [previous article](/2019/01/29/clusters-and-membership-discovering-the-swim-protocol/),
I started playing with distributed systems by implementing a distributed key-value
store.

I used SWIM to create a cluster, know its members and monitor their health. But
I still didn't touch the main feature of my store: actually distributing data.
Now is the time to address that.

<!--more-->

Before talking about a possible solution, let's lay out a few properties that we
want it to have:

* **load balancing**: each of the <code>n</code> nodes is equally likely to receive the key <code>K</code> ;
* **low overhead**: the overhead introduced by routing objects to the right node
  should be minimal, as to not decrease the overall performance of the system ;
* **minimal disruption**: whenever a node fails or is added to the cluster, the
  number of keys to relocate to another node should be as small as possible ;
* **distributed agreement**: for a given key, all the nodes should choose the
  same node as the recipient.

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
determine which one will be responsible for the given key:

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

**Note**: another issue that could be raised is the need for each node to
maintain a list of all other nodes in the cluster. It's not an issue for me as I
rely on SWIM to maintain and monitor my cluster. Through this protocol, each
node has an up-to-date (eventually) list of the members of the cluster.

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
	// usually, you would find a way to merge the two hashed instead
	// of concatenating the server's adress, the key and hashing the
	// result. The original paper suggests:
	// a = 1103515245
	// b = 12345
	// (a * ((a * server_address + b) ^ hash(key)) + b) % 2^31

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

**Note**: [*MurmurHash*](https://en.wikipedia.org/wiki/MurmurHash) is a
non-cryptographic, general-purpose hash function that is often used for
rendezvous hashing. There is also a [pretty cool answer on StackOverflow](https://softwareengineering.stackexchange.com/questions/49550/which-hashing-algorithm-is-best-for-uniqueness-and-speed/145633#145633)
where someone did an interesting comparison of several hashing algorithms.

## Evaluating rendezvous hashing

This algorithm is pretty similar to the "hashtable-style" one in the sense where
it relies on hash functions to map objects to servers.

The main difference lies in how you map a key to a server. Instead of hashing
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

#### Performance

For a big enough cluster, the <code>O(n)</code> lookup time necessary to compute
a key to server mapping can be too much.

To mitigate that, a number of optimizations exist.

The simplest way would be to find a trick to speed up the loop iterating over
the nodes. Possibly by pre-computing hashes for each server and using some
bit shifting-based black magic to merge the key's hash and the server's one.

But the algorithm's complexity wouldn't change.

That being said, there is a variant of the rendezvous algorithm — [the
skeleton-based one](https://en.wikipedia.org/wiki/Rendezvous_hashing#Skeleton-based_variant_for_very_large_n) —
that relies on a virtual hierarchical structure to achieve an <code>O(log n)</code> complexity.
The idea is to consider the cluster as a tree, with the nodes as leaves and
introducing virtual nodes to structure the tree in a hierarchical way.
This tree can then be used to compute hashes just for a subset of the servers in
the cluster instead of all of them.

#### Replication

For some services like databases or cache servers, replication is a must-have
feature. Luckily, it's straightforward to implement with rendezvous hashing.

The algorithm already sorts nodes by weight, from the most susceptible to
receive the object to the least. When we don't want the data to be replicated,
we select only the first node. If we want the data to live in two nodes, we can
select the first two nodes of the list. And so on.
If the "main" node goes down, the algorithm will automatically be able to fetch
the data from the replica, with no need for additional coordination across
nodes.

## Other algorithms

Of course, rendezvous hashing isn't the only technique to distribute keys across
servers.

I won't detail them here, I just leave a few of them here, for the curious
readers:

* [consistent hashing](https://en.wikipedia.org/wiki/Consistent_hashing): don't
  forget to read the "External links" section ;
* [jump hash](https://arxiv.org/abs/1406.2294): this one looks like dark magic.
  It's a hash function that consistently chooses a number between [0, numServers),
  using the given key (it's basically a srand(), using the key as seed) ;
* and I'm sure that there are a lot of other methods that I don't know about…
  feel free to tell me about them!
