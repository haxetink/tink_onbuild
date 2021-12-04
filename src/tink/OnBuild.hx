package tink;

#if macro
import haxe.ds.ReadOnlyArray;
import haxe.macro.Type;
import tink.priority.Queue;
import haxe.macro.*;
import tink.core.Lazy;
using haxe.macro.Tools;

class OnBuild {
  static function __init__() {
    Context.onGenerate(pass);
    Context.onAfterGenerate(() -> after.process(typesFound));
  }

  static public final before = new Passes();
  static public final after = new Passes();
  static var typesFound = null;

  static inline function field(c:ClassField) {
    var expr:Lazy<TypedExpr> = c.expr;
    (cast c).expr = () -> expr.get();
  }

  static function once<X>(r:Ref<X>, ?process)
    return switch r {
      case null: null;
      case v: new Once(r, process);
    }

  static final classes = new Map();
  static function cls(c:Ref<ClassType>):Ref<ClassType> {
    var key = c.toString();
    return switch classes[key] {
      case null:

        function fields(a:Ref<Array<ClassField>>)
          return new Once(a, fields -> for (f in fields) field(f));

        function process(c:ClassType) {
          #if tink_onbuild.cache_tast
          c.constructor = once(c.constructor, field);
          c.fields = fields(c.fields);
          c.statics = fields(c.statics);
          #end
          switch c.superClass {
            case null:
            case v:
              c.superClass.t = cls(c.superClass.t);
          }

          for (i in c.interfaces)
            i.t = cls(i.t);
        }
        classes[key] = new Once(c, process, key);
      case v: v;
    }
  }

  static function pass(types:Array<Type>) {
    for (i => t in types)
      types[i] = switch t {
        // case TEnum(t, params):
        case TInst(t, params):
          TInst(cls(t), params);

        // case TAbstract(t, params):
        //   TAbstract(new Once(t), params);
        default: t;
      }

    before.process(typesFound = types);
    // for (p in passes)

  }
}

private class Once<T> {
  final value:Lazy<T>;
  final rep:Lazy<String>;

  public function new(ref:Ref<T>, ?process:T->Void, ?str:String) {
    this.value = () -> {
      var v = ref.get();
      if (process != null) process(v);
      v;
    }

    this.rep = switch str {
      case null: ref.toString;
      case v: v;
    }
  }

  public function get():T
    return value;

	public function toString():String
    return rep;
}


private class Passes {
  public final types:Queue<ReadOnlyArray<Type>->Void>;
  public final exprs:Queue<Type->Null<ClassField->Null<TypedExpr->Void>>>;
  public function new() {
    this.exprs = new Queue();
    this.types = new Queue();
    this.types.whenever(traverse);
  }

  public function process(found:ReadOnlyArray<Type>) {
    for (t in types)
      t(found);
  }

  static var tast = new eval.Vector(1024);

  function traverse(found:ReadOnlyArray<Type>) {

    var count = 0,
        max = tast.length,
        tast = tast;

    inline function push(expr) {
      if (count == max) {
        tast = new eval.Vector(max * 2);
        Passes.tast.blit(0, tast, 0, max);
        max *= 2;
        Passes.tast = tast;
      }
      tast[count++] = expr;
    }

    for (t in found) {
      var funcs = [for (e in exprs) switch e(t) {
        case null: continue;
        case v: v;
      }];

      if (funcs.length == 0) continue;

      function field(c:ClassField) {
        count = -1;
        for (f in funcs)
          switch f(c) {
            case null:
            case cb:
              if (count == -1) {
                count = 0;
                switch c.expr() {
                  case null:
                  case e:
                    (function drill(e:TypedExpr) {
                      push(e);
                      e.iter(drill);
                    })(e);
                }
              }
              for (i in 0...count)
                cb(tast[i]);
          };

      }

      switch t {
        case TInst(_.get() => c, _):
          if (c.constructor != null)
            field(c.constructor.get());

          for (fields in [c.fields, c.statics])
            for (f in fields.get())
              field(f);
        default:
      }
    }
  }
}
#end