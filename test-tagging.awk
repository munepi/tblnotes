# test-tagging.awk -- check the footnote structures of a tagged PDF
#
#   show-pdf-tags --xml test-tagging.pdf | awk -v want=<n> -f test-tagging.awk
#
# Every footnotemark (Lbl) and footnote (FENote) structure element must
# refer to the other one (/Ref, shown as <?References objects="..." ?>),
# and there must be <want> of each.  Prints TAGS-RESULT OK or NG.
function done() {
  if (kind != "") { id[kind, ++n[kind]] = cur; ref[kind, n[kind]] = refs }
  kind = ""; cur = ""; refs = ""
}
/<footnotemark[ >]/ { done(); kind = "mark"; next }
/<footnote[ >]/     { done(); kind = "note"; next }
kind != "" && /referenced-as="/ {
  s = $0; sub(/.*referenced-as="/, "", s); sub(/".*/, "", s); cur = s; next
}
kind != "" && /<\?References objects="/ {
  s = $0; sub(/.*objects="/, "", s); sub(/".*/, "", s); refs = s; done(); next
}
kind != "" && /^[ \t]*<[^?]/ && !/<footnote/ { done() }
END {
  done(); ng = 0
  for (i = 1; i <= n["note"]; i++) note[id["note", i]] = ref["note", i]
  for (i = 1; i <= n["mark"]; i++) {
    m = id["mark", i]; r = ref["mark", i]
    if (m == "" || r == "") { print "TAGS-MARK NG: mark " i " has no Ref"; ng++; continue }
    if (!(r in note)) { print "TAGS-MARK NG: mark " m " refers to " r ", not a footnote"; ng++; continue }
    if (!index(" " note[r] " ", " " m " ")) { print "TAGS-NOTE NG: footnote " r " does not refer to mark " m; ng++ }
  }
  for (i = 1; i <= n["note"]; i++)
    if (ref["note", i] == "") { print "TAGS-NOTE NG: footnote " i " has no Ref"; ng++ }
  if (n["mark"] != want || n["note"] != want) {
    print "TAGS-COUNT NG: " n["mark"] " marks, " n["note"] " footnotes, want " want; ng++
  }
  print (ng ? "TAGS-RESULT NG" : "TAGS-RESULT OK") " (" n["mark"] " marks, " n["note"] " footnotes)"
  exit (ng ? 1 : 0)
}
