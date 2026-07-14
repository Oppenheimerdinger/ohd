# oppenheimerdinger — 설계 스펙 (living draft)

**날짜**: 2026-07-14
**상태**: 탐색 중 초안 — "열린 질문" 섹션이 비워질 때까지 반복 갱신
**한 줄**: 개발과 연구를 Claude Code로 잘하기 위한 하네스 플러그인 — dipark의
프로젝트 설계·유지관리·작업 방식을 코드화해서, 연구는 잘하지만 개발지식이
부족한 사용자도 그대로 쓰게 한다.

## 대상 사용자와 설계 톤 (모든 컴포넌트에 적용)

- 사용자: 연구 역량은 높고 git/worktree/배포 지식은 부족한 연구자.
- 따라서 모든 갈림길은 **인터뷰 주도**: 질문하고, 안전한 기본값과 함께
  **반드시 추천 1개를 제시**하고, 사용자가 결정한다 (deep-solve 게이트 원칙의
  일반화). 강제 대신 게이트, 완벽 대신 정직.
- 대부분의 컴포넌트는 **재구현이 아니라 오케스트레이션 글루**: superpowers /
  OMC(ralph) / code-review / Workflow 툴을 "dipark 방식으로 부르는 법"을 스킬로
  박제한다.

## 패키징

- **모노 플러그인**: `oppenheimerdinger` 하나에 스킬/커맨드 전부 내장.
  deep-solve도 **흡수** (독립 repo 유지 비용 > 가치 — 사용자 결정 2026-07-14).
- Repo: `Oppenheimerdinger/oppenheimerdinger` (공개 GitHub, MIT).
  repo가 marketplace를 겸함 — marketplace 이름 **`dipark`** 유지 (deep-solve
  repo에서 이사).
- 설치: `claude plugin marketplace add Oppenheimerdinger/oppenheimerdinger`
  → `claude plugin install oppenheimerdinger@dipark`.

### deep-solve 흡수 마이그레이션

1. `skills/deep-solve/` (SKILL.md + solve-converge.js) + `commands/deep-solve.md`
   + `tests/` 를 이 repo로 이식 (v0.2.2 기준, 히스토리는 커밋 메시지로 출처 표기).
2. **커맨드:스킬 동명 충돌 workaround 유지** — 커맨드가 SKILL.md를
   `@${CLAUDE_PLUGIN_ROOT}` 인라인 (플러그인이 바뀌어도 구조 동일).
3. 옛 repo `Oppenheimerdinger/deep-solve`: README 상단에 "moved to
   oppenheimerdinger" 포인터 추가 후 GitHub archive.
4. 기설치자 이주: `claude plugin uninstall deep-solve@dipark` →
   marketplace re-add → `install oppenheimerdinger@dipark`. USAGE 안내 갱신.
5. 스킬 id 변경: `deep-solve:deep-solve` → `oppenheimerdinger:deep-solve`.
   메모리/문서의 참조 갱신.

## 컴포넌트 인벤토리 (작명 확정분)

| 이름 | 종류 | 내용 | 원천 |
|---|---|---|---|
| `setup` | 커맨드+스킬 | 선행 플러그인(superpowers, oh-my-claudecode, code-review) 설치 점검 → 미설치 시 추천 + 설치 커맨드 안내. 개발지식 부족 사용자의 첫 관문 | 신규 |
| `new-project` | 커맨드+스킬 | 인터뷰 주도 프로젝트 스캐폴더 (아래 §인터뷰) | 신규 (umbrella-proj/validation-proj 패턴 일반화) |
| `campaign-land` | 스킬 | land 의식: 게이트 체크리스트 → push+PR → 병합 순서(포크 먼저→pin→본체) → clean → 교훈 증류 + md-sanity. squash-merge/스택PR/living-doc union 함정 포함 | umbrella-proj 스킬 일반화 |
| `campaign-status` | 스킬 | git refs + PR API로 병합상태 판정 (기억이 아니라 refs가 진실) | umbrella-proj 스킬 승격 (거의 그대로) |
| `claude-md-sanity` | 스킬 | CLAUDE.md/메모리 드리프트 감사 — **중첩 CLAUDE.md 전체** 순회 | 개인 스킬 승격 (이름 유지) |
| `review-to-convergence` | 스킬 | 산출물 zero-finding 검증 루프; 코드면 /code-review를 계기로 | 개인 스킬 승격 |
| `deep-solve` | 커맨드+스킬+Workflow 스크립트 | isolated/grounded 이중모드 수렴 하네스 | deep-solve v0.2.2 흡수 |
| `way-of-working` | 스킬 | 하네스 규약: superpowers 경유 작업 방식, 품질 라우팅(§라우팅), ralph 사용법+**오발동 방지**, 창의적 작업 뒤 workflow 리뷰, worktree/anchor/trunk 규율 요약 | 신규 (글로벌 CLAUDE.md 규약의 스킬화) |

