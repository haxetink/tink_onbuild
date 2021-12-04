package ;

class RunTests {
  static function test() {
    tink.OnBuild.before.exprs.whenever(t -> c -> e -> switch e {
      case { expr: TConst(TString(c)) }: trace(c);
      default:
    });
    return macro null;
  }

}