# Known Limitations & Roadmap

## V1 Known Limitations

These are intentional constraints for v1 to ship quickly and avoid feature bloat:

### 1. No Freeform Drawing
**Limitation:** Coaches cannot draw plays from scratch on a blank canvas.

**Reason:**
- Freeform drawing is hard to make legible on phones
- Results in inconsistent visual language
- Requires complex canvas UI (pan, zoom, layers)

**Workaround:**
- 12+ preloaded offense templates
- 5 defense scenario templates
- Coaches duplicate and edit parametrically

**v1.1 Consideration:**
- May add more templates based on demand
- Freeform drawing remains explicitly out of scope

---

### 2. Step-Level Notes (Tentative)
**Limitation:** Notes may only attach to Set/Defense/Practice level in v1 (not individual steps).

**Reason:**
- Simplifies initial implementation
- Most notes are play-level or role-level, not step-specific

**v1.1 Plan:**
- Add step-level notes if easy (already modeled in schema with `stepIndex` field)
- If implemented in v1, this limitation is lifted

---

### 3. No Deep Links for Team Invites
**Limitation:** Players join teams via 6-character code only (no URL deep links).

**Reason:**
- Reduces setup complexity for v1
- Universal Links require Apple/Android app association files

**v1.1 Plan:**
- Add deep link support: `install://join/{teamId}?code={joinCode}`
- Shareable invite links via Messages, Email, etc.

---

### 4. Single Team Per User
**Limitation:** Users can only be a member of one team at a time.

**Reason:**
- Simplifies auth/team state management
- Most users (youth/HS players) are on one team

**v1.1 Consideration:**
- Multi-team support for coaches who run multiple programs
- Requires team switcher UI and more complex data fetching

---

### 5. No Branching Logic in Plays
**Limitation:** All steps are linear (no "if X happens, go to step Y" logic).

**Reason:**
- Linear steps are easier to teach and study
- Branching adds complexity to playback and editing
- Most fundamental plays are linear progressions

**Future:**
- Branching may be added in v2+ for advanced option plays
- Would require significant UI/UX rethinking

---

### 6. No Film Hosting
**Limitation:** Cannot upload video files. Film references are external links only.

**Reason:**
- Video storage/encoding/streaming is expensive
- Existing platforms (YouTube, Hudl, Vimeo) already host film

**Workaround:**
- Coaches upload film to YouTube/Hudl/Vimeo
- Add link with optional timecodes in INSTALL

**Not Planned:**
- Video upload/hosting will not be added (see "Explicitly Not Planned" below)

---

### 7. No Social Features
**Limitation:** No chat, comments, reactions, read receipts, or feeds.

**Reason:**
- INSTALL is a study tool, not a messaging app
- Social features create moderation burden
- Keeps focus on coach-led learning

**Not Planned:**
- Messaging, comments, and social features are explicitly out of scope

---

### 8. No Analytics Dashboard
**Limitation:** No "player viewed this set 5 times" analytics.

**Reason:**
- Adds complexity and privacy concerns
- v1 focuses on content delivery, not tracking

**v1.1 Consideration:**
- Basic usage stats (e.g., "10 players viewed playbook") may be added
- Detailed per-player analytics unlikely

---

## V1.1 Roadmap (Realistic Additions)

These features are **allowed** and may be added in v1.1:

### 1. Deep Links for Team Invites ✅
- Support `install://join/{teamId}?code={joinCode}`
- Generate shareable invite URLs
- Auto-join when user taps link

### 2. Step-Level Notes (If Not in V1) ✅
- Attach notes to specific steps (e.g., "1 must read 5's defender here")
- Schema already supports this with `stepIndex` field

### 3. Import/Export Sets as JSON ✅
- Export team playbook as JSON file
- Import plays from other teams/coaches
- Enables play sharing without requiring templates

