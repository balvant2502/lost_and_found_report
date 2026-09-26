# CampusFound Screenshot Checklist

Use a real emulator or device with Firebase configured. Save final images in `docs/screenshots/` and use the filenames below so the report can reference them consistently.

| Done | Filename | Required view | Evidence to show |
|---|---|---|---|
| [ ] | `01-login-demo.png` | Login | CampusFound branding, login form, and Demo Mode button |
| [ ] | `02-register.png` | Registration | Name, email, password, and university fields |
| [ ] | `03-explore-search.png` | Explore | Search query with matching report results |
| [ ] | `04-explore-filters.png` | Explore | Lost/Found type control and category chips |
| [ ] | `05-report-form.png` | Report | Create lost/found form with required fields |
| [ ] | `06-item-details.png` | Item details | Report details, status, location, and contact action |
| [ ] | `07-dashboard.png` | Dashboard | User profile, statistics, and personal reports |
| [ ] | `08-chat-list.png` | Chats | Chat room list linked to an item |
| [ ] | `09-chat-room.png` | Chat room | Messages from both participants |
| [ ] | `10-test-results.png` | Terminal | Passing `flutter test` output |

## Capture notes

- Use the same demo account and university where possible.
- Include enough surrounding UI to make the feature identifiable.
- Avoid exposing real passwords, private email addresses, API keys, or Firebase credentials.
- For CRUD evidence, capture before/after states or include the action in a short screen recording if one screenshot cannot prove the state change.
- Add the final images to the ZIP under `docs/screenshots/`.