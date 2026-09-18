# 🛠️ Project Rules 

## 1. Core Coding Principles (Karpathy-Inspired)

### 1.1 Pre-Action Notification & Plan Sharing (MANDATORY)
- **사전 공유 원칙:** 파일 수정, 생성, 삭제 등 실제 코드/설정 변경 작업을 진행하기 전에 **반드시 어떤 조치를 취할 것인지 계획(조치 사항, 변경 대상 파일, 변경 이유)**을 사용자에게 먼저 명확히 설명합니다.
- **예상 영향도 안내:** 변경 작업이 기존 동작이나 다른 모듈에 미치는 영향(Side effect)을 사전에 요약하여 전달합니다.

### 1.2 Think Before Coding
- **No Assumptions:** Never make blind assumptions about OIDC/OAuth2 protocols or user flows. If any requirement or interface boundary is ambiguous, STOP and ask the user for clarification.
- **Trade-off Analysis:** Present multiple interpretations or architectural choices before implementing core security features (e.g., Token expiration handling, Interceptor vs Filter choices).

### 1.3 Simplicity First
- **Minimal Code:** Implement the absolute minimum Java code required to satisfy the specification. No speculative helper methods or unused utility classes.
- **No Bloated Abstractions:** Avoid heavy design patterns, deep interface hierarchies, or multi-layered architectures for single-use logic. Lean on idiomatic Spring Boot 3.x web components.
- **Code Compression:** If a mechanism can be written cleanly in fewer lines, rewrite and compress it. Keep token generation and filter logic concise.

### 1.4 Surgical Changes
- **Targeted Modifications:** Touch only the precise files/lines necessary for the step-by-step request.
- **Consistency:** Maintain strict consistency with Java 17 records, standard JPA specifications, and existing controller style guides.
- **Hygiene:** Do not randomly refactor adjacent code, format untouched files, or modify unrelated comments. Clean up all unused imports or variables introduced by changes.

### 1.5 Goal-Driven Execution
- **Step-by-Step Delivery:** Break down multi-step features into clear, verifiable success criteria. Do not attempt to output the repository, service, and controller layer all in a single response to optimize token efficiency.

---

## 2. Global Project Context


## 3. Execution Guideline for Agent
- This document serves as the global architecture framework and operational boundary.
- **Pre-Action Protocol:** Always explain the action plan and file changes before executing code modifications.
- Do NOT generate full implementation code for the whole system unless explicitly requested in a split step-by-step prompt.
- Always cross-reference this file before writing configuration files, entities, or filters to ensure strict adherence to the **No Spring Security** and **RS256** guidelines.
