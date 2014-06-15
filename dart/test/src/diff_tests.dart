part of diff_match_patch_test_harness;

// DIFF TEST FUNCTIONS

void testDiffCommonPrefix() {
  // Detect any common prefix.
  expect(dmp.diff_commonPrefix('abc', 'xyz'), equals(0), reason: 'diff_commonPrefix: Null case.');

  expect(dmp.diff_commonPrefix('1234abcdef', '1234xyz'), equals(4), reason: 'diff_commonPrefix: Non-null case.');

  expect(dmp.diff_commonPrefix('1234', '1234xyz'), equals(4), reason: 'diff_commonPrefix: Whole case.');
}

void testDiffCommonSuffix() {
  // Detect any common suffix.
  expect(dmp.diff_commonSuffix('abc', 'xyz'), equals(0), reason: 'diff_commonSuffix: Null case.');

  expect(dmp.diff_commonSuffix('abcdef1234', 'xyz1234'), equals(4), reason: 'diff_commonSuffix: Non-null case.');

  expect(dmp.diff_commonSuffix('1234', 'xyz1234'), equals(4), reason: 'diff_commonSuffix: Whole case.');
}

void testDiffCommonOverlap() {
  // Detect any suffix/prefix overlap.
  expect(callPrivateWithReturn('_diff_commonOverlap', ['', 'abcd']), equals(0), reason: 'diff_commonOverlap: Null case.');

  expect(callPrivateWithReturn('_diff_commonOverlap', ['abc', 'abcd']), equals(3), reason: 'diff_commonOverlap: Whole case.');

  expect(callPrivateWithReturn('_diff_commonOverlap', ['123456', 'abcd']), equals(0), reason: 'diff_commonOverlap: No overlap.');

  expect(callPrivateWithReturn('_diff_commonOverlap', ['123456xxx', 'xxxabcd']), equals(3), reason: 'diff_commonOverlap: Overlap.');

  // Some overly clever languages (C#) may treat ligatures as equal to their
  // component letters.  E.g. U+FB01 == 'fi'
  expect(callPrivateWithReturn('_diff_commonOverlap', ['fi', '\ufb01i']), equals(0), reason: 'diff_commonOverlap: Unicode.');
}

void testDiffHalfmatch() {
  // Detect a halfmatch.
  dmp.Diff_Timeout = 1.0;
  expect(callPrivateWithReturn('_diff_halfMatch', ['1234567890', 'abcdef']), isNull, reason: 'diff_halfMatch: No match #1.');

  expect(callPrivateWithReturn('_diff_halfMatch', ['12345', '23']), isNull, reason: 'diff_halfMatch: No match #2.');

  expect(callPrivateWithReturn('_diff_halfMatch', ['1234567890', 'a345678z']), ['12', '90', 'a', 'z', '345678'], reason: 'diff_halfMatch: Single Match #1.');

  expect(callPrivateWithReturn('_diff_halfMatch', ['a345678z', '1234567890']), ['a', 'z', '12', '90', '345678'], reason: 'diff_halfMatch: Single Match #2.');

  expect(callPrivateWithReturn('_diff_halfMatch', ['abc56789z', '1234567890']), ['abc', 'z', '1234', '0', '56789'], reason: 'diff_halfMatch: Single Match #3.');

  expect(callPrivateWithReturn('_diff_halfMatch', ['a23456xyz', '1234567890']), ['a', 'xyz', '1', '7890', '23456'], reason: 'diff_halfMatch: Single Match #4.');

  expect(callPrivateWithReturn('_diff_halfMatch', ['121231234123451234123121', 'a1234123451234z']), ['12123', '123121', 'a', 'z', '1234123451234'], reason: 'diff_halfMatch: Multiple Matches #1.');

  expect(callPrivateWithReturn('_diff_halfMatch', ['x-=-=-=-=-=-=-=-=-=-=-=-=', 'xx-=-=-=-=-=-=-=']), ['', '-=-=-=-=-=', 'x', '', 'x-=-=-=-=-=-=-='], reason: 'diff_halfMatch: Multiple Matches #2.');

  expect(callPrivateWithReturn('_diff_halfMatch', ['-=-=-=-=-=-=-=-=-=-=-=-=y', '-=-=-=-=-=-=-=yy']), ['-=-=-=-=-=', '', '', 'y', '-=-=-=-=-=-=-=y'], reason: 'diff_halfMatch: Multiple Matches #3.');

  // Optimal diff would be -q+x=H-i+e=lloHe+Hu=llo-Hew+y not -qHillo+x=HelloHe-w+Hulloy
  expect(callPrivateWithReturn('_diff_halfMatch', ['qHilloHelloHew', 'xHelloHeHulloy']), ['qHillo', 'w', 'x', 'Hulloy', 'HelloHe'], reason: 'diff_halfMatch: Non-optimal halfmatch.');

  dmp.Diff_Timeout = 0.0;
  expect(callPrivateWithReturn('_diff_halfMatch', ['qHilloHelloHew', 'xHelloHeHulloy']), isNull, reason: 'diff_halfMatch: Optimal no halfmatch.');
}

