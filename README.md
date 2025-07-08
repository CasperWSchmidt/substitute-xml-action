# 📘 XML Key Substitution Action

This GitHub Action updates XML files by replacing values in `<add>` elements based on matching environment variables.

It supports:
- `<add key="VAR" value="...">` → replaces `value`
- `<add name="VAR" connectionString="...">` → replaces `connectionString`

---

## ✅ Features

- 🔁 Replaces values of `<add>` elements with matching `key` or `name` from environment variables
- 🧾 Works for `web.config`, `app.config`, and other XML files
- ⚙️ Fully cross-platform (Windows, Linux, macOS)
- 🛡️ Ignores files that aren’t valid XML

---

## 🔧 Inputs

| Input    | Description                                 | Required |
|----------|---------------------------------------------|----------|
| `files`  | Newline-separated list of XML file paths    | ✅       |

---

## 🖥️ Compatibility
- ✅ ubuntu-latest
- ✅ windows-latest
- ✅ macos-latest
- 🔧 Requires PowerShell Core

---

## 🚀 Usage

### 🧪 Example workflow step

```yaml
- name: Substitute XML values
  uses: CasperWSchmidt/substitute-xml-action@v1
  with:
    files: |
      web.config
      app.config
```

### 🔐 Environment variables
```yaml
env:
  ENVIRONMENT: Production
  DefaultConnection: Server=sql;Database=prod;User Id=admin;
```

### 🗂️ Example `web.config` (before)
```xml
<configuration>
  <appSettings>
    <add key="ENVIRONMENT" value="Development" />
  </appSettings>
  <connectionStrings>
    <add name="DefaultConnection" connectionString="..." />
  </connectionStrings>
</configuration>
```

### ✅ Result (after)
```xml
<configuration>
  <appSettings>
    <add key="ENVIRONMENT" value="Production" />
  </appSettings>
  <connectionStrings>
    <add name="DefaultConnection" connectionString="Server=sql;Database=prod;User Id=admin;" />
  </connectionStrings>
</configuration>
```
