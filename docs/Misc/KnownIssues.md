# Known Issues

redux-components is young and as such, there are still a few conceptual hurdles to overcome. I welcome discussions of these issues and their possible resolutions on the [GitHub issue tracker](https://github.com/wcjohnson/redux-components/issues)

### Action Noise in Composed Components

[GitHub issue here.](https://github.com/wcjohnson/redux-components/issues/2)

redux-components enables and encourages designs where components are built up from simpler ones as sub-branches using ```SubtreeMixin```. In practice we've found that this can leave one with subtrees that may be a few levels deep, whose leaves are just a bunch of ```ObjectStore```s.

This kind of design can lead to a single action creator on a high branch firing multiple action creators on a subbranch, and so on down the tree until you get a quite large sequence of primitive actions reducing over all the ```ObjectStore``` leaves simultaneously, thus tripping a lot of Redux store updates.

We have been doing several things internally to mitigate this phenomenon:

> **NB:** Don't prematurely optimize! Make sure this is actually a problem for you before using these remedies. For many use cases, there won't be a noticeable impact.

* Batching actions with [redux-batched-actions](https://www.npmjs.com/package/redux-batched-actions)
* Batching updates to connected React components with [redux-batched-subscribe](https://github.com/tappleby/redux-batched-subscribe)
* The old country doctor's remedy: "It hurts when I do this. -- So stop doing that!" For components where state gets very deep, or where it is valuable to have composite rather than primitive actions in Redux's history (e.g. undo/redo use cases), we are avoiding deeply nested composition of redux-components.

I don't particularly like that we have to resort to the country doctor remedy, so I'm looking for feedback on a better solution. Early days but my own instincts tell me we need something like redux-batched-actions that can be mixed in at the top of deep subtrees that will (somehow) automatically compose any synchronously generated block of actions into a batched one...
