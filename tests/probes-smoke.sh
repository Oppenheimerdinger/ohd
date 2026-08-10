#!/usr/bin/env bash
# probes-smoke.sh — the shipped probe assets, black-box.
#
# The one contract every assertion below exists to hold: agent-facing failure is
# EXIT-CODE-SHAPED. Agents read logs through tails and summarizers, so a warning
# line is structurally unseen — a probe that warns and continues has failed open.
# Every negative case here therefore asserts a NON-ZERO exit, not a message.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
P="$HERE/assets/probes"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "PROBES-SMOKE FAIL: $*" >&2; exit 1; }
# run a probe, capture its exit code without tripping set -e
rc() { local c=0; "$@" >/dev/null 2>&1 || c=$?; echo "$c"; }

# EVERY non-git assertion below — mutation_run's "contamination unverified"
# scoping and provenance_block's git=n/a case — reads as a PASS if TMPDIR
# happens to sit inside a repository. Refuse once, here, ahead of all of them:
# a vacuous green is exactly what lets the regression walk back in.
git -C "$TMP" rev-parse --git-dir >/dev/null 2>&1 \
  && fail "fixture invalid: TMPDIR is inside a git repo — non-git assertions would misreport"

for probe in engage_grep.sh mutation_run.sh provenance_block.sh; do
  [ -f "$P/$probe" ] || fail "$probe not shipped in assets/probes/"
  [ -x "$P/$probe" ] || fail "$probe is not executable"
  bash -n "$P/$probe" || fail "$probe has syntax errors"
  # every probe carries its own failure path
  [ "$(rc bash "$P/$probe" --self-test)" = 0 ] || fail "$probe --self-test did not pass"
  # ...and a usage line naming itself
  bash "$P/$probe" --help 2>&1 | grep -q "$probe" || fail "$probe --help does not name itself"
  # SMALL: these are assets projects copy in, not a framework
  n="$(wc -l < "$P/$probe")"
  [ "$n" -le 120 ] || fail "$probe is $n lines (target <=120)"
done

# ---------- engage_grep: the route assertion ----------
cd "$TMP"
cat > run.log <<'EOF'
starting
backend=fused kernel selected
step 1 ok
run complete
EOF
E="$P/engage_grep.sh"
[ "$(rc bash "$E" --must 'backend=fused' --must-not 'fallback' --anchor 'run complete' run.log)" = 0 ] \
  || fail "engage_grep failed a log that satisfies every assertion"
# the must-match line is missing -> DIE
[ "$(rc bash "$E" --must 'backend=reference' --anchor 'run complete' run.log)" = 1 ] \
  || fail "engage_grep did not die when the required route marker was absent"
# the must-NOT line is present -> DIE
[ "$(rc bash "$E" --must 'backend=fused' --must-not 'step 1' --anchor 'run complete' run.log)" = 1 ] \
  || fail "engage_grep did not die when a forbidden line was present"
# the positive-state anchor is what stops a CRASHED run from passing: a run that
# died before reaching the fallback satisfies --must-not vacuously
cat > crashed.log <<'EOF'
starting
backend=fused kernel selected
EOF
[ "$(rc bash "$E" --must 'backend=fused' --must-not 'fallback' --anchor 'run complete' crashed.log)" = 1 ] \
  || fail "engage_grep passed a crashed run (anchor not enforced)"
# skipping the anchor is possible but ATTESTED, never silent
[ "$(rc bash "$E" --must 'backend=fused' --must-not 'fallback' crashed.log)" = 2 ] \
  || fail "engage_grep ran without an anchor and without an attested skip"
[ "$(rc bash "$E" --must 'backend=fused' --no-anchor 'log has no completion marker' crashed.log)" = 0 ] \
  || fail "attested --no-anchor was not honored"
bash "$E" --must 'backend=fused' --no-anchor 'no completion marker' crashed.log \
  | grep -q 'no completion marker' || fail "attested skip reason does not reach the proof line"