작명 원칙: 동사/행위 중심 kebab-case; 플러그인명과 동명 스킬 금지; 확립된
이름(campaign-land, claude-md-sanity, deep-solve)은 유지. 용어는
**campaign으로 통일** (validation-proj의 milestone도 campaign 어휘로 수렴; 생성
인터뷰에서 스크립트 파라미터만 달라짐).

### 제외 (명시적 non-goal)

- `the-company-report` — 회사 자산(로고/LaTeX 템플릿), 공개 repo 불가. 사내 별도.
- 도메인 스킬 (parity-gate, measure-to-ceiling, occupancy-limiter-first) —
  GPU/DFT 도메인이라 프로젝트 repo에 잔류. 단 new-project가 "프로젝트별
  `.claude/skills/` 디렉토리" 관례 자체는 깔아준다.

## `new-project` 인터뷰 (파라미터 = 탐사에서 확인된 실제 변주)

campaign.sh(무거움)와 milestone.sh(가벼움)는 같은 라이프사이클
(`new → land → clean/abort`, worktree 1:1, 보호 트렁크, GitHub=truth)의
변형이므로, **파라미터화된 campaign.sh 템플릿 하나**를 assets로 배포하고
인터뷰가 인스턴스화한다:

1. **외부 코드 반입**: 없음 / fork+manifest pin (hosts/ 패턴: VEHICLE=fork,
   TRUNK, PIN, campaign.sh pin 연동) / patches (VEHICLE=patches) / submodule /
   vendor. 기본 추천: 수정이 필요한 외부코드 = fork+pin, 읽기전용 = pin된 clone.
2. **병합 모델**: 코디네이터 로컬 병합 (umbrella-proj형 — 앵커 세션이 gh pr merge) /
   GitHub 리뷰 게이트 (validation-proj형 — land에서 세션 종료). 기본: 1인 프로젝트면
   코디네이터형, 협업이면 리뷰 게이트형.
3. **배포 형태**: 없음 / <shared-storage> vX.Y.Z 스냅숏+latest+cache (pkg-proj형) /
   read-only main 미러 (validation-proj형). 사내 공유 여부 질문으로 분기.
4. **환경**: uv / conda / 모듈 — venv 공유 여부(read-only symlink + --local-venv
   탈출구) 포함.
5. **데이터**: 대용량 공유 데이터 여부 → datasets/ read-only symlink +
   --local-data 패턴.
6. **명명**: campaign 이름 자유형 vs NNN-slug 번호형.
7. 공통 산출물 (질문 없이 항상): git init + GitHub private repo(origin=GitHub
   규약) + 보호 트렁크(pre-commit: docs/**·*.md만) + tools/campaign.sh +
   tools/install-hooks.sh + **CLAUDE.md 토폴로지** (루트 + hosts/서브시스템별
   중첩 골격, 자기유지 promise 문구 포함 — md-sanity가 감사할 대상) +
   `.claude/skills/` 디렉토리 + docs/campaigns/ 상태문서 템플릿.

## 품질 라우팅 (way-of-working에 박제)

| 상황 | 도구 |
|---|---|
| 답이 아직 없음 (미해결 문제) | deep-solve (isolated/grounded는 그 안에서 라우팅) |
| 산출물이 이미 있음 (문서/분석/설계) | review-to-convergence |
| 산출물이 코드 diff | review-to-convergence가 /code-review를 계기로 호출 |
| 창의적/구조적 작업 직후 | workflow 리뷰 (multi-agent) — 규모 기준 명시 필요(열린 질문) |

## 열린 질문 (탐색하며 채움)

- [ ] "더 챙겨야 할 부분" — 사용자가 아직 다 알려주지 않음. 실사용 시나리오
      워크스루로 발굴.
- [ ] `deep-research` 스킬의 소재 불명 (~/.claude/skills에 없음) — 추적 후
      포함 여부 결정.
- [ ] ralph 글루의 구체 내용: 언제 ralph가 적절한가 / 오발동 방지(2026-07-14
      키워드 훅 사건) / cancel 절차. way-of-working에 넣을지 별도 스킬인지.
- [ ] workflow 리뷰의 트리거 기준 ("창의적 작업 뒤" — 규모/비용 기준).
- [ ] campaign.sh 템플릿의 파라미터화 방식: 생성 시 sed 인스턴스화 vs 런타임
      설정파일(env) 읽기.
- [ ] 버전/릴리스 흐름: 이 플러그인 자신의 개발도 campaign 방식으로? (셀프
      호스팅 — repo에 tools/campaign.sh 깔기)
- [ ] 테스트 전략: deep-solve 테스트는 이식; new-project 스캐폴더는 스모크
      (임시 dir에 생성 → 구조 검증) 가능. 스킬 텍스트는 plugin-dev 리뷰로.
- [ ] marketplace `dipark` 이사 시점과 deep-solve repo archive 시점 (플러그인
      v0.1이 deep-solve 기능 동등성 확보한 후).
- [ ] CLAUDE.md 템플릿의 내용 수위 — 글로벌 CLAUDE.md에서 무엇을 프로젝트
      템플릿으로 내리고 무엇을 way-of-working 스킬로 올릴지.