void testDiffLinesToChars() {
  void assertLinesToCharsResultEquals(Map<String, dynamic> a, Map<String, dynamic> b, String error_msg) {
    expect(a['chars1'], equals(b['chars1']), reason: error_msg);
    expect(a['chars2'], equals(b['chars2']), reason: error_msg);
    expect(a['lineArray'], equals(b['lineArray']), reason: error_msg);
  }

  // Convert lines down to characters.
  assertLinesToCharsResultEquals(callPrivateWithReturn('_diff_linesToChars', ['alpha\nbeta\nalpha\n', 'beta\nalpha\nbeta\n']),
      {'chars1': '\u0001\u0002\u0001', 'chars2': '\u0002\u0001\u0002', 'lineArray': ['', 'alpha\n', 'beta\n']},
                                     'diff_linesToChars: Shared lines.');

  assertLinesToCharsResultEquals(callPrivateWithReturn('_diff_linesToChars', ['', 'alpha\r\nbeta\r\n\r\n\r\n']),
      {'chars1': '', 'chars2': '\u0001\u0002\u0003\u0003', 'lineArray': ['', 'alpha\r\n', 'beta\r\n', '\r\n']},
                                     'diff_linesToChars: Empty string and blank lines.');

  assertLinesToCharsResultEquals(callPrivateWithReturn('_diff_linesToChars', ['a', 'b']),
      {'chars1': '\u0001', 'chars2': '\u0002', 'lineArray': ['', 'a', 'b']},
                                     'diff_linesToChars: No linebreaks.');

  // More than 256 to reveal any 8-bit limitations.
  int n = 300;
  List<String> lineList = [];
  StringBuffer charList = new StringBuffer();
  for (int x = 1; x < n + 1; x++) {
    lineList.add('$x\n');
    charList.write(new String.fromCharCodes([x]));
  }
  expect(n, lineList.length);
  String lines = lineList.join();
  String chars = charList.toString();
  expect(n, chars.length);
  lineList.insert(0, '');
  assertLinesToCharsResultEquals(callPrivateWithReturn('_diff_linesToChars', [lines, '']),
                                 {'chars1': chars, 'chars2': '', 'lineArray': lineList},
      'diff_linesToChars: More than 256.');
}

void testDiffCharsToLines() {
  // First check that Diff equality works.
  expect(new Diff(DIFF_EQUAL, 'a') == new Diff(DIFF_EQUAL, 'a'), isTrue, reason: 'diff_charsToLines: Equality #1.');

  expect(new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_EQUAL, 'a'), reason: 'diff_charsToLines: Equality #2.');

  // Convert chars up to lines.
  List<Diff> diffs = [new Diff(DIFF_EQUAL, '\u0001\u0002\u0001'), new Diff(DIFF_INSERT, '\u0002\u0001\u0002')];
  callPrivate('_diff_charsToLines', [diffs, ['', 'alpha\n', 'beta\n']]);
  expect(diffs, equals([new Diff(DIFF_EQUAL, 'alpha\nbeta\nalpha\n'), new Diff(DIFF_INSERT, 'beta\nalpha\nbeta\n')]), reason: 'diff_charsToLines: Shared lines.');

  // More than 256 to reveal any 8-bit limitations.
  int n = 300;
  List<String> lineList = [];
  StringBuffer charList = new StringBuffer();
  for (int x = 1; x < n + 1; x++) {
    lineList.add('$x\n');
    charList.write(new String.fromCharCodes([x]));
  }
  expect(n, lineList.length);
  String lines = lineList.join();
  String chars = charList.toString();
  expect(n, chars.length);
  lineList.insert(0, '');
  diffs = [new Diff(DIFF_DELETE, chars)];
  callPrivate('_diff_charsToLines', [diffs, lineList]);
  expect(diffs, [new Diff(DIFF_DELETE, lines)], reason: 'diff_charsToLines: More than 256.');
}

