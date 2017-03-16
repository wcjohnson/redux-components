import createMemoizingGetter from 'nanotools/lib/createMemoizingGetter';

export default function bind(proto, key, descriptor) {
  var fn, ref;
  fn = descriptor.value;
  if (typeof fn !== 'function') {
    throw new Error(`@bind decorator (applied to ${((ref = proto.constructor) != null ? ref.name : void 0)}.${key}) can only be applied to functions.`);
  }
  return {
    configurable: true,
    get: createMemoizingGetter(proto, key, fn, function() {
      return fn.bind(this);
    })
  };
}
