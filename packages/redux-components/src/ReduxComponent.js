import invariant from 'nanotools/lib/invariant'
import get from 'nanotools/lib/get'
import iteratePrototypeChain from 'nanotools/lib/iteratePrototypeChain'
import createSubject from 'observable-utils/lib/createSubject'
import getObservableFrom from 'observable-utils/lib/getObservableFrom'

export default class ReduxComponent {
  constructor() {
    if (process.env.NODE_ENV !== 'production') {
      invariant(typeof this.reducer === 'function', `redux-component of type ${this.displayName} has no reducer.`);
    }
    this.reducer = this.reducer.bind(this);
    this._subject = createSubject();
  }

  reducer(state, action) {
    if (state === void 0) {
      return null;
    } else {
      return state;
    }
  }

  __getSubject() {
    return this._subject;
  }

  isMounted() {
    return !!this.__mounted;
  }

  __willMount(store, path = [], parentComponent = null) {
    var i, len, stringPath, verb, verbs;
    if (process.env.NODE_ENV !== 'production') {
      invariant(
        (store != null) && (store.dispatch) && (store.subscribe) && (store.getState) && (store.replaceReducer),
        `redux-component of type ${this.displayName} was mounted without a proper Store object. Redux components may only be mounted to valid redux stores.`
      )
      invariant(
        !this.__mounted,
        `redux-component of type ${this.displayName} was multiply mounted. This can indicate a cycle in your component graph, which is illegal. Make sure each instance is only used once in your tree. If you wish to use a component in multiple places, construct additional instances. This mounting was at [${path}]. The previous mounting was at [${this.path}].`
      )
    }

    // Demographics
    this.store = store;
    this.parentComponent = parentComponent;
    this.path = path;
    // Scope verbs
    if ( (verbs = this.__getMagicallyBoundKeys('verbs')) ) {
      stringPath = this.path.join('.');
      for (i = 0, len = verbs.length; i < len; i++) {
        verb = verbs[i];
        this[verb] = `${stringPath}:${verb}`;
      }
    }
    // Connect observers to store
    this._subject.subscription = getObservableFrom(this.store).subscribe(this._subject);
    // Lifecycle
    if (typeof this.componentWillMount === "function") {
      this.componentWillMount();
    }
  }

  __didMount() {
    this.__mounted = true;
    if (typeof this.componentDidMount === "function") {
      this.componentDidMount();
    }
  }

  __willUnmount() {
    var ref;
    if (process.env.NODE_ENV !== 'production') {
      invariant(this.__mounted, `redux-component of type ${this.displayName} was unmounted when not mounted. This can indicate an issue in a dynamic reducer component such as redux-components-map.`);
    }
    if (typeof this.componentWillUnmount === "function") {
      this.componentWillUnmount();
    }
    if ((ref = this._subject.subscription) != null) {
      ref.unsubscribe();
    }
    delete this._subject.subscription;
    delete this.store;
    delete this.path;
    delete this.parentComponent;
    delete this.__mounted;
  }

  __getMagicallyBoundKeys(type) {
    var result;
    result = [];
    iteratePrototypeChain(this, function(proto) {
      var ref;
      return result = result.concat(((ref = proto.constructor) != null ? ref[type] : void 0) || []);
    });
    return result;
  }

  get state() {
    if (this.store != null) {
      return get(this.store.getState(), this.path);
    } else {
      return undefined;
    }
  }

  get displayName() {
    var ref, ref1;
    return ((ref = Object.getPrototypeOf(this)) != null ? (ref1 = ref.constructor) != null ? ref1.name : void 0 : void 0) || '(unknown)';
  }

}