void testDiffCleanupMerge() {
  // Cleanup a messy diff.
  List<Diff> diffs = [];
  dmp.diff_cleanupMerge(diffs);
  expect([], diffs, reason: 'diff_cleanupMerge: Null case.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'b'), new Diff(DIFF_INSERT, 'c')];
  dmp.diff_cleanupMerge(diffs);
  expect([new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'b'), new Diff(DIFF_INSERT, 'c')], diffs, reason: 'diff_cleanupMerge: No change case.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_EQUAL, 'b'), new Diff(DIFF_EQUAL, 'c')];
  dmp.diff_cleanupMerge(diffs);
  expect([new Diff(DIFF_EQUAL, 'abc')], diffs, reason: 'diff_cleanupMerge: Merge equalities.');

  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_DELETE, 'b'), new Diff(DIFF_DELETE, 'c')];
  dmp.diff_cleanupMerge(diffs);
  expect([new Diff(DIFF_DELETE, 'abc')], diffs, reason: 'diff_cleanupMerge: Merge deletions.');

  diffs = [new Diff(DIFF_INSERT, 'a'), new Diff(DIFF_INSERT, 'b'), new Diff(DIFF_INSERT, 'c')];
  dmp.diff_cleanupMerge(diffs);
  expect([new Diff(DIFF_INSERT, 'abc')], diffs, reason: 'diff_cleanupMerge: Merge insertions.');

  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_INSERT, 'b'), new Diff(DIFF_DELETE, 'c'), new Diff(DIFF_INSERT, 'd'), new Diff(DIFF_EQUAL, 'e'), new Diff(DIFF_EQUAL, 'f')];
  dmp.diff_cleanupMerge(diffs);
  expect([new Diff(DIFF_DELETE, 'ac'), new Diff(DIFF_INSERT, 'bd'), new Diff(DIFF_EQUAL, 'ef')], diffs, reason: 'diff_cleanupMerge: Merge interweave.');

  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_INSERT, 'abc'), new Diff(DIFF_DELETE, 'dc')];
  dmp.diff_cleanupMerge(diffs);
  expect([new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'd'), new Diff(DIFF_INSERT, 'b'), new Diff(DIFF_EQUAL, 'c')], diffs, reason: 'diff_cleanupMerge: Prefix and suffix detection.');

  diffs = [new Diff(DIFF_EQUAL, 'x'), new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_INSERT, 'abc'), new Diff(DIFF_DELETE, 'dc'), new Diff(DIFF_EQUAL, 'y')];
  dmp.diff_cleanupMerge(diffs);
  expect([new Diff(DIFF_EQUAL, 'xa'), new Diff(DIFF_DELETE, 'd'), new Diff(DIFF_INSERT, 'b'), new Diff(DIFF_EQUAL, 'cy')], diffs, reason: 'diff_cleanupMerge: Prefix and suffix detection with equalities.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_INSERT, 'ba'), new Diff(DIFF_EQUAL, 'c')];
  dmp.diff_cleanupMerge(diffs);
  expect([new Diff(DIFF_INSERT, 'ab'), new Diff(DIFF_EQUAL, 'ac')], diffs, reason: 'diff_cleanupMerge: Slide edit left.');

  diffs = [new Diff(DIFF_EQUAL, 'c'), new Diff(DIFF_INSERT, 'ab'), new Diff(DIFF_EQUAL, 'a')];
  dmp.diff_cleanupMerge(diffs);
  expect([new Diff(DIFF_EQUAL, 'ca'), new Diff(DIFF_INSERT, 'ba')], diffs, reason: 'diff_cleanupMerge: Slide edit right.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'b'), new Diff(DIFF_EQUAL, 'c'), new Diff(DIFF_DELETE, 'ac'), new Diff(DIFF_EQUAL, 'x')];
  dmp.diff_cleanupMerge(diffs);
  expect([new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_EQUAL, 'acx')], diffs, reason: 'diff_cleanupMerge: Slide edit left recursive.');

  diffs = [new Diff(DIFF_EQUAL, 'x'), new Diff(DIFF_DELETE, 'ca'), new Diff(DIFF_EQUAL, 'c'), new Diff(DIFF_DELETE, 'b'), new Diff(DIFF_EQUAL, 'a')];
  dmp.diff_cleanupMerge(diffs);
  expect([new Diff(DIFF_EQUAL, 'xca'), new Diff(DIFF_DELETE, 'cba')], diffs, reason: 'diff_cleanupMerge: Slide edit right recursive.');
}

