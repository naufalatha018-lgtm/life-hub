Get-ChildItem -Path "lib" -Recurse -Include "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -Encoding UTF8
    if ($content -match "Life Hub") {
        $newContent = $content -replace "Life Hub", "Life OS"
        [System.IO.File]::WriteAllText($_.FullName, $newContent, [System.Text.Encoding]::UTF8)
        Write-Host "Updated: $($_.FullName)"
    }
}
Write-Host "Brand rename complete."
