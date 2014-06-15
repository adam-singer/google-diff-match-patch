part of diff_match_patch_test_harness;

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
  expect(dmp.patch_fromText('').isEmpty, isTrue, reason: 'patch_fromText: #0.');

  String strp = '@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n %0Alaz\n';
  expect(strp, dmp.patch_fromText(strp)[0].toString(), reason: 'patch_fromText: #1.');

  expect('@@ -1 +1 @@\n-a\n+b\n', dmp.patch_fromText('@@ -1 +1 @@\n-a\n+b\n')[0].toString(), reason: 'patch_fromText: #2.');

  expect('@@ -1,3 +0,0 @@\n-abc\n', dmp.patch_fromText('@@ -1,3 +0,0 @@\n-abc\n')[0].toString(), reason: 'patch_fromText: #3.');

  expect('@@ -0,0 +1,3 @@\n+abc\n', dmp.patch_fromText('@@ -0,0 +1,3 @@\n+abc\n')[0].toString(), reason: 'patch_fromText: #4.');

  // Generates error.
  expect(() => dmp.patch_fromText('Bad\nPatch\n'), throwsArgumentError, reason: 'patch_fromText: #5.');
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
  callPrivate('_patch_addContext', [p, 'The quick brown fox jumps over the lazy dog.']);
  expect('@@ -17,12 +17,18 @@\n fox \n-jump\n+somersault\n s ov\n', p.toString(), reason: 'patch_addContext: Simple case.');

  p = dmp.patch_fromText('@@ -21,4 +21,10 @@\n-jump\n+somersault\n')[0];
  callPrivate('_patch_addContext', [p, 'The quick brown fox jumps.']);
  expect('@@ -17,10 +17,16 @@\n fox \n-jump\n+somersault\n s.\n', p.toString(), reason: 'patch_addContext: Not enough trailing context.');

  p = dmp.patch_fromText('@@ -3 +3,2 @@\n-e\n+at\n')[0];
  callPrivate('_patch_addContext', [p, 'The quick brown fox jumps.']);
  expect('@@ -1,7 +1,8 @@\n Th\n-e\n+at\n  qui\n', p.toString(), reason: 'patch_addContext: Not enough leading context.');

  p = dmp.patch_fromText('@@ -3 +3,2 @@\n-e\n+at\n')[0];
  callPrivate('_patch_addContext', [p, 'The quick brown fox jumps.  The quick brown fox crashes.']);
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
  expect(diffs, dmp.patch_fromText('@@ -1,21 +1,21 @@\n-%601234567890-=%5B%5D%5C;\',./\n+~!@#\$%25%5E&*()_+%7B%7D%7C:%22%3C%3E?\n')[0].diffs, reason: 'patch_fromText: Character decoding.');

  final sb = new StringBuffer();
  for (int x = 0; x < 100; x++) {
    sb.write('abcdef');
  }
  text1 = sb.toString();
  text2 = '${text1}123';
  expectedPatch = '@@ -573,28 +573,31 @@\n cdefabcdefabcdefabcdefabcdef\n+123\n';
  patches = dmp.patch_make(text1, text2);
  expect(expectedPatch, dmp.patch_toText(patches), reason: 'patch_make: Long string with repeats.');

  // Test null inputs.
  expect(() => dmp.patch_make(null), throwsArgumentError, reason: 'patch_make: Null inputs.');
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