void testDiffCleanupSemanticLossless() {
  // Slide diffs to match logical boundaries.
  List<Diff> diffs = [];
  callPrivate('_diff_cleanupSemanticLossless', [diffs]);
  expect([], diffs, reason: 'diff_cleanupSemanticLossless: Null case.');

  diffs = [new Diff(DIFF_EQUAL, 'AAA\r\n\r\nBBB'), new Diff(DIFF_INSERT, '\r\nDDD\r\n\r\nBBB'), new Diff(DIFF_EQUAL, '\r\nEEE')];
  callPrivate('_diff_cleanupSemanticLossless', [diffs]);
  expect([new Diff(DIFF_EQUAL, 'AAA\r\n\r\n'), new Diff(DIFF_INSERT, 'BBB\r\nDDD\r\n\r\n'), new Diff(DIFF_EQUAL, 'BBB\r\nEEE')], diffs, reason: 'diff_cleanupSemanticLossless: Blank lines.');

  diffs = [new Diff(DIFF_EQUAL, 'AAA\r\nBBB'), new Diff(DIFF_INSERT, ' DDD\r\nBBB'), new Diff(DIFF_EQUAL, ' EEE')];
  callPrivate('_diff_cleanupSemanticLossless', [diffs]);
  expect([new Diff(DIFF_EQUAL, 'AAA\r\n'), new Diff(DIFF_INSERT, 'BBB DDD\r\n'), new Diff(DIFF_EQUAL, 'BBB EEE')], diffs, reason: 'diff_cleanupSemanticLossless: Line boundaries.');

  diffs = [new Diff(DIFF_EQUAL, 'The c'), new Diff(DIFF_INSERT, 'ow and the c'), new Diff(DIFF_EQUAL, 'at.')];
  callPrivate('_diff_cleanupSemanticLossless', [diffs]);
  expect([new Diff(DIFF_EQUAL, 'The '), new Diff(DIFF_INSERT, 'cow and the '), new Diff(DIFF_EQUAL, 'cat.')], diffs, reason: 'diff_cleanupSemanticLossless: Word boundaries.');

  diffs = [new Diff(DIFF_EQUAL, 'The-c'), new Diff(DIFF_INSERT, 'ow-and-the-c'), new Diff(DIFF_EQUAL, 'at.')];
  callPrivate('_diff_cleanupSemanticLossless', [diffs]);
  expect([new Diff(DIFF_EQUAL, 'The-'), new Diff(DIFF_INSERT, 'cow-and-the-'), new Diff(DIFF_EQUAL, 'cat.')], diffs, reason: 'diff_cleanupSemanticLossless: Alphanumeric boundaries.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_EQUAL, 'ax')];
  callPrivate('_diff_cleanupSemanticLossless', [diffs]);
  expect([new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_EQUAL, 'aax')], diffs, reason: 'diff_cleanupSemanticLossless: Hitting the start.');

  diffs = [new Diff(DIFF_EQUAL, 'xa'), new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_EQUAL, 'a')];
  callPrivate('_diff_cleanupSemanticLossless', [diffs]);
  expect([new Diff(DIFF_EQUAL, 'xaa'), new Diff(DIFF_DELETE, 'a')], diffs, reason: 'diff_cleanupSemanticLossless: Hitting the end.');

  diffs = [new Diff(DIFF_EQUAL, 'The xxx. The '), new Diff(DIFF_INSERT, 'zzz. The '), new Diff(DIFF_EQUAL, 'yyy.')];
  callPrivate('_diff_cleanupSemanticLossless', [diffs]);
  expect([new Diff(DIFF_EQUAL, 'The xxx.'), new Diff(DIFF_INSERT, ' The zzz.'), new Diff(DIFF_EQUAL, ' The yyy.')], diffs, reason: 'diff_cleanupSemanticLossless: Sentence boundaries.');
}

