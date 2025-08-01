param (
  [string]$FilesList
)

Write-Host "🔄 Starting XML substitution based on ``key`` and ``name`` attributes..."

$files = @()
$inputFiles = @($FilesList -split "`n")
foreach ($file in $inputFiles) {
	if ($file.Trim()) {
		$files += $file.Trim()
	}
}

$envVars = [System.Environment]::GetEnvironmentVariables()
$caseInsensitiveEnvVars = New-Object System.Collections.Hashtable ([System.StringComparer]::OrdinalIgnoreCase)

# Copy environment variables into it
foreach ($key in $envVars.Keys) {
    $caseInsensitiveEnvVars[$key] = $envVars[$key]
}

Write-Host "🔄 Resolving file paths..."

# Expand all glob patterns (e.g., deploy/*.config)
# HashSet to store full paths (avoids duplicates)
$resolved = [System.Collections.Generic.HashSet[string]]::new()

foreach ($pattern in $files) {
  $matches = Get-ChildItem -Path $pattern -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
  if (-not $matches) {
    Write-Warning "⚠️ No matches found for pattern: $pattern"
  }

  foreach ($file in $matches) {
	Write-Host "Found: $file"
    $resolved.Add($file) | Out-Null
  }
}

if ($resolved.Count -eq 0) {
  Write-Error "❌ No valid files found. Exiting."
  exit 1
}

foreach ($file in $resolved) {
  if (-not (Test-Path $file)) {
    Write-Warning "⚠️ File not found: $file"
    continue
  }

  try {
    [xml]$xml = Get-Content -Path $file -Raw
  } catch {
    Write-Warning "⚠️ Failed to parse XML in $file. Skipping."
    continue
  }

  $updated = $false

  foreach ($node in $xml.SelectNodes("//add")) {
    # Handle <add key="..." value="...">
    $keyAttr = $node.GetAttribute("key")
    if ($keyAttr -and $caseInsensitiveEnvVars.ContainsKey($keyAttr)) {
      $old = $node.GetAttribute("value")
      $new = $caseInsensitiveEnvVars[$keyAttr]
      if ($old -ne $new) {
        $node.SetAttribute("value", $new)
        Write-Host "🔁 Updated key='$keyAttr': '$old' → '$new'"
        $updated = $true
      }
    }

    # Handle <add name="..." connectionString="...">
    $nameAttr = $node.GetAttribute("name")
    if ($nameAttr -and $caseInsensitiveEnvVars.ContainsKey($nameAttr)) {
      $old = $node.GetAttribute("connectionString")
      $new = $caseInsensitiveEnvVars[$nameAttr]
      if ($old -ne $new) {
        $node.SetAttribute("connectionString", $new)
        Write-Host "🔁 Updated name='$nameAttr': '$old' → '$new'"
        $updated = $true
      }
    }
  }

  if ($updated) {
    $xml.Save($file)
    Write-Host "💾 Saved: $file"
  } else {
    Write-Host "ℹ️ No substitutions needed in: $file"
  }
}

Write-Host "✅ XML substitution complete."
