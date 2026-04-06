# Sandbox Directory Extension - Quick Start Guide

## 🎯 Which version should you use?

### Simple Version (`sandbox-directory.ts`)
✅ **Choose this if you want:**
- Strict enforcement, no exceptions
- Automatic protection without interaction
- Minimal UI clutter
- Set-it-and-forget-it security

❌ **Not ideal if:**
- You sometimes need to write outside the directory
- You want interactive control

### Advanced Version (`sandbox-directory-advanced.ts`)
✅ **Choose this if you want:**
- Ability to toggle protection on/off
- Confirmation dialogs for blocked operations
- Option to allow specific operations
- Whitelist for certain paths
- More flexibility

❌ **Not ideal if:**
- You want strict enforcement only
- You don't want confirmation prompts

## 🚀 Quick Setup

### Currently Active:
The **simple version** is currently active in your pi installation.

### To Switch to Advanced Version:
```bash
cd ~/.pi/agent/extensions/

# Backup simple version
mv sandbox-directory.ts sandbox-directory-simple.ts

# Activate advanced version  
cp sandbox-directory-advanced.ts sandbox-directory.ts

# Reload pi (if running)
# In pi: /reload
```

### To Switch Back to Simple:
```bash
cd ~/.pi/agent/extensions/

# Restore simple version
mv sandbox-directory-simple.ts sandbox-directory.ts

# Reload pi (if running)
# In pi: /reload
```

## 📋 Quick Test

1. **Create a test area:**
   ```bash
   mkdir -p /tmp/pi-sandbox-test
   cd /tmp/pi-sandbox-test
   ```

2. **Start pi:**
   ```bash
   pi
   ```

3. **Test inside sandbox (should work):**
   ```
   You: create a file called test.txt with the text "hello world"
   ```

4. **Test outside sandbox (should block):**
   ```
   You: create a file at /tmp/outside.txt with text "blocked"
   ```

## 🎮 Advanced Version Commands

If using the advanced version:

- **Toggle sandbox:** `/sandbox` or press `Ctrl+Shift+S`
- **Disable sandbox:** `/sandbox off`
- **Enable sandbox:** `/sandbox on`

When blocked, you'll see a prompt with options:
- **No (block)** - Block this operation
- **Yes (allow once)** - Allow just this one operation
- **Yes and disable sandbox** - Allow and turn off sandbox completely

## 🔧 Customization

### Add whitelist paths (in advanced version):
Edit `sandbox-directory.ts` and modify the `whitelist` array:

```typescript
const whitelist = [
  "/tmp/",           // Allow all /tmp writes
  "/var/log/myapp/", // Allow app logs
];
```

### Change keyboard shortcut:
Edit the `pi.registerShortcut()` call:

```typescript
pi.registerShortcut("ctrl+shift+s", {  // Change this line
  description: "Toggle sandbox protection",
  // ...
});
```

## 🔒 Security Notes

- The sandbox checks the **resolved path** (follows symlinks)
- Relative paths like `../` are resolved before checking
- The extension does NOT restrict:
  - Reading files (only write/edit)
  - Bash commands that create files
  - Network operations
  
For full isolation, consider combining with:
- Docker containers
- Virtual machines
- OS-level sandboxing (firejail, etc.)

## 📚 Examples

### Example 1: Working within project
```bash
cd ~/my-project
pi
# ✅ Can write to ~/my-project/src/file.ts
# ❌ Cannot write to ~/other-project/file.ts
```

### Example 2: Temporary workspace
```bash
mkdir -p /tmp/workspace
cd /tmp/workspace
pi
# ✅ Can write to /tmp/workspace/**
# ❌ Cannot write to /tmp/other/** or anywhere else
```

### Example 3: Using whitelist (advanced version)
```typescript
// In sandbox-directory.ts
const whitelist = ["/tmp/logs/"];

// Now when started in ~/my-project:
// ✅ Can write to ~/my-project/**
// ✅ Can write to /tmp/logs/** (whitelisted)
// ❌ Cannot write anywhere else
```

## 🐛 Troubleshooting

**Sandbox not working?**
1. Check if extension is loaded: `ls ~/.pi/agent/extensions/sandbox-directory.ts`
2. Check for errors: Look at pi startup messages
3. Verify correct directory: Check the status line in pi

**Want to see what's being blocked?**
Watch the notifications (simple version) or confirmation dialogs (advanced version).

**Need to disable temporarily?**
- Advanced: `/sandbox off` or `Ctrl+Shift+S`
- Simple: `mv sandbox-directory.ts sandbox-directory.ts.disabled` and `/reload`

**Extension conflicts?**
Make sure you don't have both simple and advanced versions active:
```bash
ls ~/.pi/agent/extensions/sandbox-directory*.ts
```

Only `sandbox-directory.ts` should be active (not disabled).

---

📖 **Full documentation:** See `sandbox-directory-README.md`