# FIXED-STRING by default: the hand-rolled regex that can never match is the
# measured failure this default exists to prevent
printf 'value = a.c\n' > lit.log
[ "$(rc bash "$E" --must 'a.c' --no-anchor t lit.log)" = 0 ] || fail "fixed-string --must failed on a literal hit"
[ "$(rc bash "$E" --must 'a?c' --no-anchor t lit.log)" = 1 ] || fail "'a?c' matched as a regex under the fixed-string default"
[ "$(rc bash "$E" --regex --must 'a.c' --no-anchor t lit.log)" = 0 ] || fail "--regex did not enable regex matching"
# a missing file is a hard error, never a vacuous pass
[ "$(rc bash "$E" --must x --no-anchor t nosuch.log)" != 0 ] || fail "engage_grep passed on a missing file"
# a value-taking flag with NO value must DIE, and die FAST. The `timeout` is the
# regression guard, not decoration: the original bug dropped the validator's
# `exit 2` inside a command substitution, so it killed the subshell only, the
# flag was never shifted past, and the parse loop re-read it forever. A
# regression must fail this suite, not wedge CI for its whole time budget.
for bad in "--must" "--must-not" "--anchor" "--no-anchor"; do
  # shellcheck disable=SC2086
  [ "$(rc timeout 5 bash "$E" --must seed $bad)" = 2 ] \
    || fail "engage_grep did not exit 2 on a trailing valueless $bad (124 = it hung)"
done
[ "$(rc timeout 5 bash "$E" --must)" = 2 ] || fail "engage_grep did not exit 2 on a lone valueless --must (124 = it hung)"
# an EMPTY value is the same bug wearing a different hat: the subshell died, the
# empty string was appended as a marker, and `--must ''` then matched every line
[ "$(rc timeout 5 bash "$E" --must '' --no-anchor t lit.log)" = 2 ] \
  || fail "engage_grep accepted an empty --must value (it matches every line)"

# ---------- mutation_run: proving the tests CAN fail ----------
M="$P/mutation_run.sh"
mkdir -p mut && cd mut
echo GOOD > impl.txt && echo OTHER > other.txt
CHK='grep -q GOOD impl.txt'
ARM='signflip|sed -i s/GOOD/BAD/ impl.txt|sed -i s/BAD/GOOD/ impl.txt'
[ "$(rc bash "$M" --check "$CHK" --arm "$ARM" --untouched 'grep -q OTHER other.txt')" = 0 ] \
  || fail "mutation_run failed a run whose arm is properly caught"
# Assertions on probe OUTPUT capture first and match second, never
# `probe | grep`. Under `set -o pipefail` that pipe is a race: `grep -q` exits
# on the matching line, the probe's NEXT line then writes to a closed pipe and
# dies 141, and pipefail promotes 141 to the pipeline status — so the assertion
# reports failure while the string it looked for was present. Observed at ~7.5%
# here, on whichever probe emits a trailing line (mutation_run's not-a-git-tree
# NOTE, provenance_block's second field line).
grep -q '1 tried / 1 caught' <<<"$(bash "$M" --check "$CHK" --arm "$ARM")" \
  || fail "mutation_run summary does not report tried/caught counts"
grep -q 'no-op control ok' <<<"$(bash "$M" --check "$CHK" --arm "$ARM")" \
  || fail "mutation_run summary does not report the no-op control"
grep -q GOOD impl.txt || fail "mutation_run left the tree mutated after a clean run"
# a check that CANNOT fail is the whole point -> DIE, naming the arm
out="$(bash "$M" --check true --arm "$ARM" 2>&1)" && fail "mutation_run passed a check that cannot fail"
grep -q signflip <<<"$out" || fail "the uncaught-arm failure does not name the arm"
grep -q GOOD impl.txt || fail "mutation_run left the tree mutated after a FAILED run"
# a red baseline makes every later result meaningless -> DIE before any arm runs
[ "$(rc bash "$M" --check false --arm "$ARM")" != 0 ] || fail "mutation_run ran arms on a red baseline"
# the untouched-phase control: if a mutation breaks a phase it never touched,
# "caught" is not evidence of a sharp test
[ "$(rc bash "$M" --check "$CHK" --arm "$ARM" --untouched 'grep -q GOOD impl.txt')" != 0 ] \
  || fail "mutation_run accepted an arm that broke the untouched-phase control"
