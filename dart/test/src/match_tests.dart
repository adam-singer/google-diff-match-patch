part of diff_match_patch_test_harness;

//  MATCH TEST FUNCTIONS

void testMatchAlphabet() {
  void assertMapEquals(Map a, Map b, String error_msg) {
    Function eq = const ListEquality().equals;
    var _a = a.keys.toList();
    _a.sort();
    var _b = b.keys.toList();
    _b.sort();
    expect(_a, _b, reason: error_msg);
    for (var x in a.keys) {
      expect(a[x], b[x], reason: "$error_msg [Key: $x]");
    }
  }

  // Initialise the bitmasks for Bitap.
  Map<String, int> bitmask = {'a': 4, 'b': 2, 'c': 1};
  assertMapEquals(bitmask, callPrivateWithReturn('_match_alphabet', ['abc']), 'match_alphabet: Unique.');

  bitmask = {'a': 37, 'b': 18, 'c': 8};
  assertMapEquals(bitmask, callPrivateWithReturn('_match_alphabet', ['abcaba']), 'match_alphabet: Duplicates.');
}

void testMatchBitap() {
  // Bitap algorithm.
  dmp.Match_Distance = 100;
  dmp.Match_Threshold = 0.5;
  expect(5, callPrivateWithReturn('_match_bitap', ['abcdefghijk', 'fgh', 5]), reason: 'match_bitap: Exact match #1.');

  expect(5, callPrivateWithReturn('_match_bitap', ['abcdefghijk', 'fgh', 0]), reason: 'match_bitap: Exact match #2.');

  expect(4, callPrivateWithReturn('_match_bitap', ['abcdefghijk', 'efxhi', 0]), reason: 'match_bitap: Fuzzy match #1.');

  expect(2, callPrivateWithReturn('_match_bitap', ['abcdefghijk', 'cdefxyhijk', 5]), reason: 'match_bitap: Fuzzy match #2.');

  expect(-1, callPrivateWithReturn('_match_bitap', ['abcdefghijk', 'bxy', 1]), reason: 'match_bitap: Fuzzy match #3.');

  expect(2, callPrivateWithReturn('_match_bitap', ['123456789xx0', '3456789x0', 2]), reason: 'match_bitap: Overflow.');

  expect(0, callPrivateWithReturn('_match_bitap', ['abcdef', 'xxabc', 4]), reason: 'match_bitap: Before start match.');

  expect(3, callPrivateWithReturn('_match_bitap', ['abcdef', 'defyy', 4]), reason: 'match_bitap: Beyond end match.');

  expect(0, callPrivateWithReturn('_match_bitap', ['abcdef', 'xabcdefy', 0]), reason: 'match_bitap: Oversized pattern.');

  dmp.Match_Threshold = 0.4;
  expect(4, callPrivateWithReturn('_match_bitap', ['abcdefghijk', 'efxyhi', 1]), reason: 'match_bitap: Threshold #1.');

  dmp.Match_Threshold = 0.3;
  expect(-1, callPrivateWithReturn('_match_bitap', ['abcdefghijk', 'efxyhi', 1]), reason: 'match_bitap: Threshold #2.');

  dmp.Match_Threshold = 0.0;
  expect(1, callPrivateWithReturn('_match_bitap', ['abcdefghijk', 'bcdef', 1]), reason: 'match_bitap: Threshold #3.');

  dmp.Match_Threshold = 0.5;
  expect(0, callPrivateWithReturn('_match_bitap', ['abcdexyzabcde', 'abccde', 3]), reason: 'match_bitap: Multiple select #1.');

  expect(8, callPrivateWithReturn('_match_bitap', ['abcdexyzabcde', 'abccde', 5]), reason: 'match_bitap: Multiple select #2.');

  dmp.Match_Distance = 10;  // Strict location.
  expect(-1, callPrivateWithReturn('_match_bitap', ['abcdefghijklmnopqrstuvwxyz', 'abcdefg', 24]), reason: 'match_bitap: Distance test #1.');

  expect(0, callPrivateWithReturn('_match_bitap', ['abcdefghijklmnopqrstuvwxyz', 'abcdxxefg', 1]), reason: 'match_bitap: Distance test #2.');

  dmp.Match_Distance = 1000;  // Loose location.
  expect(0, callPrivateWithReturn('_match_bitap', ['abcdefghijklmnopqrstuvwxyz', 'abcdefg', 24]), reason: 'match_bitap: Distance test #3.');
}

void testMatchMain() {
  // Full match.
  expect(0, dmp.match_main('abcdef', 'abcdef', 1000), reason: 'match_main: Equality.');

  expect(-1, dmp.match_main('', 'abcdef', 1), reason: 'match_main: Null text.');

  expect(3, dmp.match_main('abcdef', '', 3), reason: 'match_main: Null pattern.');

  expect(3, dmp.match_main('abcdef', 'de', 3), reason: 'match_main: Exact match.');

  expect(3, dmp.match_main('abcdef', 'defy', 4), reason: 'match_main: Beyond end match.');

  expect(0, dmp.match_main('abcdef', 'abcdefy', 0), reason: 'match_main: Oversized pattern.');

  dmp.Match_Threshold = 0.7;
  expect(4, dmp.match_main('I am the very model of a modern major general.', ' that berry ', 5), reason: 'match_main: Complex match.');
  dmp.Match_Threshold = 0.5;

  // Test null inputs.
  expect(() => dmp.match_main(null, null, 0), throwsArgumentError, reason: 'match_main: Null inputs.');
}
