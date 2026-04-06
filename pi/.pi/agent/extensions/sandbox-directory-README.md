# Sandbox Directory Extension

This extension restricts file modifications to only the directory where pi was started.

## What it does:

- ✅ Allows `write` and `edit` operations inside the starting directory
- ❌ Blocks `write` and `edit` operations outside the starting directory
- 🔍 Resolves symlinks to prevent bypassing restrictions
- 📊 Shows a status indicator in the footer
- 🔔 Notifies when operations are blocked

## Testing:

1. Create a test directory:
   ```bash
   mkdir -p /tmp/sandbox-test
   cd /tmp/sandbox-test
   echo "allowed" > allowed.txt
   ```

2. Start pi in that directory:
   ```bash
   pi
   ```

3. Test allowed operations (should work):
   ```
   You: Create a file called test.txt with "Hello World"
   ```

4. Test blocked operations (should fail):
   ```
   You: Create a file at /tmp/outside.txt with "This should be blocked"
   You: Edit /etc/hosts
   You: Write to ~/Desktop/test.txt
   ```

## How it protects:

### Allowed paths (examples when started in `/tmp/sandbox-test`):
- `./file.txt` 
- `subdir/file.txt`
- `/tmp/sandbox-test/anything.txt`

### Blocked paths:
- `/tmp/outside.txt` (outside starting directory)
- `../outside.txt` (goes up and out)
- `/etc/hosts` (absolute path outside)
- `~/Desktop/test.txt` (outside starting directory)

## Disabling temporarily:

If you need to disable the sandbox for a session, you can:

1. Move or rename the extension file:
   ```bash
   mv ~/.pi/agent/extensions/sandbox-directory.ts ~/.pi/agent/extensions/sandbox-directory.ts.disabled
   ```

2. Start a new session or run `/reload`

## Customization:

You can modify the extension to:
- Allow specific paths outside the sandbox (add a whitelist)
- Add a command to toggle the sandbox on/off
- Add a prompt before blocking to allow one-time operations
- Log all blocked attempts to a file

See the extension code at `~/.pi/agent/extensions/sandbox-directory.ts` for details.