grep -q GOOD impl.txt || fail "mutation_run left the tree mutated after the control failed"
# arms are SERIAL by construction — no parallel mode to get the evidence wrong
grep -qi 'serial' "$M" || fail "mutation_run does not state that arms run serially"
[ "$(rc bash "$M" --check "$CHK" --arm "$ARM" --jobs 4)" = 2 ] || fail "mutation_run accepted a parallelism flag"
# a restore that does not restore is a setup failure, not a pass
[ "$(rc bash "$M" --check "$CHK" --arm 'bad|sed -i s/GOOD/BAD/ impl.txt|true')" != 0 ] \
  || fail "mutation_run passed an arm whose restore left the tree dirty"
echo GOOD > impl.txt
# valueless flag -> exit 2, under a timeout (see the engage_grep block: the same
# validator-in-a-subshell bug spun this parse loop forever)
for bad in "--check" "--arm" "--untouched"; do
  # shellcheck disable=SC2086
  [ "$(rc timeout 5 bash "$M" --check "$CHK" $bad)" = 2 ] \
    || fail "mutation_run did not exit 2 on a trailing valueless $bad (124 = it hung)"
done
[ "$(rc timeout 5 bash "$M" --check)" = 2 ] || fail "mutation_run did not exit 2 on a lone valueless --check (124 = it hung)"
# restore verification is CHECK-SCOPED, so outside a git work tree a restore that
# leaks a file cannot be seen at all — the probe must SAY so, not imply it looked
grep -qi 'not a git work tree' <<<"$(bash "$M" --check "$CHK" --arm "$ARM")" \
  || fail "outside a git tree, mutation_run does not state that contamination is unverified"
# ...and inside one, the leak is caught: this arm undoes the mutation the check
# looks at and still leaves a new file behind, so every gate above stays green
# identity at INIT time, not inline per commit: a CI runner has no global one,
# and a later assertion that adds a commit must not have to remember the flags
mkdir -p "$TMP/gitmut" && cd "$TMP/gitmut" && git init -q
git config user.email smoke@test && git config user.name smoke
echo GOOD > impl.txt
git add -A && git commit -qm base >/dev/null
LEAKY='leak|sed -i s/GOOD/BAD/ impl.txt && touch stray.txt|sed -i s/BAD/GOOD/ impl.txt'
out="$(bash "$M" --check 'grep -q GOOD impl.txt' --arm "$LEAKY" 2>&1)" \
  && fail "mutation_run passed an arm whose restore leaked a file into the tree"
grep -q 'stray.txt' <<<"$out" || fail "the tree-contamination failure does not name the leftover path"
grep -qi 'per-run-unique' <<<"$out" \
  || fail "the contamination failure blames a leaked restore without naming the other cause"
rm -f stray.txt
# the OTHER cause of the same signal: a --check that writes a per-run-unique
# file. The probe cannot tell the two apart, so the message must not pick one.
# (A STABLE-named artifact is absorbed: the baseline runs happen before the
# snapshot, so it is already in it — which is why the precondition is only
# about per-run-unique names.)
out="$(bash "$M" --check 'grep -q GOOD impl.txt && touch "log.$(date +%s%N)"' \
       --arm 'clean|sed -i s/GOOD/BAD/ impl.txt|sed -i s/BAD/GOOD/ impl.txt' 2>&1)" \
  && fail "a per-run-unique check artifact did not trip the tree comparison"
grep -qi 'per-run-unique' <<<"$out" \
  || fail "a per-run-unique check artifact is misreported as a leaked restore"
rm -f log.*
grep -qi 'per-run-unique' <<<"$(bash "$M" --help)" \
  || fail "--help does not state the no-per-run-unique-files precondition"
