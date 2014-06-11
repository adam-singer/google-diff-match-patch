/*
 * Diff Match and Patch
 *
 * Copyright 2011 Google Inc.
 * http://code.google.com/p/google-diff-match-patch/
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

part of DiffMatchPatch;

/**
 * Class representing one patch operation.
 */
class Patch {
  List<Diff> diffs;
  int start1;
  int start2;
  int length1 = 0;
  int length2 = 0;

  /**
   * Constructor.  Initializes with an empty list of diffs.
   */
  Patch() {
    this.diffs = <Diff>[];
  }

  /**
   * Emmulate GNU diff's format.
   * Header: @@ -382,8 +481,9 @@
   * Indicies are printed as 1-based, not 0-based.
   * Returns the GNU diff string.
   */
  String toString() {
    String coords1, coords2;
    if (this.length1 == 0) {
      coords1 = '${this.start1},0';
    } else if (this.length1 == 1) {
      coords1 = (this.start1 + 1).toString();
    } else {
      coords1 = '${this.start1 + 1},${this.length1}';
    }
    if (this.length2 == 0) {
      coords2 = '${this.start2},0';
    } else if (this.length2 == 1) {
      coords2 = (this.start2 + 1).toString();
    } else {
      coords2 = '${this.start2 + 1},${this.length2}';
    }
    final text = new StringBuffer('@@ -$coords1 +$coords2 @@\n');
    // Escape the body of the patch with %xx notation.
    for (Diff aDiff in this.diffs) {
      switch (aDiff.operation) {
      case DIFF_INSERT:
        text.add('+');
        break;
      case DIFF_DELETE:
        text.add('-');
        break;
      case DIFF_EQUAL:
        text.add(' ');
        break;
      }
      text.add(encodeUri(aDiff.text)).add('\n');
    }
    return text.toString().replaceAll('%20', ' ');
  }
}
