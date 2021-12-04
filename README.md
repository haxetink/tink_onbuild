# tink_onbuild

This is a helper library to streamline `onGenerate`/`onAfterGenerate` passes. It does two things:

1. Allow different libraries to register their passes in an orderly fashion via [`tink_priority`](https://github.com/haxetink/tink_priority#readme) queues.
2. Avoid duplicate encoding from compiler to interpreter data structures.

The basic API looks like this:

```haxe
class OnBuild {
  static public final before:Passes;
  static public final after:Passes;
}
// with this:
private class Passes {
  public final types:Queue<ReadOnlyArray<Type>->Void>;
  public final exprs:Queue<Type->Null<ClassField->Null<TypedExpr->Void>>>;
}
```

The callback type for expressions is a bit involved.

It is called for every type. If you wish to skip the type, you can return `null`. Otherwise, it is called with every field on the type. If you wish to skip the field, you can return `null`. Otherwise the returned callback is run on every subexpression of said field.

To run before/after the expression pass, use `tink.OnBuild.EXPR_PASS` as `ID`.

## Caution

Because the data structures of the macro APIs are mutable and the data is shared between all callbacks, it is left up to you not to mutate them - otherwise other callbacks may be passed falsified data.

## Defines

### Cache typed AST `-D tink_onbuild.cache_tast`

Setting this define will make it so that any field's typed AST is cached.