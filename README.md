# 📘 XML Key Substitution Action

This GitHub Action updates XML files by replacing values in `<add>` elements based on matching environment variables.

It supports:
- `<add key="VAR" value="...">` → replaces `value`
- `<add name="VAR" connectionString="...">` → replaces `connectionString`

---

## ✅ Features

- 🔁 Replaces values of `<add>` elements with matching `key` or `name` from environment variables
- 🔠 Case-insensitive matching for variable names
- ✨ Supports **glob patterns** like `**/*.config`
- 🚫 Automatically deduplicates matched files
- 🛡️ Ignores files that aren’t valid XML
- 🛡️ Fails cleanly if no files matched
- 🧾 Works for `web.config`, `app.config`, and other XML files
- ⚙️ Fully cross-platform (Windows, Linux, macOS)

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

---

## 🚀 Usage

Because GitHub Actions composite actions cannot directly access the `vars`, `inputs`, or `secrets` contexts, you must manually pass any required values through the `env` block (see example below).
Alternatively you can dump all variables as environment variables using the following script in a step before calling this action:

> ⚠️ **Warning:** Dumping all variables may expose sensitive information. Use with caution.

```yaml
- name: Export all GitHub vars
  run: |
    $json = '${{ toJson(vars) }}'
	$vars = ConvertFrom-Json $json
	foreach ($property in $vars.PSObject.Properties) {
	  $key = $property.Name
	  $value = $property.Value
	  Write-Host "Setting $key to $value"
	  $output = "${key}<<EOF`n${value}`nEOF" # Needed if any value contains a new-line (\r\n)
	  Add-Content -Path $Env:GITHUB_ENV -Value $output
    }
    Write-Host "Variables exported successfully."
```

### 🧪 Example workflow step setting environment variables manually

```yaml
- name: Substitute XML values
  uses: CasperWSchmidt/substitute-xml-action@v1
  with:
    files: |
      deploy/**/*.config
      web.config
  env: # required to pass variables into the action
    ENVIRONMENT: ${{ inputs.environment }}
    CONNECTION_STRING: ${{ secrets.MY_DATABASE_CONNECTION  }}
	ROOT_DIRECTORY: ${{ vars.MY_ROOT_DIRECTORY }}
```

### 🧪 Example workflow step using dynamic variable export

```yaml
- name: Export all GitHub vars
  run: |
    $json = '${{ toJson(vars) }}'
	$vars = ConvertFrom-Json $json
	foreach ($property in $vars.PSObject.Properties) {
	  $key = $property.Name
	  $value = $property.Value
	  Write-Host "Setting $key to $value"
	  $output = "${key}<<EOF`n${value}`nEOF" # Needed if any value contains a new-line (\r\n)
	  Add-Content -Path $Env:GITHUB_ENV -Value $output
    }
    Write-Host "Variables exported successfully."
	
- name: Substitute XML values
  uses: CasperWSchmidt/substitute-xml-action@v1
  with:
    files: |
      deploy/**/*.config
      web.config
```

### 🗂️ Example `web.config` (before)
```xml
<configuration>
  <appSettings>
    <add key="Environment" value="Dummy" />
    <add key="RootDirectory" value="Dummy" />
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
    <add key="Environment" value="Production" />
    <add key="RootDirectory" value="C:\Some\Path" />
  </appSettings>
  <connectionStrings>
    <add name="DefaultConnection" connectionString="Server=sql;Database=prod;User Id=admin;" />
  </connectionStrings>
</configuration>
```
