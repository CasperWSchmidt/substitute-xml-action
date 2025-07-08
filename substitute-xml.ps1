param (
  [string[]]$Files
)

Write-Host "🔄 Starting XML substitution based on `key` and `name` attributes..."

$envVars = [System.Environment]::GetEnvironmentVariables()

foreach ($file in $Files) {
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
    if ($keyAttr -and $envVars.ContainsKey($keyAttr)) {
      $old = $node.GetAttribute("value")
      $new = $envVars[$keyAttr]
      if ($old -ne $new) {
        $node.SetAttribute("value", $new)
        Write-Host "🔁 Updated key='$keyAttr': '$old' → '$new'"
        $updated = $true
      }
    }

    # Handle <add name="..." connectionString="...">
    $nameAttr = $node.GetAttribute("name")
    if ($nameAttr -and $envVars.ContainsKey($nameAttr)) {
      $old = $node.GetAttribute("connectionString")
      $new = $envVars[$nameAttr]
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
