# 1199-coleman

Personal skill library for Claude Code.

## Install
```bash
bash install.sh
```

## Structure
- `atomic/` - single-responsibility IO skills
- `composite/` - multi-step skills that depend on atomic skills

## Skills
| Layer | Skill | Trigger |
|-------|-------|---------|
| atomic | read-wiki | 读取Notion wiki |
| atomic | read-all-prds | 读取所有PRD |
| atomic | read-tracker | 读取进度tracker |
| atomic | read-experiment-logs | 读取实验日志 |
| atomic | write-wiki-page | 写入Notion页面 |
| atomic | clone-codebase | 临时clone代码库 |
| atomic | append-version-log | 追加版本记录 |
| composite | paper-distill | 蒸馏paper到wiki |
| composite | prd-draft | 起草新PRD |
| composite | prd-edit | 修改现有PRD |
| composite | prd-critique | 批评审阅PRD |
| composite | knowledge-retrieval | 检索知识库 |
| composite | knowledge-correction | 修正知识库 |
| composite | progress-digest | 综合进度理解 |
| composite | experiment-design | 实验设计规范 |
| composite | slides-report | 生成汇报幻灯片 |
| composite | wiki-lint | 知识库健康检查 |
