import createMemoizingGetter from 'nanotools/lib/createMemoizingGetter';

function getActionDispatcherDescriptor(proto, key, actionCreator) {
  var actionDispatcher;
  actionDispatcher = function(...args) {
    return this.store.dispatch(actionCreator.apply(this, args));
  };
  return {
    configurable: true,
    get: createMemoizingGetter(proto, key, actionDispatcher, function() {
      return actionDispatcher.bind(this);
    })
  };
}

function defineActionDispatcher(proto, key, actionCreator) {
  return Object.defineProperty(proto, key, getActionDispatcherDescriptor(proto, key, actionCreator));
}

export default function action(opts) {
  var isDispatcher, withDispatcher;
  if (opts) {
    withDispatcher = opts.withDispatcher, isDispatcher = opts.isDispatcher;
  }
  return function(proto, key, descriptor) {
    var originalActionCreator, ref;
    originalActionCreator = descriptor.value;
    if (typeof originalActionCreator !== 'function') {
      throw new Error(`redux-components: @action decorator (applied to ${((ref = proto.constructor) != null ? ref.name : void 0)}.${key}) can only be applied to action creators.`);
    }
    if (isDispatcher) {
      return getActionDispatcherDescriptor(proto, key, originalActionCreator);
    } else {
      if (withDispatcher) {
        defineActionDispatcher(proto, withDispatcher, originalActionCreator);
      }
      return {
        configurable: true,
        get: createMemoizingGetter(proto, key, originalActionCreator, function() {
          return originalActionCreator.bind(this);
        })
      };
    }
  };
}
