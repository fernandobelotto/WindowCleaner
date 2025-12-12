# Reset SwiftData

Delete all SwiftData files to start fresh with an empty database.

## Context
- App Bundle ID: `com.fernandobelotto.MacAppTemplate`
- Data Location: `~/Library/Application Support/com.fernandobelotto.MacAppTemplate/`
- Files: `default.store`, `default.store-shm`, `default.store-wal`

## Instructions

1. **Ensure the app is closed** before running this command

2. Run the following command to delete SwiftData files:
   ```bash
   rm -rf ~/Library/Application\ Support/com.fernandobelotto.MacAppTemplate/default.store*
   ```

3. Alternatively, to delete **all app data** (not just SwiftData):
   ```bash
   rm -rf ~/Library/Application\ Support/com.fernandobelotto.MacAppTemplate
   ```

4. Rebuild and run the app to create a fresh database

## When to Use

- Schema changed and migrations are failing
- Database is in a corrupted state
- Testing fresh install experience
- Clearing test data during development

## Notes

- This only affects the development machine, not other users
- UserDefaults are stored separately in `~/Library/Preferences/`
- To also reset UserDefaults:
  ```bash
  defaults delete com.fernandobelotto.MacAppTemplate
  ```