# the same arm without the leak still passes — the check is contamination, not
# "any git tree makes this fail"
out="$(bash "$M" --check 'grep -q GOOD impl.txt' --arm 'clean|sed -i s/GOOD/BAD/ impl.txt|sed -i s/BAD/GOOD/ impl.txt')" \
  || fail "a properly restoring arm failed the tree-contamination check"
# ...and the success line does not overclaim: git status cannot see an ignored
# path, so "tree unchanged" has to say what it actually compared
grep -q 'ignored paths not checked' <<<"$out" \
  || fail "the success line claims 'tree unchanged' without scoping it to what git status sees"
cd "$TMP/mut"

# ---------- provenance_block: which route ACTUALLY ran ----------
cd "$TMP"
V="$P/provenance_block.sh"
out="$(OHDTEST_FLAG=on bash "$V" --field backend=fused --cmd device='echo cuda:0' --env-prefix OHDTEST_)"
grep -q 'backend=fused' <<<"$out"        || fail "provenance_block dropped a --field"
grep -q 'device=cuda:0' <<<"$out"        || fail "provenance_block dropped a --cmd result"
grep -q 'env.OHDTEST_FLAG=on' <<<"$out"  || fail "provenance_block dropped a matching env flag"
grep -q 'OHDTEST_' <<<"$(bash "$V" --env-prefix OHDTEST_)" || fail "provenance_block hides the prefix it filtered on"
# a field that could not be resolved is RECORDED as unavailable, never omitted
out="$(bash "$V" --cmd gpu='exit 7' || true)"
grep -q 'gpu=unavailable' <<<"$out"      || fail "an unresolvable --cmd was silently dropped"
# --require turns a missing field into an exit code
[ "$(rc bash "$V" --field backend=fused --require backend)" = 0 ] || fail "--require failed on a present field"
[ "$(rc bash "$V" --field backend=fused --require kernel)" = 1 ] || fail "--require did not die on a missing field"
[ "$(rc bash "$V" --cmd gpu='exit 7' --require gpu)" = 1 ]       || fail "--require accepted an unavailable field"
# the artifact form: a run's route proof is a recorded fact, not archaeology
bash "$V" --field backend=fused --out prov.txt >/dev/null
grep -q 'backend=fused' prov.txt         || fail "--out did not write the provenance block"
# outside a git work tree the git field is n/a and STAYS n/a: `git diff --quiet`
# exits 129 there (not a repository), and a bare `||` chain reads that as "dirty"
# — a FABRICATED flag, in the one artifact whose whole job is recording facts
mkdir -p "$TMP/nogit" && cd "$TMP/nogit"
out="$(bash "$V" --field backend=fused)"
grep -q '^git=n/a$' <<<"$out" || fail "outside a git tree the git field is not plain n/a"
grep -q 'n/a-dirty' <<<"$out" && fail "outside a git tree provenance_block fabricated a dirty flag"
# ...and inside one a real dirty tree IS still flagged (the suffix is not just dead)
mkdir -p "$TMP/gitprov" && cd "$TMP/gitprov" && git init -q
git config user.email smoke@test && git config user.name smoke
echo one > f.txt && git add -A && git commit -qm base >/dev/null
echo two > f.txt
grep -qE '^git=[0-9a-f]+-dirty$' <<<"$(bash "$V" --field backend=fused)" \
  || fail "inside a git tree, a dirty work tree is no longer flagged"
cd "$TMP"
# valueless flag -> exit 2, under a timeout (see the engage_grep block)
for bad in "--field" "--cmd" "--env-prefix" "--require" "--out"; do
  # shellcheck disable=SC2086
  [ "$(rc timeout 5 bash "$V" --field backend=fused $bad)" = 2 ] \
    || fail "provenance_block did not exit 2 on a trailing valueless $bad (124 = it hung)"
done
[ "$(rc timeout 5 bash "$V" --require)" = 2 ] || fail "provenance_block did not exit 2 on a lone valueless --require (124 = it hung)"

echo "PROBES-SMOKE PASS"
