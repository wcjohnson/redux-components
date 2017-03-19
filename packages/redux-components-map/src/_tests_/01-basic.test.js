var ComponentMap, createClass, createComponent, expect, makeAStore, mountRootComponent, ref, ref1, testComponentMixin;

expect = require('chai').expect;

ref = require('redux-components-legacy'), createClass = ref.createClass, mountRootComponent = ref.mountRootComponent, createComponent = ref.createComponent;

ref1 = require('./helpers/store'), makeAStore = ref1.makeAStore, testComponentMixin = ref1.testComponentMixin;

ComponentMap = require('..').default;

describe('basic functions: ', function() {
  var MapClass, SubcomponentOne, SubcomponentTwo, rootComponentInstance, store;
  store = makeAStore();
  SubcomponentOne = null;
  SubcomponentTwo = null;
  MapClass = null;
  rootComponentInstance = null;
  return describe('trivial map: ', function() {
    it('should create fresh store', function() {
      return store = makeAStore();
    });
    it('should create component class', function() {
      SubcomponentOne = createClass({
        displayName: 'SubcomponentOne',
        mixins: [testComponentMixin]
      });
      return SubcomponentTwo = createClass({
        displayName: 'SubcomponentTwo',
        mixins: [testComponentMixin]
      });
    });
    it('should create ComponentMap with typemap', function() {
      var typeMap;
      typeMap = {
        SubcomponentOne: SubcomponentOne,
        SubcomponentTwo: SubcomponentTwo
      };
      return MapClass = ComponentMap(function(desc) {
        return typeMap[desc];
      });
    });
    it('should mount instance of class on store', function() {
      rootComponentInstance = new MapClass();
      return mountRootComponent(store, rootComponentInstance);
    });
    it('should mount component 1', function() {
      rootComponentInstance.add('one', 'SubcomponentOne');
      return expect(rootComponentInstance.get('one').get()).to.equal('mounted');
    });
    it('should error on duplicate key', function() {
      return expect(function() {
        return rootComponentInstance.add('one', 'SubcomponentOne');
      }).to["throw"]("duplicate key");
    });
    it('should mount component 2', function() {
      rootComponentInstance.add('two', 'SubcomponentTwo');
      return expect(rootComponentInstance.get('two').get()).to.equal('mounted');
    });
    it('should exercise mounted components', function() {
      rootComponentInstance.get('one').set('hello');
      expect(rootComponentInstance.get('one').get()).to.equal('hello');
      rootComponentInstance.get('two').set('world');
      return expect(rootComponentInstance.get('two').get()).to.equal('world');
    });
    it('should unmount component 1', function() {
      rootComponentInstance.remove('one');
      return expect(rootComponentInstance.get('one')).to.not.be.ok;
    });
    it('should do nothing on double removal', function() {
      return rootComponentInstance.remove('one');
    });
    return it('should flush component 1 data after a reduction that would change the store', function() {
      rootComponentInstance.get('two').set('next');
      return expect(rootComponentInstance.state.one).to.not.be.ok;
    });
  });
});
