|NEW_FILE

# LocalVault - Core Concepts and Capabilities Summary

> Core context for Flutter mobile version  
> **Version**: v1.0 | **Date**: 2026-03-08

---

## 🎯 Core Concept

**LocalVault = Local Memory Bank for AI**

Solves the pain point: All AIs (Doubao, Grok, DeepSeek, ChatGPT) are **isolated per conversation with no long-term
memory**

Core values:

- ✅ **Cross-conversation**: Important conclusions from last time can be directly referenced next time
- ✅ **Cross-platform**: Summaries saved in Doubao can be injected into DeepSeek
- ✅ **100% local**: Zero uploads, privacy-first, full user control
- ✅ **Minimal design**: Only storage + access, no intelligent generation

---

## 🔑 Three Core Features

### 1. Save

**Triggers**: Floating ball wake-up, voice command, or gesture wake-up

**Process**:
AI reply → Detect keywords → Pop up confirmation → Fill in title/tags → Save locally