void testDiffCleanupSemantic() {
  // Cleanup semantically trivial equalities.
  List<Diff> diffs = [];
  dmp.diff_cleanupSemantic(diffs);
  expect([], diffs, reason: 'diff_cleanupSemantic: Null case.');

  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, 'cd'), new Diff(DIFF_EQUAL, '12'), new Diff(DIFF_DELETE, 'e')];
  dmp.diff_cleanupSemantic(diffs);
  expect([new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, 'cd'), new Diff(DIFF_EQUAL, '12'), new Diff(DIFF_DELETE, 'e')], diffs, reason: 'diff_cleanupSemantic: No elimination #1.');

  diffs = [new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_INSERT, 'ABC'), new Diff(DIFF_EQUAL, '1234'), new Diff(DIFF_DELETE, 'wxyz')];
  dmp.diff_cleanupSemantic(diffs);
  expect([new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_INSERT, 'ABC'), new Diff(DIFF_EQUAL, '1234'), new Diff(DIFF_DELETE, 'wxyz')], diffs, reason: 'diff_cleanupSemantic: No elimination #2.');

  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_EQUAL, 'b'), new Diff(DIFF_DELETE, 'c')];
  dmp.diff_cleanupSemantic(diffs);
  expect([new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_INSERT, 'b')], diffs, reason: 'diff_cleanupSemantic: Simple elimination.');

  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_EQUAL, 'cd'), new Diff(DIFF_DELETE, 'e'), new Diff(DIFF_EQUAL, 'f'), new Diff(DIFF_INSERT, 'g')];
  dmp.diff_cleanupSemantic(diffs);
  expect([new Diff(DIFF_DELETE, 'abcdef'), new Diff(DIFF_INSERT, 'cdfg')], diffs, reason: 'diff_cleanupSemantic: Backpass elimination.');

  diffs = [new Diff(DIFF_INSERT, '1'), new Diff(DIFF_EQUAL, 'A'), new Diff(DIFF_DELETE, 'B'), new Diff(DIFF_INSERT, '2'), new Diff(DIFF_EQUAL, '_'), new Diff(DIFF_INSERT, '1'), new Diff(DIFF_EQUAL, 'A'), new Diff(DIFF_DELETE, 'B'), new Diff(DIFF_INSERT, '2')];
  dmp.diff_cleanupSemantic(diffs);
  expect([new Diff(DIFF_DELETE, 'AB_AB'), new Diff(DIFF_INSERT, '1A2_1A2')], diffs, reason: 'diff_cleanupSemantic: Multiple elimination.');

  diffs = [new Diff(DIFF_EQUAL, 'The c'), new Diff(DIFF_DELETE, 'ow and the c'), new Diff(DIFF_EQUAL, 'at.')];
  dmp.diff_cleanupSemantic(diffs);
  expect([new Diff(DIFF_EQUAL, 'The '), new Diff(DIFF_DELETE, 'cow and the '), new Diff(DIFF_EQUAL, 'cat.')], diffs, reason: 'diff_cleanupSemantic: Word boundaries.');

  diffs = [new Diff(DIFF_DELETE, 'abcxx'), new Diff(DIFF_INSERT, 'xxdef')];
  dmp.diff_cleanupSemantic(diffs);
  expect([new Diff(DIFF_DELETE, 'abcxx'), new Diff(DIFF_INSERT, 'xxdef')], diffs, reason: 'diff_cleanupSemantic: No overlap elimination.');

  diffs = [new Diff(DIFF_DELETE, 'abcxxx'), new Diff(DIFF_INSERT, 'xxxdef')];
  dmp.diff_cleanupSemantic(diffs);
  expect([new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_EQUAL, 'xxx'), new Diff(DIFF_INSERT, 'def')], diffs, reason: 'diff_cleanupSemantic: Overlap elimination.');

  diffs = [new Diff(DIFF_DELETE, 'xxxabc'), new Diff(DIFF_INSERT, 'defxxx')];
  dmp.diff_cleanupSemantic(diffs);
  expect([new Diff(DIFF_INSERT, 'def'), new Diff(DIFF_EQUAL, 'xxx'), new Diff(DIFF_DELETE, 'abc')], diffs, reason: 'diff_cleanupSemantic: Reverse overlap elimination.');

  diffs = [new Diff(DIFF_DELETE, 'abcd1212'), new Diff(DIFF_INSERT, '1212efghi'), new Diff(DIFF_EQUAL, '----'), new Diff(DIFF_DELETE, 'A3'), new Diff(DIFF_INSERT, '3BC')];
  dmp.diff_cleanupSemantic(diffs);
  expect([new Diff(DIFF_DELETE, 'abcd'), new Diff(DIFF_EQUAL, '1212'), new Diff(DIFF_INSERT, 'efghi'), new Diff(DIFF_EQUAL, '----'), new Diff(DIFF_DELETE, 'A'), new Diff(DIFF_EQUAL, '3'), new Diff(DIFF_INSERT, 'BC')], diffs, reason: 'diff_cleanupSemantic: Two overlap eliminations.');
}

void testDiffCleanupEfficiency() {
  // Cleanup operationally trivial equalities.
  dmp.Diff_EditCost = 4;
  List<Diff> diffs = [];
  dmp.diff_cleanupEfficiency(diffs);
  expect([], diffs, reason: 'diff_cleanupEfficiency: Null case.');

  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'wxyz'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '34')];
  dmp.diff_cleanupEfficiency(diffs);
  expect([new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'wxyz'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '34')], diffs, reason: 'diff_cleanupEfficiency: No elimination.');

  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'xyz'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '34')];
  dmp.diff_cleanupEfficiency(diffs);
  expect([new Diff(DIFF_DELETE, 'abxyzcd'), new Diff(DIFF_INSERT, '12xyz34')], diffs, reason: 'diff_cleanupEfficiency: Four-edit elimination.');

  diffs = [new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'x'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '34')];
  dmp.diff_cleanupEfficiency(diffs);
  expect([new Diff(DIFF_DELETE, 'xcd'), new Diff(DIFF_INSERT, '12x34')], diffs, reason: 'diff_cleanupEfficiency: Three-edit elimination.');

  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'xy'), new Diff(DIFF_INSERT, '34'), new Diff(DIFF_EQUAL, 'z'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '56')];
  dmp.diff_cleanupEfficiency(diffs);
  expect([new Diff(DIFF_DELETE, 'abxyzcd'), new Diff(DIFF_INSERT, '12xy34z56')], diffs, reason: 'diff_cleanupEfficiency: Backpass elimination.');

  dmp.Diff_EditCost = 5;
  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'wxyz'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '34')];
  dmp.diff_cleanupEfficiency(diffs);
  expect([new Diff(DIFF_DELETE, 'abwxyzcd'), new Diff(DIFF_INSERT, '12wxyz34')], diffs, reason: 'diff_cleanupEfficiency: High cost elimination.');
  dmp.Diff_EditCost = 4;
}

