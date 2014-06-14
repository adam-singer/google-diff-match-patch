/**
 * Test Harness for Diff Match and Patch
 *
 * Copyright 2011 Google Inc.
 * http://code.google.com/p/google-diff-match-patch/
 *
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

library test_harness;

// Can't import DiffMatchPatch library since the private functions would be
// unavailable.  Instead, import all the source files.
// TODO(adam): use mirrors to access private methods.
import 'dart:math';
import 'dart:convert';

import 'package:unittest/unittest.dart';

import 'package:diff_match_patch/DiffMatchPatch.dart';

List<String> _diff_rebuildtexts(diffs) {
  // Construct the two texts which made up the diff originally.
  final text1 = new StringBuffer();
  final text2 = new StringBuffer();
  for (int x = 0; x < diffs.length; x++) {
    if (diffs[x].operation != DIFF_INSERT) {
      text1.write(diffs[x].text);
    }
    if (diffs[x].operation != DIFF_DELETE) {
      text2.write(diffs[x].text);
    }
  }
  return [text1.toString(), text2.toString()];
}

DiffMatchPatch dmp;

// DIFF TEST FUNCTIONS


void testDiffCommonPrefix() {
  // Detect any common prefix.
  expect(0, dmp.diff_commonPrefix('abc', 'xyz'), reason: 'diff_commonPrefix: Null case.');

  expect(4, dmp.diff_commonPrefix('1234abcdef', '1234xyz'), reason: 'diff_commonPrefix: Non-null case.');

  expect(4, dmp.diff_commonPrefix('1234', '1234xyz'), reason: 'diff_commonPrefix: Whole case.');
}

void testDiffCommonSuffix() {
  // Detect any common suffix.
  expect(0, dmp.diff_commonSuffix('abc', 'xyz'), reason: 'diff_commonSuffix: Null case.');

  expect(4, dmp.diff_commonSuffix('abcdef1234', 'xyz1234'), reason: 'diff_commonSuffix: Non-null case.');

  expect(4, dmp.diff_commonSuffix('1234', 'xyz1234'), reason: 'diff_commonSuffix: Whole case.');
}

void testDiffCommonOverlap() {
  // Detect any suffix/prefix overlap.
  expect(0, dmp._diff_commonOverlap('', 'abcd'), reason: 'diff_commonOverlap: Null case.');

  expect(3, dmp._diff_commonOverlap('abc', 'abcd'), reason: 'diff_commonOverlap: Whole case.');

  expect(0, dmp._diff_commonOverlap('123456', 'abcd'), reason: 'diff_commonOverlap: No overlap.');

  expect(3, dmp._diff_commonOverlap('123456xxx', 'xxxabcd'), reason: 'diff_commonOverlap: Overlap.');

  // Some overly clever languages (C#) may treat ligatures as equal to their
  // component letters.  E.g. U+FB01 == 'fi'
  expect(0, dmp._diff_commonOverlap('fi', '\ufb01i'), reason: 'diff_commonOverlap: Unicode.');
}

void testDiffHalfmatch() {
  // Detect a halfmatch.
  dmp.Diff_Timeout = 1.0;
  Expect.isNull(dmp._diff_halfMatch('1234567890', 'abcdef'), 'diff_halfMatch: No match #1.');

  Expect.isNull(dmp._diff_halfMatch('12345', '23'), 'diff_halfMatch: No match #2.');

  Expect.listEquals(['12', '90', 'a', 'z', '345678'], dmp._diff_halfMatch('1234567890', 'a345678z'), 'diff_halfMatch: Single Match #1.');

  Expect.listEquals(['a', 'z', '12', '90', '345678'], dmp._diff_halfMatch('a345678z', '1234567890'), 'diff_halfMatch: Single Match #2.');

  Expect.listEquals(['abc', 'z', '1234', '0', '56789'], dmp._diff_halfMatch('abc56789z', '1234567890'), 'diff_halfMatch: Single Match #3.');

  Expect.listEquals(['a', 'xyz', '1', '7890', '23456'], dmp._diff_halfMatch('a23456xyz', '1234567890'), 'diff_halfMatch: Single Match #4.');

  Expect.listEquals(['12123', '123121', 'a', 'z', '1234123451234'], dmp._diff_halfMatch('121231234123451234123121', 'a1234123451234z'), 'diff_halfMatch: Multiple Matches #1.');

  Expect.listEquals(['', '-=-=-=-=-=', 'x', '', 'x-=-=-=-=-=-=-='], dmp._diff_halfMatch('x-=-=-=-=-=-=-=-=-=-=-=-=', 'xx-=-=-=-=-=-=-='), 'diff_halfMatch: Multiple Matches #2.');

  Expect.listEquals(['-=-=-=-=-=', '', '', 'y', '-=-=-=-=-=-=-=y'], dmp._diff_halfMatch('-=-=-=-=-=-=-=-=-=-=-=-=y', '-=-=-=-=-=-=-=yy'), 'diff_halfMatch: Multiple Matches #3.');

  // Optimal diff would be -q+x=H-i+e=lloHe+Hu=llo-Hew+y not -qHillo+x=HelloHe-w+Hulloy
  Expect.listEquals(['qHillo', 'w', 'x', 'Hulloy', 'HelloHe'], dmp._diff_halfMatch('qHilloHelloHew', 'xHelloHeHulloy'), 'diff_halfMatch: Non-optimal halfmatch.');

  dmp.Diff_Timeout = 0.0;
  Expect.isNull(dmp._diff_halfMatch('qHilloHelloHew', 'xHelloHeHulloy'), 'diff_halfMatch: Optimal no halfmatch.');
}

void testDiffLinesToChars() {
  void assertLinesToCharsResultEquals(Map<String, dynamic> a, Map<String, dynamic> b, String error_msg) {
    expect(a['chars1'], b['chars1'], reason: error_msg);
    expect(a['chars2'], b['chars2'], reason: error_msg);
    Expect.listEquals(a['lineArray'], b['lineArray'], error_msg);
  }

  // Convert lines down to characters.
  assertLinesToCharsResultEquals({'chars1': '\u0001\u0002\u0001', 'chars2': '\u0002\u0001\u0002', 'lineArray': ['', 'alpha\n', 'beta\n']}, dmp._diff_linesToChars('alpha\nbeta\nalpha\n', 'beta\nalpha\nbeta\n'), 'diff_linesToChars: Shared lines.');

  assertLinesToCharsResultEquals({'chars1': '', 'chars2': '\u0001\u0002\u0003\u0003', 'lineArray': ['', 'alpha\r\n', 'beta\r\n', '\r\n']}, dmp._diff_linesToChars('', 'alpha\r\nbeta\r\n\r\n\r\n'), 'diff_linesToChars: Empty string and blank lines.');

  assertLinesToCharsResultEquals({'chars1': '\u0001', 'chars2': '\u0002', 'lineArray': ['', 'a', 'b']}, dmp._diff_linesToChars('a', 'b'), 'diff_linesToChars: No linebreaks.');

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
  lineList.insertRange(0, 1, '');
  assertLinesToCharsResultEquals({'chars1': chars, 'chars2': '', 'lineArray': lineList}, dmp._diff_linesToChars(lines, ''), 'diff_linesToChars: More than 256.');
}

void testDiffCharsToLines() {
  // First check that Diff equality works.
  Expect.isTrue(new Diff(DIFF_EQUAL, 'a') == new Diff(DIFF_EQUAL, 'a'), 'diff_charsToLines: Equality #1.');

  expect(new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_EQUAL, 'a'), reason: 'diff_charsToLines: Equality #2.');

  // Convert chars up to lines.
  List<Diff> diffs = [new Diff(DIFF_EQUAL, '\u0001\u0002\u0001'), new Diff(DIFF_INSERT, '\u0002\u0001\u0002')];
  dmp._diff_charsToLines(diffs, ['', 'alpha\n', 'beta\n']);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'alpha\nbeta\nalpha\n'), new Diff(DIFF_INSERT, 'beta\nalpha\nbeta\n')], diffs, 'diff_charsToLines: Shared lines.');

  // More than 256 to reveal any 8-bit limitations.
  int n = 300;
  List<String> lineList = [];
  StringBuffer charList = new StringBuffer();
  for (int x = 1; x < n + 1; x++) {
    lineList.add('$x\n');
    charList.write(new String.fromCharCodes([x]));
  }
  expect(n, lineList.length);
  String lines = Strings.join(lineList, '');
  String chars = charList.toString();
  expect(n, chars.length);
  lineList.insertRange(0, 1, '');
  diffs = [new Diff(DIFF_DELETE, chars)];
  dmp._diff_charsToLines(diffs, lineList);
  Expect.listEquals([new Diff(DIFF_DELETE, lines)], diffs, 'diff_charsToLines: More than 256.');
}

void testDiffCleanupMerge() {
  // Cleanup a messy diff.
  List<Diff> diffs = [];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([], diffs, 'diff_cleanupMerge: Null case.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'b'), new Diff(DIFF_INSERT, 'c')];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'b'), new Diff(DIFF_INSERT, 'c')], diffs, 'diff_cleanupMerge: No change case.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_EQUAL, 'b'), new Diff(DIFF_EQUAL, 'c')];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'abc')], diffs, 'diff_cleanupMerge: Merge equalities.');

  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_DELETE, 'b'), new Diff(DIFF_DELETE, 'c')];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'abc')], diffs, 'diff_cleanupMerge: Merge deletions.');

  diffs = [new Diff(DIFF_INSERT, 'a'), new Diff(DIFF_INSERT, 'b'), new Diff(DIFF_INSERT, 'c')];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([new Diff(DIFF_INSERT, 'abc')], diffs, 'diff_cleanupMerge: Merge insertions.');

  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_INSERT, 'b'), new Diff(DIFF_DELETE, 'c'), new Diff(DIFF_INSERT, 'd'), new Diff(DIFF_EQUAL, 'e'), new Diff(DIFF_EQUAL, 'f')];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'ac'), new Diff(DIFF_INSERT, 'bd'), new Diff(DIFF_EQUAL, 'ef')], diffs, 'diff_cleanupMerge: Merge interweave.');

  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_INSERT, 'abc'), new Diff(DIFF_DELETE, 'dc')];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'd'), new Diff(DIFF_INSERT, 'b'), new Diff(DIFF_EQUAL, 'c')], diffs, 'diff_cleanupMerge: Prefix and suffix detection.');

  diffs = [new Diff(DIFF_EQUAL, 'x'), new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_INSERT, 'abc'), new Diff(DIFF_DELETE, 'dc'), new Diff(DIFF_EQUAL, 'y')];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'xa'), new Diff(DIFF_DELETE, 'd'), new Diff(DIFF_INSERT, 'b'), new Diff(DIFF_EQUAL, 'cy')], diffs, 'diff_cleanupMerge: Prefix and suffix detection with equalities.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_INSERT, 'ba'), new Diff(DIFF_EQUAL, 'c')];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([new Diff(DIFF_INSERT, 'ab'), new Diff(DIFF_EQUAL, 'ac')], diffs, 'diff_cleanupMerge: Slide edit left.');

  diffs = [new Diff(DIFF_EQUAL, 'c'), new Diff(DIFF_INSERT, 'ab'), new Diff(DIFF_EQUAL, 'a')];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'ca'), new Diff(DIFF_INSERT, 'ba')], diffs, 'diff_cleanupMerge: Slide edit right.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'b'), new Diff(DIFF_EQUAL, 'c'), new Diff(DIFF_DELETE, 'ac'), new Diff(DIFF_EQUAL, 'x')];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_EQUAL, 'acx')], diffs, 'diff_cleanupMerge: Slide edit left recursive.');

  diffs = [new Diff(DIFF_EQUAL, 'x'), new Diff(DIFF_DELETE, 'ca'), new Diff(DIFF_EQUAL, 'c'), new Diff(DIFF_DELETE, 'b'), new Diff(DIFF_EQUAL, 'a')];
  dmp.diff_cleanupMerge(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'xca'), new Diff(DIFF_DELETE, 'cba')], diffs, 'diff_cleanupMerge: Slide edit right recursive.');
}

void testDiffCleanupSemanticLossless() {
  // Slide diffs to match logical boundaries.
  List<Diff> diffs = [];
  dmp._diff_cleanupSemanticLossless(diffs);
  Expect.listEquals([], diffs, 'diff_cleanupSemanticLossless: Null case.');

  diffs = [new Diff(DIFF_EQUAL, 'AAA\r\n\r\nBBB'), new Diff(DIFF_INSERT, '\r\nDDD\r\n\r\nBBB'), new Diff(DIFF_EQUAL, '\r\nEEE')];
  dmp._diff_cleanupSemanticLossless(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'AAA\r\n\r\n'), new Diff(DIFF_INSERT, 'BBB\r\nDDD\r\n\r\n'), new Diff(DIFF_EQUAL, 'BBB\r\nEEE')], diffs, 'diff_cleanupSemanticLossless: Blank lines.');

  diffs = [new Diff(DIFF_EQUAL, 'AAA\r\nBBB'), new Diff(DIFF_INSERT, ' DDD\r\nBBB'), new Diff(DIFF_EQUAL, ' EEE')];
  dmp._diff_cleanupSemanticLossless(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'AAA\r\n'), new Diff(DIFF_INSERT, 'BBB DDD\r\n'), new Diff(DIFF_EQUAL, 'BBB EEE')], diffs, 'diff_cleanupSemanticLossless: Line boundaries.');

  diffs = [new Diff(DIFF_EQUAL, 'The c'), new Diff(DIFF_INSERT, 'ow and the c'), new Diff(DIFF_EQUAL, 'at.')];
  dmp._diff_cleanupSemanticLossless(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'The '), new Diff(DIFF_INSERT, 'cow and the '), new Diff(DIFF_EQUAL, 'cat.')], diffs, 'diff_cleanupSemanticLossless: Word boundaries.');

  diffs = [new Diff(DIFF_EQUAL, 'The-c'), new Diff(DIFF_INSERT, 'ow-and-the-c'), new Diff(DIFF_EQUAL, 'at.')];
  dmp._diff_cleanupSemanticLossless(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'The-'), new Diff(DIFF_INSERT, 'cow-and-the-'), new Diff(DIFF_EQUAL, 'cat.')], diffs, 'diff_cleanupSemanticLossless: Alphanumeric boundaries.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_EQUAL, 'ax')];
  dmp._diff_cleanupSemanticLossless(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_EQUAL, 'aax')], diffs, 'diff_cleanupSemanticLossless: Hitting the start.');

  diffs = [new Diff(DIFF_EQUAL, 'xa'), new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_EQUAL, 'a')];
  dmp._diff_cleanupSemanticLossless(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'xaa'), new Diff(DIFF_DELETE, 'a')], diffs, 'diff_cleanupSemanticLossless: Hitting the end.');

  diffs = [new Diff(DIFF_EQUAL, 'The xxx. The '), new Diff(DIFF_INSERT, 'zzz. The '), new Diff(DIFF_EQUAL, 'yyy.')];
  dmp._diff_cleanupSemanticLossless(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'The xxx.'), new Diff(DIFF_INSERT, ' The zzz.'), new Diff(DIFF_EQUAL, ' The yyy.')], diffs, 'diff_cleanupSemanticLossless: Sentence boundaries.');
}

void testDiffCleanupSemantic() {
  // Cleanup semantically trivial equalities.
  List<Diff> diffs = [];
  dmp.diff_cleanupSemantic(diffs);
  Expect.listEquals([], diffs, 'diff_cleanupSemantic: Null case.');

  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, 'cd'), new Diff(DIFF_EQUAL, '12'), new Diff(DIFF_DELETE, 'e')];
  dmp.diff_cleanupSemantic(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, 'cd'), new Diff(DIFF_EQUAL, '12'), new Diff(DIFF_DELETE, 'e')], diffs, 'diff_cleanupSemantic: No elimination #1.');

  diffs = [new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_INSERT, 'ABC'), new Diff(DIFF_EQUAL, '1234'), new Diff(DIFF_DELETE, 'wxyz')];
  dmp.diff_cleanupSemantic(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_INSERT, 'ABC'), new Diff(DIFF_EQUAL, '1234'), new Diff(DIFF_DELETE, 'wxyz')], diffs, 'diff_cleanupSemantic: No elimination #2.');

  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_EQUAL, 'b'), new Diff(DIFF_DELETE, 'c')];
  dmp.diff_cleanupSemantic(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_INSERT, 'b')], diffs, 'diff_cleanupSemantic: Simple elimination.');

  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_EQUAL, 'cd'), new Diff(DIFF_DELETE, 'e'), new Diff(DIFF_EQUAL, 'f'), new Diff(DIFF_INSERT, 'g')];
  dmp.diff_cleanupSemantic(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'abcdef'), new Diff(DIFF_INSERT, 'cdfg')], diffs, 'diff_cleanupSemantic: Backpass elimination.');

  diffs = [new Diff(DIFF_INSERT, '1'), new Diff(DIFF_EQUAL, 'A'), new Diff(DIFF_DELETE, 'B'), new Diff(DIFF_INSERT, '2'), new Diff(DIFF_EQUAL, '_'), new Diff(DIFF_INSERT, '1'), new Diff(DIFF_EQUAL, 'A'), new Diff(DIFF_DELETE, 'B'), new Diff(DIFF_INSERT, '2')];
  dmp.diff_cleanupSemantic(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'AB_AB'), new Diff(DIFF_INSERT, '1A2_1A2')], diffs, 'diff_cleanupSemantic: Multiple elimination.');

  diffs = [new Diff(DIFF_EQUAL, 'The c'), new Diff(DIFF_DELETE, 'ow and the c'), new Diff(DIFF_EQUAL, 'at.')];
  dmp.diff_cleanupSemantic(diffs);
  Expect.listEquals([new Diff(DIFF_EQUAL, 'The '), new Diff(DIFF_DELETE, 'cow and the '), new Diff(DIFF_EQUAL, 'cat.')], diffs, 'diff_cleanupSemantic: Word boundaries.');

  diffs = [new Diff(DIFF_DELETE, 'abcxx'), new Diff(DIFF_INSERT, 'xxdef')];
  dmp.diff_cleanupSemantic(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'abcxx'), new Diff(DIFF_INSERT, 'xxdef')], diffs, 'diff_cleanupSemantic: No overlap elimination.');

  diffs = [new Diff(DIFF_DELETE, 'abcxxx'), new Diff(DIFF_INSERT, 'xxxdef')];
  dmp.diff_cleanupSemantic(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'abc'), new Diff(DIFF_EQUAL, 'xxx'), new Diff(DIFF_INSERT, 'def')], diffs, 'diff_cleanupSemantic: Overlap elimination.');

  diffs = [new Diff(DIFF_DELETE, 'xxxabc'), new Diff(DIFF_INSERT, 'defxxx')];
  dmp.diff_cleanupSemantic(diffs);
  Expect.listEquals([new Diff(DIFF_INSERT, 'def'), new Diff(DIFF_EQUAL, 'xxx'), new Diff(DIFF_DELETE, 'abc')], diffs, 'diff_cleanupSemantic: Reverse overlap elimination.');

  diffs = [new Diff(DIFF_DELETE, 'abcd1212'), new Diff(DIFF_INSERT, '1212efghi'), new Diff(DIFF_EQUAL, '----'), new Diff(DIFF_DELETE, 'A3'), new Diff(DIFF_INSERT, '3BC')];
  dmp.diff_cleanupSemantic(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'abcd'), new Diff(DIFF_EQUAL, '1212'), new Diff(DIFF_INSERT, 'efghi'), new Diff(DIFF_EQUAL, '----'), new Diff(DIFF_DELETE, 'A'), new Diff(DIFF_EQUAL, '3'), new Diff(DIFF_INSERT, 'BC')], diffs, 'diff_cleanupSemantic: Two overlap eliminations.');
}

void testDiffCleanupEfficiency() {
  // Cleanup operationally trivial equalities.
  dmp.Diff_EditCost = 4;
  List<Diff> diffs = [];
  dmp.diff_cleanupEfficiency(diffs);
  Expect.listEquals([], diffs, 'diff_cleanupEfficiency: Null case.');

  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'wxyz'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '34')];
  dmp.diff_cleanupEfficiency(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'wxyz'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '34')], diffs, 'diff_cleanupEfficiency: No elimination.');

  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'xyz'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '34')];
  dmp.diff_cleanupEfficiency(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'abxyzcd'), new Diff(DIFF_INSERT, '12xyz34')], diffs, 'diff_cleanupEfficiency: Four-edit elimination.');

  diffs = [new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'x'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '34')];
  dmp.diff_cleanupEfficiency(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'xcd'), new Diff(DIFF_INSERT, '12x34')], diffs, 'diff_cleanupEfficiency: Three-edit elimination.');

  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'xy'), new Diff(DIFF_INSERT, '34'), new Diff(DIFF_EQUAL, 'z'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '56')];
  dmp.diff_cleanupEfficiency(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'abxyzcd'), new Diff(DIFF_INSERT, '12xy34z56')], diffs, 'diff_cleanupEfficiency: Backpass elimination.');

  dmp.Diff_EditCost = 5;
  diffs = [new Diff(DIFF_DELETE, 'ab'), new Diff(DIFF_INSERT, '12'), new Diff(DIFF_EQUAL, 'wxyz'), new Diff(DIFF_DELETE, 'cd'), new Diff(DIFF_INSERT, '34')];
  dmp.diff_cleanupEfficiency(diffs);
  Expect.listEquals([new Diff(DIFF_DELETE, 'abwxyzcd'), new Diff(DIFF_INSERT, '12wxyz34')], diffs, 'diff_cleanupEfficiency: High cost elimination.');
  dmp.Diff_EditCost = 4;
}

void testDiffPrettyHtml() {
  // Pretty print.
  List<Diff> diffs = [new Diff(DIFF_EQUAL, 'a\n'), new Diff(DIFF_DELETE, '<B>b</B>'), new Diff(DIFF_INSERT, 'c&d')];
  expect('<span>a&para;<br></span><del style="background:#ffe6e6;">&lt;B&gt;b&lt;/B&gt;</del><ins style="background:#e6ffe6;">c&amp;d</ins>', dmp.diff_prettyHtml(diffs), 'diff_prettyHtml:');
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
  Expect.listEquals(diffs, dmp.diff_fromDelta(text1, delta), 'diff_fromDelta: Normal.');

  // Generates error (19 < 20).
  Expect.throws(() => dmp.diff_fromDelta('${text1}x', delta), null, 'diff_fromDelta: Too long.');

  // Generates error (19 > 18).
  Expect.throws(() => dmp.diff_fromDelta(text1.substring(1), delta), null, 'diff_fromDelta: Too short.');

  // Generates error (%c3%xy invalid Unicode).
  Expect.throws(() => dmp.diff_fromDelta('', '+%c3%xy'), null, 'diff_fromDelta: Invalid character.');

  // Test deltas with special characters.
  diffs = [new Diff(DIFF_EQUAL, '\u0680 \x00 \t %'), new Diff(DIFF_DELETE, '\u0681 \x01 \n ^'), new Diff(DIFF_INSERT, '\u0682 \x02 \\ |')];
  text1 = dmp.diff_text1(diffs);
  expect('\u0680 \x00 \t %\u0681 \x01 \n ^', text1, reason: 'diff_text1: Unicode text.');

  delta = dmp.diff_toDelta(diffs);
  expect('=7\t-7\t+%DA%82 %02 %5C %7C', delta, reason: 'diff_toDelta: Unicode.');

  Expect.listEquals(diffs, dmp.diff_fromDelta(text1, delta), 'diff_fromDelta: Unicode.');

  // Verify pool of unchanged characters.
  diffs = [new Diff(DIFF_INSERT, 'A-Z a-z 0-9 - _ . ! ~ * \' ( ) ; / ? : @ & = + \$ , # ')];
  String text2 = dmp.diff_text2(diffs);
  expect('A-Z a-z 0-9 - _ . ! ~ * \' ( ) ; / ? : @ & = + \$ , # ', text2, reason: 'diff_text2: Unchanged characters.');

  delta = dmp.diff_toDelta(diffs);
  expect('+A-Z a-z 0-9 - _ . ! ~ * \' ( ) ; / ? : @ & = + \$ , # ', delta, reason: 'diff_toDelta: Unchanged characters.');

  // Convert delta string into a diff.
  Expect.listEquals(diffs, dmp.diff_fromDelta('', delta), 'diff_fromDelta: Unchanged characters.');
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
  Expect.listEquals(diffs, dmp._diff_bisect(a, b, deadline), 'diff_bisect: Normal.');

  // Timeout.
  diffs = [new Diff(DIFF_DELETE, 'cat'), new Diff(DIFF_INSERT, 'map')];
  // Set deadline to one year ago.
  deadline = new Date.now().subtract(new Duration(days : 365));
  Expect.listEquals(diffs, dmp._diff_bisect(a, b, deadline), 'diff_bisect: Timeout.');
}

void testDiffMain() {
  // Perform a trivial diff.
  List<Diff> diffs = [];
  Expect.listEquals(diffs, dmp.diff_main('', '', false), 'diff_main: Null case.');

  diffs = [new Diff(DIFF_EQUAL, 'abc')];
  Expect.listEquals(diffs, dmp.diff_main('abc', 'abc', false), 'diff_main: Equality.');

  diffs = [new Diff(DIFF_EQUAL, 'ab'), new Diff(DIFF_INSERT, '123'), new Diff(DIFF_EQUAL, 'c')];
  Expect.listEquals(diffs, dmp.diff_main('abc', 'ab123c', false), 'diff_main: Simple insertion.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, '123'), new Diff(DIFF_EQUAL, 'bc')];
  Expect.listEquals(diffs, dmp.diff_main('a123bc', 'abc', false), 'diff_main: Simple deletion.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_INSERT, '123'), new Diff(DIFF_EQUAL, 'b'), new Diff(DIFF_INSERT, '456'), new Diff(DIFF_EQUAL, 'c')];
  Expect.listEquals(diffs, dmp.diff_main('abc', 'a123b456c', false), 'diff_main: Two insertions.');

  diffs = [new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, '123'), new Diff(DIFF_EQUAL, 'b'), new Diff(DIFF_DELETE, '456'), new Diff(DIFF_EQUAL, 'c')];
  Expect.listEquals(diffs, dmp.diff_main('a123b456c', 'abc', false), 'diff_main: Two deletions.');

  // Perform a real diff.
  // Switch off the timeout.
  dmp.Diff_Timeout = 0.0;
  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_INSERT, 'b')];
  Expect.listEquals(diffs, dmp.diff_main('a', 'b', false), 'diff_main: Simple case #1.');

  diffs = [new Diff(DIFF_DELETE, 'Apple'), new Diff(DIFF_INSERT, 'Banana'), new Diff(DIFF_EQUAL, 's are a'), new Diff(DIFF_INSERT, 'lso'), new Diff(DIFF_EQUAL, ' fruit.')];
  Expect.listEquals(diffs, dmp.diff_main('Apples are a fruit.', 'Bananas are also fruit.', false), 'diff_main: Simple case #2.');

  diffs = [new Diff(DIFF_DELETE, 'a'), new Diff(DIFF_INSERT, '\u0680'), new Diff(DIFF_EQUAL, 'x'), new Diff(DIFF_DELETE, '\t'), new Diff(DIFF_INSERT, '\000')];
  Expect.listEquals(diffs, dmp.diff_main('ax\t', '\u0680x\000', false), 'diff_main: Simple case #3.');

  diffs = [new Diff(DIFF_DELETE, '1'), new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, 'y'), new Diff(DIFF_EQUAL, 'b'), new Diff(DIFF_DELETE, '2'), new Diff(DIFF_INSERT, 'xab')];
  Expect.listEquals(diffs, dmp.diff_main('1ayb2', 'abxab', false), 'diff_main: Overlap #1.');

  diffs = [new Diff(DIFF_INSERT, 'xaxcx'), new Diff(DIFF_EQUAL, 'abc'), new Diff(DIFF_DELETE, 'y')];
  Expect.listEquals(diffs, dmp.diff_main('abcy', 'xaxcxabc', false), 'diff_main: Overlap #2.');

  diffs = [new Diff(DIFF_DELETE, 'ABCD'), new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_DELETE, '='), new Diff(DIFF_INSERT, '-'), new Diff(DIFF_EQUAL, 'bcd'), new Diff(DIFF_DELETE, '='), new Diff(DIFF_INSERT, '-'), new Diff(DIFF_EQUAL, 'efghijklmnopqrs'), new Diff(DIFF_DELETE, 'EFGHIJKLMNOefg')];
  Expect.listEquals(diffs, dmp.diff_main('ABCDa=bcd=efghijklmnopqrsEFGHIJKLMNOefg', 'a-bcd-efghijklmnopqrs', false), 'diff_main: Overlap #3.');

  diffs = [new Diff(DIFF_INSERT, ' '), new Diff(DIFF_EQUAL, 'a'), new Diff(DIFF_INSERT, 'nd'), new Diff(DIFF_EQUAL, ' [[Pennsylvania]]'), new Diff(DIFF_DELETE, ' and [[New')];
  Expect.listEquals(diffs, dmp.diff_main('a [[Pennsylvania]] and [[New', ' and [[Pennsylvania]]', false), 'diff_main: Large equality.');

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
  Expect.isTrue(dmp.Diff_Timeout <= elapsedSeconds, 'diff_main: Timeout min.');
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
  Expect.listEquals(dmp.diff_main(a, b, true), dmp.diff_main(a, b, false), 'diff_main: Simple line-mode.');

  a = '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
  b = 'abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij';
  Expect.listEquals(dmp.diff_main(a, b, true), dmp.diff_main(a, b, false), 'diff_main: Single line-mode.');

  a = '1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n';
  b = 'abcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n';
  List<String> texts_linemode = _diff_rebuildtexts(dmp.diff_main(a, b, true));
  List<String> texts_textmode = _diff_rebuildtexts(dmp.diff_main(a, b, false));
  Expect.listEquals(texts_textmode, texts_linemode, 'diff_main: Overlap line-mode.');

  // Test null inputs.
  Expect.throws(() => dmp.diff_main(null, null), null, 'diff_main: Null inputs.');
}


//  MATCH TEST FUNCTIONS

void testMatchAlphabet() {
  void assertMapEquals(Map a, Map b, String error_msg) {
    Expect.setEquals(a.keys, b.keys, error_msg);
    for (var x in a.keys) {
      expect(a[x], b[x], reason: "$error_msg [Key: $x]");
    }
  }

  // Initialise the bitmasks for Bitap.
  Map<String, int> bitmask = {'a': 4, 'b': 2, 'c': 1};
  assertMapEquals(bitmask, dmp._match_alphabet('abc'), 'match_alphabet: Unique.');

  bitmask = {'a': 37, 'b': 18, 'c': 8};
  assertMapEquals(bitmask, dmp._match_alphabet('abcaba'), 'match_alphabet: Duplicates.');
}

void testMatchBitap() {
  // Bitap algorithm.
  dmp.Match_Distance = 100;
  dmp.Match_Threshold = 0.5;
  expect(5, dmp._match_bitap('abcdefghijk', 'fgh', 5), reason: 'match_bitap: Exact match #1.');

  expect(5, dmp._match_bitap('abcdefghijk', 'fgh', 0), reason: 'match_bitap: Exact match #2.');

  expect(4, dmp._match_bitap('abcdefghijk', 'efxhi', 0), reason: 'match_bitap: Fuzzy match #1.');

  expect(2, dmp._match_bitap('abcdefghijk', 'cdefxyhijk', 5), reason: 'match_bitap: Fuzzy match #2.');

  expect(-1, dmp._match_bitap('abcdefghijk', 'bxy', 1), reason: 'match_bitap: Fuzzy match #3.');

  expect(2, dmp._match_bitap('123456789xx0', '3456789x0', 2), reason: 'match_bitap: Overflow.');

  expect(0, dmp._match_bitap('abcdef', 'xxabc', 4), reason: 'match_bitap: Before start match.');

  expect(3, dmp._match_bitap('abcdef', 'defyy', 4), reason: 'match_bitap: Beyond end match.');

  expect(0, dmp._match_bitap('abcdef', 'xabcdefy', 0), reason: 'match_bitap: Oversized pattern.');

  dmp.Match_Threshold = 0.4;
  expect(4, dmp._match_bitap('abcdefghijk', 'efxyhi', 1), reason: 'match_bitap: Threshold #1.');

  dmp.Match_Threshold = 0.3;
  expect(-1, dmp._match_bitap('abcdefghijk', 'efxyhi', 1), reason: 'match_bitap: Threshold #2.');

  dmp.Match_Threshold = 0.0;
  expect(1, dmp._match_bitap('abcdefghijk', 'bcdef', 1), reason: 'match_bitap: Threshold #3.');

  dmp.Match_Threshold = 0.5;
  expect(0, dmp._match_bitap('abcdexyzabcde', 'abccde', 3), reason: 'match_bitap: Multiple select #1.');

  expect(8, dmp._match_bitap('abcdexyzabcde', 'abccde', 5), reason: 'match_bitap: Multiple select #2.');

  dmp.Match_Distance = 10;  // Strict location.
  expect(-1, dmp._match_bitap('abcdefghijklmnopqrstuvwxyz', 'abcdefg', 24), reason: 'match_bitap: Distance test #1.');

  expect(0, dmp._match_bitap('abcdefghijklmnopqrstuvwxyz', 'abcdxxefg', 1), reason: 'match_bitap: Distance test #2.');

  dmp.Match_Distance = 1000;  // Loose location.
  expect(0, dmp._match_bitap('abcdefghijklmnopqrstuvwxyz', 'abcdefg', 24), reason: 'match_bitap: Distance test #3.');
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
  Expect.throws(() => dmp.match_main(null, null, 0), null, 'match_main: Null inputs.');
}


//  PATCH TEST FUNCTIONS


void testPatchObj() {
  // Patch Object.
  Patch p = new Patch();
  p.start1 = 20;
  p.start2 = 21;
  p.length1 = 18;
  p.length2 = 17;
  p.diffs = [new Diff(DIFF_EQUAL, 'jump'), new Diff(DIFF_DELETE, 's'), new Diff(DIFF_INSERT, 'ed'), new Diff(DIFF_EQUAL, ' over '), new Diff(DIFF_DELETE, 'the'), new Diff(DIFF_INSERT, 'a'), new Diff(DIFF_EQUAL, '\nlaz')];
  String strp = '@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n %0Alaz\n';
  expect(strp, p.toString(), reason: 'Patch: toString.');
}

void testPatchFromText() {
  Expect.isTrue(dmp.patch_fromText('').isEmpty, 'patch_fromText: #0.');

  String strp = '@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n %0Alaz\n';
  expect(strp, dmp.patch_fromText(strp)[0].toString(), reason: 'patch_fromText: #1.');

  expect('@@ -1 +1 @@\n-a\n+b\n', dmp.patch_fromText('@@ -1 +1 @@\n-a\n+b\n')[0].toString(), reason: 'patch_fromText: #2.');

  expect('@@ -1,3 +0,0 @@\n-abc\n', dmp.patch_fromText('@@ -1,3 +0,0 @@\n-abc\n')[0].toString(), reason: 'patch_fromText: #3.');

  expect('@@ -0,0 +1,3 @@\n+abc\n', dmp.patch_fromText('@@ -0,0 +1,3 @@\n+abc\n')[0].toString(), reason: 'patch_fromText: #4.');

  // Generates error.
  Expect.throws(() => dmp.patch_fromText('Bad\nPatch\n'), null, 'patch_fromText: #5.');
}

void testPatchToText() {
  String strp = '@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n  laz\n';
  List<Patch> patches;
  patches = dmp.patch_fromText(strp);
  expect(strp, dmp.patch_toText(patches), reason: 'patch_toText: Single.');

  strp = '@@ -1,9 +1,9 @@\n-f\n+F\n oo+fooba\n@@ -7,9 +7,9 @@\n obar\n-,\n+.\n  tes\n';
  patches = dmp.patch_fromText(strp);
  expect(strp, dmp.patch_toText(patches), reason: 'patch_toText: Dual.');
}

void testPatchAddContext() {
  dmp.Patch_Margin = 4;
  Patch p;
  p = dmp.patch_fromText('@@ -21,4 +21,10 @@\n-jump\n+somersault\n')[0];
  dmp._patch_addContext(p, 'The quick brown fox jumps over the lazy dog.');
  expect('@@ -17,12 +17,18 @@\n fox \n-jump\n+somersault\n s ov\n', p.toString(), reason: 'patch_addContext: Simple case.');

  p = dmp.patch_fromText('@@ -21,4 +21,10 @@\n-jump\n+somersault\n')[0];
  dmp._patch_addContext(p, 'The quick brown fox jumps.');
  expect('@@ -17,10 +17,16 @@\n fox \n-jump\n+somersault\n s.\n', p.toString(), reason: 'patch_addContext: Not enough trailing context.');

  p = dmp.patch_fromText('@@ -3 +3,2 @@\n-e\n+at\n')[0];
  dmp._patch_addContext(p, 'The quick brown fox jumps.');
  expect('@@ -1,7 +1,8 @@\n Th\n-e\n+at\n  qui\n', p.toString(), reason: 'patch_addContext: Not enough leading context.');

  p = dmp.patch_fromText('@@ -3 +3,2 @@\n-e\n+at\n')[0];
  dmp._patch_addContext(p, 'The quick brown fox jumps.  The quick brown fox crashes.');
  expect('@@ -1,27 +1,28 @@\n Th\n-e\n+at\n  quick brown fox jumps. \n', p.toString(), reason: 'patch_addContext: Ambiguity.');
}

void testPatchMake() {
  List<Patch> patches;
  patches = dmp.patch_make('', '');
  expect('', dmp.patch_toText(patches), reason: 'patch_make: Null case.');

  String text1 = 'The quick brown fox jumps over the lazy dog.';
  String text2 = 'That quick brown fox jumped over a lazy dog.';
  String expectedPatch = '@@ -1,8 +1,7 @@\n Th\n-at\n+e\n  qui\n@@ -21,17 +21,18 @@\n jump\n-ed\n+s\n  over \n-a\n+the\n  laz\n';
  // The second patch must be '-21,17 +21,18', not '-22,17 +21,18' due to rolling context.
  patches = dmp.patch_make(text2, text1);
  expect(expectedPatch, dmp.patch_toText(patches), reason: 'patch_make: Text2+Text1 inputs.');

  expectedPatch = '@@ -1,11 +1,12 @@\n Th\n-e\n+at\n  quick b\n@@ -22,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n  laz\n';
  patches = dmp.patch_make(text1, text2);
  expect(expectedPatch, dmp.patch_toText(patches), reason: 'patch_make: Text1+Text2 inputs.');

  List<Diff> diffs = dmp.diff_main(text1, text2, false);
  patches = dmp.patch_make(diffs);
  expect(expectedPatch, dmp.patch_toText(patches), reason: 'patch_make: Diff input.');

  patches = dmp.patch_make(text1, diffs);
  expect(expectedPatch, dmp.patch_toText(patches), reason: 'patch_make: Text1+Diff inputs.');

  patches = dmp.patch_make(text1, text2, diffs);
  expect(expectedPatch, dmp.patch_toText(patches), reason: 'patch_make: Text1+Text2+Diff inputs (deprecated).');

  patches = dmp.patch_make('`1234567890-=[]\\;\',./', '~!@#\$%^&*()_+{}|:"<>?');
  expect('@@ -1,21 +1,21 @@\n-%601234567890-=%5B%5D%5C;\',./\n+~!@#\$%25%5E&*()_+%7B%7D%7C:%22%3C%3E?\n', dmp.patch_toText(patches), reason: 'patch_toText: Character encoding.');

  diffs = [new Diff(DIFF_DELETE, '`1234567890-=[]\\;\',./'), new Diff(DIFF_INSERT, '~!@#\$%^&*()_+{}|:"<>?')];
  Expect.listEquals(diffs, dmp.patch_fromText('@@ -1,21 +1,21 @@\n-%601234567890-=%5B%5D%5C;\',./\n+~!@#\$%25%5E&*()_+%7B%7D%7C:%22%3C%3E?\n')[0].diffs, 'patch_fromText: Character decoding.');

  final sb = new StringBuffer();
  for (int x = 0; x < 100; x++) {
    sb.add('abcdef');
  }
  text1 = sb.toString();
  text2 = '${text1}123';
  expectedPatch = '@@ -573,28 +573,31 @@\n cdefabcdefabcdefabcdefabcdef\n+123\n';
  patches = dmp.patch_make(text1, text2);
  expect(expectedPatch, dmp.patch_toText(patches), reason: 'patch_make: Long string with repeats.');

  // Test null inputs.
  Expect.throws(() => dmp.patch_make(null), null, 'patch_make: Null inputs.');
}

void testPatchSplitMax() {
  // Assumes that Match_MaxBits is 32.
  List<Patch> patches;
  patches = dmp.patch_make('abcdefghijklmnopqrstuvwxyz01234567890', 'XabXcdXefXghXijXklXmnXopXqrXstXuvXwxXyzX01X23X45X67X89X0');
  dmp.patch_splitMax(patches);
  expect('@@ -1,32 +1,46 @@\n+X\n ab\n+X\n cd\n+X\n ef\n+X\n gh\n+X\n ij\n+X\n kl\n+X\n mn\n+X\n op\n+X\n qr\n+X\n st\n+X\n uv\n+X\n wx\n+X\n yz\n+X\n 012345\n@@ -25,13 +39,18 @@\n zX01\n+X\n 23\n+X\n 45\n+X\n 67\n+X\n 89\n+X\n 0\n', dmp.patch_toText(patches), reason: 'patch_splitMax: #1.');

  patches = dmp.patch_make('abcdef1234567890123456789012345678901234567890123456789012345678901234567890uvwxyz', 'abcdefuvwxyz');
  String oldToText = dmp.patch_toText(patches);
  dmp.patch_splitMax(patches);
  expect(oldToText, dmp.patch_toText(patches), reason: 'patch_splitMax: #2.');

  patches = dmp.patch_make('1234567890123456789012345678901234567890123456789012345678901234567890', 'abc');
  dmp.patch_splitMax(patches);
  expect('@@ -1,32 +1,4 @@\n-1234567890123456789012345678\n 9012\n@@ -29,32 +1,4 @@\n-9012345678901234567890123456\n 7890\n@@ -57,14 +1,3 @@\n-78901234567890\n+abc\n', dmp.patch_toText(patches), reason: 'patch_splitMax: #3.');

  patches = dmp.patch_make('abcdefghij , h : 0 , t : 1 abcdefghij , h : 0 , t : 1 abcdefghij , h : 0 , t : 1', 'abcdefghij , h : 1 , t : 1 abcdefghij , h : 1 , t : 1 abcdefghij , h : 0 , t : 1');
  dmp.patch_splitMax(patches);
  expect('@@ -2,32 +2,32 @@\n bcdefghij , h : \n-0\n+1\n  , t : 1 abcdef\n@@ -29,32 +29,32 @@\n bcdefghij , h : \n-0\n+1\n  , t : 1 abcdef\n', dmp.patch_toText(patches), reason: 'patch_splitMax: #4.');
}

void testPatchAddPadding() {
  List<Patch> patches;
  patches = dmp.patch_make('', 'test');
  expect('@@ -0,0 +1,4 @@\n+test\n', dmp.patch_toText(patches), reason: 'patch_addPadding: Both edges full.');
  dmp.patch_addPadding(patches);
  expect('@@ -1,8 +1,12 @@\n %01%02%03%04\n+test\n %01%02%03%04\n', dmp.patch_toText(patches), reason: 'patch_addPadding: Both edges full.');

  patches = dmp.patch_make('XY', 'XtestY');
  expect('@@ -1,2 +1,6 @@\n X\n+test\n Y\n', dmp.patch_toText(patches), reason: 'patch_addPadding: Both edges partial.');
  dmp.patch_addPadding(patches);
  expect('@@ -2,8 +2,12 @@\n %02%03%04X\n+test\n Y%01%02%03\n', dmp.patch_toText(patches), reason: 'patch_addPadding: Both edges partial.');

  patches = dmp.patch_make('XXXXYYYY', 'XXXXtestYYYY');
  expect('@@ -1,8 +1,12 @@\n XXXX\n+test\n YYYY\n', dmp.patch_toText(patches), reason: 'patch_addPadding: Both edges none.');
  dmp.patch_addPadding(patches);
  expect('@@ -5,8 +5,12 @@\n XXXX\n+test\n YYYY\n', dmp.patch_toText(patches), reason: 'patch_addPadding: Both edges none.');
}

void testPatchApply() {
  dmp.Match_Distance = 1000;
  dmp.Match_Threshold = 0.5;
  dmp.Patch_DeleteThreshold = 0.5;
  List<Patch> patches;
  patches = dmp.patch_make('', '');
  List results = dmp.patch_apply(patches, 'Hello world.');
  List boolArray = results[1];
  String resultStr = '${results[0]}\t${boolArray.length}';
  expect('Hello world.\t0', resultStr, reason: 'patch_apply: Null case.');

  patches = dmp.patch_make('The quick brown fox jumps over the lazy dog.', 'That quick brown fox jumped over a lazy dog.');
  results = dmp.patch_apply(patches, 'The quick brown fox jumps over the lazy dog.');
  boolArray = results[1];
  resultStr = '${results[0]}\t${boolArray[0]}\t${boolArray[1]}';
  expect('That quick brown fox jumped over a lazy dog.\ttrue\ttrue', resultStr, reason: 'patch_apply: Exact match.');

  results = dmp.patch_apply(patches, 'The quick red rabbit jumps over the tired tiger.');
  boolArray = results[1];
  resultStr = '${results[0]}\t${boolArray[0]}\t${boolArray[1]}';
  expect('That quick red rabbit jumped over a tired tiger.\ttrue\ttrue', resultStr, reason: 'patch_apply: Partial match.');

  results = dmp.patch_apply(patches, 'I am the very model of a modern major general.');
  boolArray = results[1];
  resultStr = '${results[0]}\t${boolArray[0]}\t${boolArray[1]}';
  expect('I am the very model of a modern major general.\tfalse\tfalse', resultStr, reason: 'patch_apply: Failed match.');

  patches = dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy');
  results = dmp.patch_apply(patches, 'x123456789012345678901234567890-----++++++++++-----123456789012345678901234567890y');
  boolArray = results[1];
  resultStr = '${results[0]}\t${boolArray[0]}\t${boolArray[1]}';
  expect('xabcy\ttrue\ttrue', resultStr, reason: 'patch_apply: Big delete, small change.');

  patches = dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy');
  results = dmp.patch_apply(patches, 'x12345678901234567890---------------++++++++++---------------12345678901234567890y');
  boolArray = results[1];
  resultStr = '${results[0]}\t${boolArray[0]}\t${boolArray[1]}';
  expect('xabc12345678901234567890---------------++++++++++---------------12345678901234567890y\tfalse\ttrue', resultStr, reason: 'patch_apply: Big delete, big change 1.');

  dmp.Patch_DeleteThreshold = 0.6;
  patches = dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy');
  results = dmp.patch_apply(patches, 'x12345678901234567890---------------++++++++++---------------12345678901234567890y');
  boolArray = results[1];
  resultStr = '${results[0]}\t${boolArray[0]}\t${boolArray[1]}';
  expect('xabcy\ttrue\ttrue', resultStr, reason: 'patch_apply: Big delete, big change 2.');
  dmp.Patch_DeleteThreshold = 0.5;

  // Compensate for failed patch.
  dmp.Match_Threshold = 0.0;
  dmp.Match_Distance = 0;
  patches = dmp.patch_make('abcdefghijklmnopqrstuvwxyz--------------------1234567890', 'abcXXXXXXXXXXdefghijklmnopqrstuvwxyz--------------------1234567YYYYYYYYYY890');
  results = dmp.patch_apply(patches, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ--------------------1234567890');
  boolArray = results[1];
  resultStr = '${results[0]}\t${boolArray[0]}\t${boolArray[1]}';
  expect('ABCDEFGHIJKLMNOPQRSTUVWXYZ--------------------1234567YYYYYYYYYY890\tfalse\ttrue', resultStr, reason: 'patch_apply: Compensate for failed patch.');
  dmp.Match_Threshold = 0.5;
  dmp.Match_Distance = 1000;

  patches = dmp.patch_make('', 'test');
  String patchStr = dmp.patch_toText(patches);
  dmp.patch_apply(patches, '');
  expect(patchStr, dmp.patch_toText(patches), reason: 'patch_apply: No side effects.');

  patches = dmp.patch_make('The quick brown fox jumps over the lazy dog.', 'Woof');
  patchStr = dmp.patch_toText(patches);
  dmp.patch_apply(patches, 'The quick brown fox jumps over the lazy dog.');
  expect(patchStr, dmp.patch_toText(patches), reason: 'patch_apply: No side effects with major delete.');

  patches = dmp.patch_make('', 'test');
  results = dmp.patch_apply(patches, '');
  boolArray = results[1];
  resultStr = '${results[0]}\t${boolArray[0]}';
  expect('test\ttrue', resultStr, reason: 'patch_apply: Edge exact match.');

  patches = dmp.patch_make('XY', 'XtestY');
  results = dmp.patch_apply(patches, 'XY');
  boolArray = results[1];
  resultStr = '${results[0]}\t${boolArray[0]}';
  expect('XtestY\ttrue', resultStr, reason: 'patch_apply: Near edge exact match.');

  patches = dmp.patch_make('y', 'y123');
  results = dmp.patch_apply(patches, 'x');
  boolArray = results[1];
  resultStr = '${results[0]}\t${boolArray[0]}';
  expect('x123\ttrue', resultStr, reason: 'patch_apply: Edge partial match.');
}

// Run each test.
// TODO: Use the Dart unit test framework (once it is published).
main() {
  dmp = new DiffMatchPatch();

  testDiffCommonPrefix();
  testDiffCommonSuffix();
  testDiffCommonOverlap();
  testDiffHalfmatch();
  testDiffLinesToChars();
  testDiffCharsToLines();
  testDiffCleanupMerge();
  testDiffCleanupSemanticLossless();
  testDiffCleanupSemantic();
  testDiffCleanupEfficiency();
  testDiffPrettyHtml();
  testDiffText();
  testDiffDelta();
  testDiffXIndex();
  testDiffLevenshtein();
  testDiffBisect();
  testDiffMain();

  testMatchAlphabet();
  testMatchBitap();
  testMatchMain();

  testPatchObj();
  testPatchFromText();
  testPatchToText();
  testPatchAddContext();
  testPatchMake();
  testPatchSplitMax();
  testPatchAddPadding();
  testPatchApply();

  print('All tests passed.');
}
