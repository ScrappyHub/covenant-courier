param(

C:\dev\covenant-courier = (Resolve-Path C:\dev\covenant-courier).Path
C:\dev\covenant-courier\scripts = Join-Path C:\dev\covenant-courier 'scripts'
}
Write-Host ('VTP_UDP_WIRE_SELFTEST_RUN: ' + $RunRoot)
Write-Host 'VTP_UDP_WIRE_SELFTEST_OK'