void testDiffPrettyHtml() {
  // Pretty print.
  List<Diff> diffs = [new Diff(DIFF_EQUAL, 'a\n'), new Diff(DIFF_DELETE, '<B>b</B>'), new Diff(DIFF_INSERT, 'c&d')];
  expect('<span>a&para;<br></span><del style="background:#ffe6e6;">&lt;B&gt;b&lt;/B&gt;</del><ins style="background:#e6ffe6;">c&amp;d</ins>', dmp.diff_prettyHtml(diffs), reason: 'diff_prettyHtml:');
}

void testDiffText() {
  // Compute the source and destination texts.
  List<Diff> diffs = [new Diff(DIFF_EQUAL, 'jump'), new Diff(DIFF_DELETE, 's'), new Diff(DIFF_INSERT, 'ed'), new Diff(DIFF_EQUAL, ' over '), new Diff(DIFF_DELETE, 'the'), new Diff(DIFF_INSERT, 'a'), new Diff(DIFF_EQUAL, ' lazy')];
  expect('jumps over the lazy', dmp.diff_text1(diffs), reason: 'diff_text1:');
  expect('jumped over a lazy', dmp.diff_text2(diffs), reason: 'diff_text2:');
}

void testDiffDelta() {
  // Convert a diff into delta string.
  List<Diff> diffs = [new Diff(DIFF_EQUAL, 'jump'), new Diff(DIFF_DELETE, 's'), new Diff(DIFF_INSERT, 'ed'), new Diff(DIFF_EQUAL, ' over '), new Diff(DIFF_DELETE, 'the'), new Diff(DIFF_INSERT, 'a'), new Diff(DIFF_EQUAL, ' lazy'), new Diff(DIFF_INSERT, 'old dog')];
  String text1 = dmp.diff_text1(diffs);
  expect('jumps over the lazy', text1, reason: 'diff_text1: Base text.');

  String delta = dmp.diff_toDelta(diffs);
  expect('=4\t-1\t+ed\t=6\t-3\t+a\t=5\t+old dog', delta, reason: 'diff_toDelta:');

  // Convert delta string into a diff.
  expect(diffs, dmp.diff_fromDelta(text1, delta), reason: 'diff_fromDelta: Normal.');

  // Generates error (19 < 20).
  expect(() => dmp.diff_fromDelta('${text1}x', delta), throwsArgumentError, reason: 'diff_fromDelta: Too long.');

  // Generates error (19 > 18).
  expect(() => dmp.diff_fromDelta(text1.substring(1), delta), throwsArgumentError, reason: 'diff_fromDelta: Too short.');

  // Generates error (%c3%xy invalid Unicode).
  expect(() => dmp.diff_fromDelta('', '+%c3%xy'), throwsArgumentError, reason: 'diff_fromDelta: Invalid character.');

  // Test deltas with special characters.
  diffs = [new Diff(DIFF_EQUAL, '\u0680 \x00 \t %'), new Diff(DIFF_DELETE, '\u0681 \x01 \n ^'), new Diff(DIFF_INSERT, '\u0682 \x02 \\ |')];
  text1 = dmp.diff_text1(diffs);
  expect('\u0680 \x00 \t %\u0681 \x01 \n ^', text1, reason: 'diff_text1: Unicode text.');

  delta = dmp.diff_toDelta(diffs);
  expect('=7\t-7\t+%DA%82 %02 %5C %7C', delta, reason: 'diff_toDelta: Unicode.');

  expect(diffs, dmp.diff_fromDelta(text1, delta), reason: 'diff_fromDelta: Unicode.');

  // Verify pool of unchanged characters.
  diffs = [new Diff(DIFF_INSERT, 'A-Z a-z 0-9 - _ . ! ~ * \' ( ) ; / ? : @ & = + \$ , # ')];
  String text2 = dmp.diff_text2(diffs);
  expect('A-Z a-z 0-9 - _ . ! ~ * \' ( ) ; / ? : @ & = + \$ , # ', text2, reason: 'diff_text2: Unchanged characters.');

  delta = dmp.diff_toDelta(diffs);
  expect('+A-Z a-z 0-9 - _ . ! ~ * \' ( ) ; / ? : @ & = + \$ , # ', delta, reason: 'diff_toDelta: Unchanged characters.');

  // Convert delta string into a diff.
  expect(diffs, dmp.diff_fromDelta('', delta), reason: 'diff_fromDelta: Unchanged characters.');
}

