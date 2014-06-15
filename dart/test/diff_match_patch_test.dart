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

library diff_match_patch_test_harness;

import 'dart:mirrors';

import 'package:collection/equality.dart';
import 'package:unittest/unittest.dart';

import 'package:diff_match_patch/diff_match_patch.dart';

part 'src/diff_tests.dart';
part 'src/match_tests.dart';
part 'src/patch_tests.dart';

DiffMatchPatch dmp;
InstanceMirror dmpInstanceMirror;

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

Symbol dmpPrivateSymbol(String name) {
  ClassMirror dmpInstanceClassMirror = dmpInstanceMirror.type;
  Map<Symbol, MethodMirror> dmpInstanceMembers = dmpInstanceClassMirror.instanceMembers;
  Symbol nameSymbol = dmpInstanceMembers.keys.singleWhere((Symbol symbol) {
    String symbolName = symbol.toString().substring('Symbol("'.length, symbol.toString().length - 2);
    List<String> symbolNameParts = symbolName.split('@');
    if (symbolNameParts.length > 1) {
      if (symbolNameParts[0] == name) {
        return true;
      }
    }
    return false;
  });
  return nameSymbol;
}

callPrivateWithReturn(String memberName, List<dynamic> positionalArguments) {
  return dmpInstanceMirror.invoke(dmpPrivateSymbol(memberName), positionalArguments).reflectee;
}

callPrivate(String memberName, List<dynamic> positionalArguments) {
  dmpInstanceMirror.invoke(dmpPrivateSymbol(memberName), positionalArguments);
}

void main() {
  dmp = new DiffMatchPatch();
  dmpInstanceMirror = reflect(dmp);

  group('Diff', () {
    test('Common Prefix', testDiffCommonPrefix);
    test('Common Suffix', testDiffCommonSuffix);
    test('Common Overlap', testDiffCommonOverlap);
    test('Halfmatch', testDiffHalfmatch);
    test('Lines To Chars', testDiffLinesToChars);
    test('Chars To Lines', testDiffCharsToLines);
    test('Cleanup Merge', testDiffCleanupMerge);
    test('Cleanup Semantic Lossless', testDiffCleanupSemanticLossless);
    test('Cleanup Semantic', testDiffCleanupSemantic);
    test('Cleanup Efficiency', testDiffCleanupEfficiency);
    test('Pretty Html', testDiffPrettyHtml);
    test('Text', testDiffText);
    test('Delta', testDiffDelta);
    test('XIndex', testDiffXIndex);
    test('Levenshtein', testDiffLevenshtein);
    test('Bisect', testDiffBisect);
    test('Main', testDiffMain);
  });

  group('Match', () {
    test('Alphabet', testMatchAlphabet);
    test('Bitap', testMatchBitap);
    test('Main', testMatchMain);
  });

  group('Patch', () {
    test('Obj', testPatchObj);
    test('From Text', testPatchFromText);
    test('To Text', testPatchToText);
    test('Add Context', testPatchAddContext);
    test('Make', testPatchMake);
    test('Split Max', testPatchSplitMax);
    test('Add Padding', testPatchAddPadding);
    test('Apply', testPatchApply);
  });
}