### 4. More Templates ✅
- Community-submitted templates
- Curated library updates
- Regional/style-specific sets (e.g., European motion, Princeton offense)

### 5. Basic Quiz Mode ✅
- "What's your next action?" quiz
- Shows step, asks player to identify their action
- No leaderboards or social scoring (keeps it educational)

### 6. Android Player App ✅
- Kotlin + Jetpack Compose
- Full player experience: playback, notes, film, practices
- Read-only (no coach features initially)

### 7. Coach-Lite on Android (Optional) ✅
- Basic editing on Android tablets
- Publishing from Android
- May defer if adoption is iOS-heavy

---

## Explicitly NOT Planned

These features will **not** be added to INSTALL:

### 1. Video Upload/Hosting ❌
- **Why:** Expensive, redundant with existing platforms
- **Alternative:** External links work fine

### 2. Messaging/Chat ❌
- **Why:** Not a social app, moderation burden
- **Alternative:** Use existing team communication tools (GroupMe, Slack, etc.)

### 3. Parent Portal ❌
- **Why:** INSTALL is player-focused, not parent-focused
- **Alternative:** Coaches can share updates via existing channels

### 4. Payments/Subscriptions ❌
- **Why:** V1 is focused on product-market fit, not monetization
- **Future:** May revisit in v2+ if app gains traction

### 5. Attendance Tracking ❌
- **Why:** Out of scope (logistics vs. curriculum)
- **Alternative:** Use existing team management tools

### 6. Freeform Play Designer ❌
- **Why:** Conflicts with phone-first legibility constraint
- **Alternative:** Parametric editing is the core system

### 7. Advanced Analytics ❌
- **Why:** Privacy concerns, complexity, diminishing returns
- **Alternative:** Focus on content quality, not metrics

### 8. Social Feeds ❌
- **Why:** Not a social network
- **Alternative:** INSTALL is a study tool, not Instagram

---

## Version Timeline (Estimated)

### V1.0 (Q1 2026)
- iOS universal (iPhone + iPad)
- Full feature set as described in PRD
- Firebase backend operational
- 12+ offense templates, 5 defense scenarios
- Push notifications for playbook/practice updates

### V1.1 (Q2 2026)
- Deep links for team invites
- Step-level notes (if not in v1)
- Import/export sets (JSON)
- Android player app (Kotlin + Compose)
- More templates (15+ offense, 8 defense)

### V1.2 (Q3 2026)
- Basic quiz mode
- Improved playback UI (step thumbnails)
- Coach-lite on Android (optional)
- Template marketplace (curated)

### V2.0 (Q4 2026+)
- TBD based on user feedback
- Potential: multi-team support, branching logic, advanced POV controls
- **Not planned:** video upload, chat, payments, analytics

---

## How to Request Features

If you have a feature request:
1. Check this document to see if it's explicitly **not planned**
2. File an issue at [repository URL] with:
   - Use case description
   - Why existing features don't solve it
   - How it fits with INSTALL's core constraints (phone-first, coach-led, structured)

**Note:** Requests for features in the "Not Planned" section will be closed immediately.

---

## Design Principles (Non-Negotiable)

All features must align with these principles:

1. **Phone-first legibility:** If it doesn't work on iPhone in portrait, it doesn't work.
2. **Coach-led authority:** Coaches create, players study. No player edits.
3. **Structured, not freeform:** Parametric editing > blank canvas.
4. **Linear, not branching:** Steps are sequential.
5. **No social clutter:** Notes are annotations, not conversations.
6. **Film is referenced, not hosted:** External links only.
7. **Simple > feature-rich:** Avoid menu bloat, keep UI teachable by use.

Any feature that violates these principles will be rejected.

---

## Feedback

For bug reports or feedback on existing features:
- Use the in-app `/help` command
- File issues at [repository URL]
- Email: [contact email if applicable]

**This document is a living guide.** It will be updated as v1 ships and user feedback informs v1.1 priorities.
