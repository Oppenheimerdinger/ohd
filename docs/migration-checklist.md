# Migration checklist (deep-solve → oppenheimerdinger)

세션 노드는 2026-07-14 완료 (리허설 겸): uninstall → marketplace remove →
add → install 순서로 무결 (add-before-remove 실패 모드는 미발생 — remove를
먼저 했기 때문. 순서 유지 권장).

## 머신별 절차 (잔여: cloud-gpubox, gpu-server-b, 기타 랩탑)

```
claude plugin uninstall deep-solve@dipark          # 설치돼 있던 경우
claude plugin marketplace remove dipark            # 옛 repo를 가리키던 경우
claude plugin marketplace add Oppenheimerdinger/oppenheimerdinger
claude plugin install oppenheimerdinger@dipark
mkdir -p ~/.claude/skills-backup-2026-07-14
mv ~/.claude/skills/claude-md-sanity      ~/.claude/skills-backup-2026-07-14/ 2>/dev/null
mv ~/.claude/skills/review-to-convergence ~/.claude/skills-backup-2026-07-14/ 2>/dev/null
```

그다음 세션 재시작 → `/ohd-setup` 으로 확인.

## 동료 재공유 메시지 (원래 채널에)

> deep-solve가 oppenheimerdinger 플러그인으로 통합됐습니다 (기능 동일 + 도구
> 추가: 환경 점검 /ohd-setup, 산출물 검증 review-to-convergence, CLAUDE.md
> 감사 claude-md-sanity). 예전 설치가 있다면:
>
>     claude plugin uninstall deep-solve@dipark
>     claude plugin marketplace remove dipark
>     claude plugin marketplace add Oppenheimerdinger/oppenheimerdinger
>     claude plugin install oppenheimerdinger@dipark
>
> 세션 재시작 후 /ohd-setup 실행. 예전 가이드 링크는 이제 안내용입니다 —
> 새 가이드: https://github.com/Oppenheimerdinger/oppenheimerdinger/blob/main/docs/USAGE-ko.md