void testDiffXIndex() {
  // Translate a location in text1 to text2.
  List<Diff> diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_INSERT, '1234'), new Diff(DIFF_EQUAL, 'xyz')];
  expect(5, dmp.diff_xIndex(diffs, 2), reason: 'diff_xIndex: Translation on equality.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, '1234'), new Diff(DIFF_EQUAL, 'xyz')];
  expect(1, dmp.diff_xIndex(diffs, 3), reason: 'diff_xIndex: Translation on deletion.');
}

void testDiffLevenshtein() {
  List<Diff> diffs = [new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_INSERT, '1234'), new Diff(DIFF_EQUAL, 'xyz')];
  expect(4, dmp.diff_levenshtein(diffs), reason: 'Levenshtein with trailing equality.');

  diffs = [new Diff(DIFF_EQUAL, 'xyz'), new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_INSERT, '1234')];
  expect(4, dmp.diff_levenshtein(diffs), reason: 'Levenshtein with leading equality.');

  diffs = [new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_EQUAL, 'xyz'), new Diff(DIFF_INSERT, '1234')];
  expect(7, dmp.diff_levenshtein(diffs), reason: 'Levenshtein with middle equality.');
}

void testDiffBisect() {
  // Normal.
  String a = 'cat';
  String b = 'map';
  // Since the resulting diff hasn't been normalized, it would be ok if
  // the insertion and deletion pairs are swapped.
  // If the order changes, tweak this test as required.
  List<Diff> diffs = [new Diff(DIFF_DELETE, 'c'), new Diff(DIFF_INSERT, 'm'), new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 't'), new Diff(DIFF_INSERT, 'p')];
  // One year should be sufficient.
  DateTime deadline = new DateTime.now().add(new Duration(days : 365));
  expect(diffs, callPrivateWithReturn('_diff_bisect', [a, b, deadline]), reason: 'diff_bisect: Normal.');

  // Timeout.
  diffs = [new Diff(DIFF_DELETE, 'cat'), new Diff(DIFF_INSERT, 'map')];
  // Set deadline to one year ago.
  deadline = new DateTime.now().subtract(new Duration(days : 365));
  expect(diffs, callPrivateWithReturn('_diff_bisect', [a, b, deadline]), reason: 'diff_bisect: Timeout.');
}

