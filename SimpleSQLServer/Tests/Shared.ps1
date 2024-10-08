# Dot source this script in any Pester test script that requires the module to be imported.

$ModuleManifestName = 'SimpleSQLServer.psd1'
$ModuleManifestPath = "$PSScriptRoot\..\src\$ModuleManifestName"

# -Scope Global is needed when running tests from inside of psake, otherwise
# the module's functions cannot be found in the SimpleSQLServer\ namespace
Import-Module $ModuleManifestPath -Scope Global

