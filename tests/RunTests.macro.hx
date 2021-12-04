package ;

class RunTests {
  static function test() {
    tink.OnBuild.before.exprs.whenever(t -> e -> switch e {
      case { expr: TConst(TString(c)) }: trace(c);
      default:
    });
    return macro null;
  }

}