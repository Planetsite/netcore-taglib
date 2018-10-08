[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true, HelpMessage="Enter a valid version (2.1.1, 2.1.304 ...)")] 
    [ValidatePattern("^\d\.\d\.\d{1,4}$")]
    [string]$Version,
    [Parameter(Mandatory=$true, HelpMessage="Enter a comment for the release commit")] 
    [string]$Comment
)

#.\release.ps1 -Version 2.1.1 -Comment "Prima versione a pacchetto" -Verbose

Write-Verbose "Version: $Version"
Write-Verbose "Comment: $Comment"

$PackageName   = "TagLib"
$SolutionDir   = "D:\git\netcore-taglib"
$PackageDir    = "$SolutionDir\src\$PackageName"
$NugetEndPoint = "http://192.168.2.129:5056/v3/index.json"

Write-Verbose "Solution directory: $SolutionDir"
Write-Verbose "Package directory:  $PackageDir"
Write-Verbose "CsProj file:        $PackageDir\$PackageName.csproj"

# Update package metadata
cd $PackageDir
$CsProjContent = Get-Content "$PackageName.csproj"
$VersionToReplace         = $CsProjContent -match '<Version>(\d+\.\d+.\d+\.?\d*)</Version>'
$AssemblyVersionToReplace = $CsProjContent -match '<AssemblyVersion>(\d+\.\d+.\d+\.\d+)</AssemblyVersion>'
$FileVersionToReplace     = $CsProjContent -match '<FileVersion>(\d+\.\d+.\d+\.\d+)</FileVersion>'
$CsProjContent = $CsProjContent.Replace($VersionToReplace,         "    <Version>$Version</Version>")
$CsProjContent = $CsProjContent.Replace($AssemblyVersionToReplace, "    <AssemblyVersion>$Version.0</AssemblyVersion>")
$CsProjContent = $CsProjContent.Replace($FileVersionToReplace,     "    <FileVersion>$Version.0</FileVersion>")
Set-Content "$PackageName.csproj" $CsProjContent

# Commit & tag
cd $SolutionDir
Write-Verbose "Current remote tags list"
git ls-remote --tags -q
git add .
git commit -m $Comment
git tag $Version
git push -q
git push -q --tags

Write-Verbose "Tag created: $Version"

# Create & publish package
dotnet pack -o . --include-symbols
dotnet nuget push --source $NugetEndPoint "$PackageDir\$PackageName.$Version.symbols.nupkg"
del "$PackageDir\$PackageName.$Version.nupkg"
del "$PackageDir\$PackageName.$Version.symbols.nupkg"

Write-Verbose "Package '$PackageName.$Version.symbols.nupkg' published to '$NugetEndPoint'"

