# Project Context & Agent Rules

이 프로젝트에서는 [PROJECT_RULES.md](file:///D:/intelij_workspace/UntitleApp/UntitleApp/PROJECT_RULES.md)에 정의된 규칙을 최우선으로 준수해야 합니다.

---

## 1. Core Principles (MANDATORY)

### 1.1 Pre-Action Notification & Plan Sharing (필수 준수)
- **사전 공유 원칙:** 파일 수정, 생성, 삭제 등 실제 코드/설정 변경 작업을 진행하기 전에 **반드시 어떤 조치를 취할 것인지 계획(조치 사항, 변경 대상 파일, 변경 이유)**을 사용자에게 먼저 명확히 설명합니다.
- **예상 영향도 안내:** 변경 작업이 기존 동작이나 다른 모듈에 미치는 영향(Side effect)을 사전에 요약하여 전달합니다.

### 1.2 Think Before Coding
- **No Assumptions:** 요구사항이나 인터페이스 경계가 모호할 경우 임의로 추측하지 말고 사용자에게 질문하여 명확히 확인합니다.
- **Trade-off Analysis:** 핵심 아키텍처나 기능 구현 전 선택지 및 트레이드오프를 제시합니다.

### 1.3 Simplicity First
- **Minimal Code:** 요구사항을 만족하는 최소한의 코드를 작성하며, 불필요한 유틸리티나 추상화를 지양합니다.
- **No Bloated Abstractions:** 단일 용도 로직을 위한 과도한 디자인 패턴이나 다계층 구조를 피하고 관용적인 Spring Boot 3.x 컴포넌트를 활용합니다.
- **Code Compression:** 간결하고 명확하게 압축된 코드를 유지합니다.

### 1.4 Surgical Changes
- **Targeted Modifications:** 요청된 작업에 꼭 필요한 파일과 라인만 정확히 수정합니다.
- **Consistency & Hygiene:** 프로젝트 스타일 가이드를 준수하며, 작업과 무관한 파일 리팩토링이나 포맷팅을 하지 않고 불필요한 import를 정리합니다.

### 1.5 Goal-Driven Execution
- **Step-by-Step Delivery:** 단계별로 검증 가능한 기준을 세워 점진적으로 진행합니다.

---

## 2. Detailed Rules Reference
- 전체 상세 아키텍처 및 세부 지침: [PROJECT_RULES.md](file:///D:/intelij_workspace/UntitleApp/UntitleApp/PROJECT_RULES.md)
