package ;

import tink.OnBuild;

class RunTests {
  static function test() {
    OnBuild.before.exprs.whenever(t -> c -> e -> switch e {
      case { expr: TConst(TString(c)) }: trace(c);
      default:
    });
    OnBuild.before.types.before(OnBuild.EXPR_PASS, _ -> trace('before'), 'before');
    OnBuild.before.types.after(OnBuild.EXPR_PASS, _ -> trace('after'), 'after');
    return macro null;
  }

}