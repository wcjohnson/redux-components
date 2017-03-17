import createMemoizingGetter from 'nanotools/lib/createMemoizingGetter'
import makeSelectorObservable from '../makeSelectorObservable'

function augmentSelector(selector, instance, makeScoped, makeObservable) {
  var boundSelector;
  if (makeScoped) {
    boundSelector = function(state, ...args) {
      return selector.call(this, instance.state, ...args);
    };
  } else {
    boundSelector = function(...args) {
      return selector.apply(this, args);
    };
  }
  if (makeObservable) {
    return makeSelectorObservable(instance, boundSelector);
  } else {
    return boundSelector;
  }
}

export default function selector(opts) {
  var isObservable, isScoped;
  opts = Object.assign({
    isObservable: false,
    isScoped: true
  }, opts);
  isObservable = opts.isObservable, isScoped = opts.isScoped;
  return function(proto, key, descriptor) {
    var originalSelector, ref;
    originalSelector = descriptor.value;
    if (typeof originalSelector !== 'function') {
      throw new Error(`redux-components: @selector decorator (applied to ${((ref = proto.constructor) != null ? ref.name : void 0)}.${key}) can only be applied to selectors.`);
    }
    return {
      configurable: true,
      get: createMemoizingGetter(proto, key, originalSelector, function() {
        return augmentSelector(originalSelector, this, isScoped, isObservable);
      })
    };
  };
}
