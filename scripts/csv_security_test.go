// SPDX-License-Identifier: AGPL-3.0-or-later
package csv

import (
	"bufio"
	"bytes"
	"strings"
	"testing"
)

func TestOpenImageCSVRecordLimit(t *testing.T) {
	for _, skip := range []int{0, csvSplitSize} {
		for _, size := range []int{maxCharsPerRecord, maxCharsPerRecord + 1} {
			input := strings.Repeat("a", size) + "\n"
			r := &Reader{buf: bufio.NewReader(strings.NewReader(input))}
			got, err := r.nextSplit(skip, nil)
			if size > maxCharsPerRecord {
				if err == nil || len(got) != 0 {
					t.Fatalf("oversized record accepted: skip=%d len=%d err=%v", skip, len(got), err)
				}
			} else if err != nil || !bytes.Equal(got, []byte(input)) {
				t.Fatalf("valid record rejected: skip=%d len=%d err=%v", skip, len(got), err)
			}
		}
	}
}