void testDiffMain() {
  // Perform a trivial diff.
  List<Diff> diffs = [];
  expect(diffs, dmp.diff_main('', '', false), reason: 'diff_main: Null case.');

  diffs = [new Diff(DIFF_EQUAL, 'abc')];
  expect(diffs, dmp.diff_main('abc', 'abc', false), reason: 'diff_main: Equality.');

  diffs = [new Diff(DIFF_EQUAL, 'ab'), new Diff(DIFF_INSERT, '123'), new Diff(DIFF_EQUAL, 'c')];
  expect(diffs, dmp.diff_main('abc', 'ab123c', false), reason: 'diff_main: Simple insertion.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, '123'), new Diff(DIFF_EQUAL, 'bc')];
  expect(diffs, dmp.diff_main('a123bc', 'abc', false), reason: 'diff_main: Simple deletion.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_INSERT, '123'), new Diff(DIFF_EQUAL, 'b'), new Diff(DIFF_INSERT, '456'), new Diff(DIFF_EQUAL, 'c')];
  expect(diffs, dmp.diff_main('abc', 'a123b456c', false), reason: 'diff_main: Two insertions.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, '123'), new Diff(DIFF_EQUAL, 'b'), new Diff(DIFF_DELETE, '456'), new Diff(DIFF_EQUAL, 'c')];
  expect(diffs, dmp.diff_main('a123b456c', 'abc', false), reason: 'diff_main: Two deletions.');

  // Perform a real diff.
  // Switch off the timeout.
  dmp.Diff_Timeout = 0.0;
  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_INSERT, 'b')];
  expect(diffs, dmp.diff_main('a', 'b', false), reason: 'diff_main: Simple case #1.');

  diffs = [new Diff(DIFF_DELETE, 'Apple'), new Diff(DIFF_INSERT, 'Banana'), new Diff(DIFF_EQUAL, 's are a'), new Diff(DIFF_INSERT, 'lso'), new Diff(DIFF_EQUAL, ' fruit.')];
  expect(diffs, dmp.diff_main('Apples are a fruit.', 'Bananas are also fruit.', false), reason: 'diff_main: Simple case #2.');

  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_INSERT, '\u0680'), new Diff(DIFF_EQUAL, 'x'), new Diff(DIFF_DELETE, '\t'), new Diff(DIFF_INSERT, '\000')];
  expect(diffs, dmp.diff_main('ax\t', '\u0680x\000', false), reason: 'diff_main: Simple case #3.');

  diffs = [new Diff(DIFF_DELETE, '1'), new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'y'), new Diff(DIFF_EQUAL, 'b'), new Diff(DIFF_DELETE, '2'), new Diff(DIFF_INSERT, 'xab')];
  expect(diffs, dmp.diff_main('1ayb2', 'abxab', false), reason: 'diff_main: Overlap #1.');

  diffs = [new Diff(DIFF_INSERT, 'xaxcx'), new Diff(DIFF_EQUAL, 'abc'), new Diff(DIFF_DELETE, 'y')];
  expect(diffs, dmp.diff_main('abcy', 'xaxcxabc', false), reason: 'diff_main: Overlap #2.');

  diffs = [new Diff(DIFF_DELETE, 'ABCD'), new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, '='), new Diff(DIFF_INSERT, '-'), new Diff(DIFF_EQUAL, 'bcd'), new Diff(DIFF_DELETE, '='), new Diff(DIFF_INSERT, '-'), new Diff(DIFF_EQUAL, 'efghijklmnopqrs'), new Diff(DIFF_DELETE, 'EFGHIJKLMNOefg')];
  expect(diffs, dmp.diff_main('ABCDa=bcd=efghijklmnopqrsEFGHIJKLMNOefg', 'a-bcd-efghijklmnopqrs', false), reason: 'diff_main: Overlap #3.');

  diffs = [new Diff(DIFF_INSERT, ' '), new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_INSERT, 'nd'), new Diff(DIFF_EQUAL, ' [[Pennsylvania]]'), new Diff(DIFF_DELETE, ' and [[New')];
  expect(diffs, dmp.diff_main('a [[Pennsylvania]] and [[New', ' and [[Pennsylvania]]', false), reason: 'diff_main: Large equality.');

  dmp.Diff_Timeout = 0.1;  // 100ms
  String a = '`Twas brillig, and the slithy toves\nDid gyre and gimble in the wabe:\nAll mimsy were the borogoves,\nAnd the mome raths outgrabe.\n';
  String b = 'I am the very model of a modern major general,\nI\'ve information vegetable, animal, and mineral,\nI know the kings of England, and I quote the fights historical,\nFrom Marathon to Waterloo, in order categorical.\n';
  // Increase the text lengths by 1024 times to ensure a timeout.
  for (int x = 0; x < 10; x++) {
    a = '$a$a';
    b = '$b$b';
  }
  DateTime startTime = new DateTime.now();
  dmp.diff_main(a, b);
  DateTime endTime = new DateTime.now();
  double elapsedSeconds = endTime.difference(startTime).inMilliseconds / 1000;
  // Test that we took at least the timeout period.
  expect(dmp.Diff_Timeout <= elapsedSeconds, isTrue, reason: 'diff_main: Timeout min.');
  // Test that we didn't take forever (be forgiving).
  // Theoretically this test could fail very occasionally if the
  // OS task swaps or locks up for a second at the wrong moment.
  // *************
  // Dart Note:  Currently (2011) Dart's performance is out of control, so this
  // diff takes 3.5 seconds on a 0.1 second timeout.  Commented out.
  // *************
  // Expect.isTrue(dmp.Diff_Timeout * 2 > elapsedSeconds, 'diff_main: Timeout max.');
  dmp.Diff_Timeout = 0.0;

  // Test the linemode speedup.
  // Must be long to pass the 100 char cutoff.
  a = '1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n';
  b = 'abcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\n';
  expect(dmp.diff_main(a, b, true), dmp.diff_main(a, b, false), reason: 'diff_main: Simple line-mode.');

  a = '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
  b = 'abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij';
  expect(dmp.diff_main(a, b, true), dmp.diff_main(a, b, false), reason: 'diff_main: Single line-mode.');

  a = '1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n';
  b = 'abcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n';
  List<String> texts_linemode = _diff_rebuildtexts(dmp.diff_main(a, b, true));
  List<String> texts_textmode = _diff_rebuildtexts(dmp.diff_main(a, b, false));
  expect(texts_textmode, texts_linemode, reason: 'diff_main: Overlap line-mode.');

  // Test null inputs.
  expect(() => dmp.diff_main(null, null), throwsArgumentError, reason: 'diff_main: Null inputs.');
}
