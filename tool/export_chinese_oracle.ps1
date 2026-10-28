# Export expected dates through the independent installed .NET calendar API.
# Run from any directory using PowerShell. Output paths are repository-local.
param([switch]$Check)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$calendar = [Globalization.ChineseLunisolarCalendar]::new()
$rows = [Collections.Generic.List[object]]::new()
for ($year = 1901; $year -le 2099; $year++) {
    $leap = $calendar.GetLeapMonth($year)
    for ($month = 1; $month -le $calendar.GetMonthsInYear($year); $month++) {
        $date = $calendar.ToDateTime($year, $month, 1, 0, 0, 0, 0)
        $number = if ($leap -gt 0 -and $month -ge $leap) { $month - 1 } else { $month }
        $row = @($date.ToString('yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture),
            $year, $month, $number, ($month -eq $leap), $calendar.GetDaysInMonth($year, $month))
        $rows.Add($row)
    }
}
$utf8 = [Text.UTF8Encoding]::new($false)
$fixtures = Join-Path $taskRoot 'packages/general_datetime_core/test/fixtures/chinese_dotnet_months.json'
$fixtureText = (ConvertTo-Json -InputObject ($rows.ToArray()) -Depth 5 -Compress) + "`n"
if ($Check) {
    if ([IO.File]::ReadAllText($fixtures) -cne $fixtureText) {
        throw 'Chinese month fixtures differ from the installed .NET oracle.'
    }
} else {
    [IO.File]::WriteAllText($fixtures, $fixtureText, $utf8)
}
$metadata = @{
    runtime = [Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
    calendarAssembly = [Globalization.ChineseLunisolarCalendar].Assembly.FullName
    minimumYear = 1901
    maximumYear = 2099
    monthCount = $rows.Count
}
$manifest = Join-Path $taskRoot 'tool/chinese_oracle_runtime.json'
if (-not $Check) {
    [IO.File]::WriteAllText($manifest, (ConvertTo-Json -InputObject $metadata) + "`n", $utf8)
}
Write-Output "Verified $($rows.Count) month fixtures through .NET calendar APIs."
