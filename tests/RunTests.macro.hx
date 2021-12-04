package ;

class RunTests {
  static function test() {
    onGenerate.Hub.before.exprs.whenever(t -> e -> switch e {
      case { expr: TConst(TString(c)) }: trace(c);
      default:
    });
    return macro null;
  }

}